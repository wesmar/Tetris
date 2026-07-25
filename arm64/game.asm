GAME_ASM EQU 1

    INCLUDE data.inc
    INCLUDE proto.inc

BOARD_MAX_CELLS EQU 400
BOARD_MIN_DIM   EQU 4
CLEAR_ANIM_MS   EQU 300

    EXPORT InitGame
    EXPORT StartGame
    EXPORT GenerateRandomPiece
    EXPORT SpawnNewPiece
    EXPORT CheckCollision
    EXPORT LockPiece
    EXPORT ClearFullLines
    EXPORT ApplyClearLines
    EXPORT UpdateGame
    EXPORT MoveLeft
    EXPORT MoveRight
    EXPORT MoveDown
    EXPORT RotatePiece
    EXPORT DropPiece
    EXPORT PauseGame
    EXPORT ResumeGame
    EXPORT TogglePause
    EXPORT SetPlayerName

; ---------------------------------------------------------------------------
; Read-only data
; ---------------------------------------------------------------------------
    AREA |.rdata|, DATA, READONLY, ALIGN=4
    ALIGN 4

; Tetromino shape templates: I, O, Z, S, T, L, J
; Format: x0,y0, x1,y1, x2,y2, x3,y3
SHAPE_TEMPLATES
    DCD 0,1, 1,1, 2,1, 3,1      ; I
    DCD 0,0, 1,0, 0,1, 1,1      ; O
    DCD 1,0, 0,1, 1,1, 2,1      ; Z
    DCD 0,1, 1,1, 1,0, 2,0      ; S
    DCD 0,0, 1,0, 1,1, 2,1      ; T
    DCD 0,0, 0,1, 1,1, 2,1      ; L
    DCD 2,0, 0,1, 1,1, 2,1      ; J

; ---------------------------------------------------------------------------
; Writable data
; ---------------------------------------------------------------------------
    AREA |.data|, DATA, READWRITE, ALIGN=4
    ALIGN 4

bagBytes DCB 0,1,2,3,4,5,6
    ALIGN 4
bagIndex DCD 7

; ---------------------------------------------------------------------------
; Code
; ---------------------------------------------------------------------------
    AREA |.text|, CODE, READONLY, ALIGN=4
    ALIGN 16

; ---------------------------------------------------------------------------
; InitGame
; X0 = pGame
; W1 = boardWidth
; W2 = boardHeight
; ---------------------------------------------------------------------------
InitGame PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STR X21, [SP, #32]

    MOV X19, X0
    MOV W20, W1
    MOV W21, W2

    MUL W8, W20, W21
    CMP W8, #BOARD_MAX_CELLS
    B.GT init_invalid_size

    CMP W20, #BOARD_MIN_DIM
    B.LT init_invalid_size

    CMP W21, #BOARD_MIN_DIM
    B.LT init_invalid_size

    STR W20, [X19, #GAME_STATE_boardWidth]
    STR W21, [X19, #GAME_STATE_boardHeight]
    B init_dimensions_ok

init_invalid_size
    MOV W8, #10
    STR W8, [X19, #GAME_STATE_boardWidth]
    MOV W8, #20
    STR W8, [X19, #GAME_STATE_boardHeight]

init_dimensions_ok
    MOV W8, #0
    STR W8, [X19, #GAME_STATE_score]
    STR W8, [X19, #GAME_STATE_lines]

    MOV W8, #1
    STR W8, [X19, #GAME_STATE_level]

    STRB WZR, [X19, #GAME_STATE_gameOver]
    STRB WZR, [X19, #GAME_STATE_paused]
    STRB WZR, [X19, #GAME_STATE_showGhost]

    STRB WZR, [X19, #GAME_STATE_clearActive]
    STRB WZR, [X19, #GAME_STATE_clearCount]
    STR WZR, [X19, #GAME_STATE_clearMask]
    STR WZR, [X19, #GAME_STATE_clearTimer]

    MOV X0, X19
    BL InitParticles

    ADD X8, X19, #GAME_STATE_board
    LDR W9, [X19, #GAME_STATE_boardHeight]
    LDR W10, [X19, #GAME_STATE_boardWidth]
    MUL W9, W9, W10
    CBZ W9, init_clear_done

init_clear_loop
    STRB WZR, [X8], #1
    SUBS W9, W9, #1
    B.NE init_clear_loop

init_clear_done
    BL GetTickCount
    STR W0, [X19, #GAME_STATE_rngSeed]

    LDR X8, =bagIndex
    MOV W9, #7
    STR W9, [X8]

    MOV X0, X19
    BL LoadHighScore

    MOV X0, X19
    BL LoadPlayerName

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_nextPiece
    BL GenerateRandomPiece

    MOV X0, X19
    BL SpawnNewPiece

    LDR X21, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; StartGame
; X0 = pGame
; ---------------------------------------------------------------------------
StartGame PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0

    ADD X8, X19, #GAME_STATE_board
    LDR W9, [X19, #GAME_STATE_boardHeight]
    LDR W10, [X19, #GAME_STATE_boardWidth]
    MUL W9, W9, W10
    CBZ W9, start_clear_done

start_clear_loop
    STRB WZR, [X8], #1
    SUBS W9, W9, #1
    B.NE start_clear_loop

start_clear_done
    MOV W8, #0
    STR W8, [X19, #GAME_STATE_score]
    STR W8, [X19, #GAME_STATE_lines]

    MOV W8, #1
    STR W8, [X19, #GAME_STATE_level]

    STRB WZR, [X19, #GAME_STATE_gameOver]
    STRB WZR, [X19, #GAME_STATE_paused]

    STRB WZR, [X19, #GAME_STATE_clearActive]
    STRB WZR, [X19, #GAME_STATE_clearCount]
    STR WZR, [X19, #GAME_STATE_clearMask]
    STR WZR, [X19, #GAME_STATE_clearTimer]

    MOV X0, X19
    BL InitParticles

    LDR X8, =bagIndex
    MOV W9, #7
    STR W9, [X8]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_nextPiece
    BL GenerateRandomPiece

    MOV X0, X19
    BL SpawnNewPiece

    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; GenerateRandomPiece
; X0 = pGame
; X1 = pPiece
; ---------------------------------------------------------------------------
GenerateRandomPiece PROC
    STP X19, X20, [SP, #-48]!
    STP X21, X22, [SP, #16]
    STR X23, [SP, #32]

    MOV X19, X0
    MOV X20, X1

    LDR X8, =bagIndex
    LDR W9, [X8]
    CMP W9, #7
    B.LT grp_get_from_bag

    ; Fisher-Yates shuffle
    MOV W21, #6

    MOVZ W22, #0x4E6D
    MOVK W22, #0x41C6, LSL #16   ; 1103515245
    MOVZ W23, #12345

grp_shuffle_loop
    LDR W9, [X19, #GAME_STATE_rngSeed]
    MUL W9, W9, W22
    ADD W9, W9, W23
    STR W9, [X19, #GAME_STATE_rngSeed]

    UBFX W10, W9, #16, #15       ; (rng >> 16) & 0x7FFF

    ADD W11, W21, #1             ; i + 1
    UDIV W12, W10, W11
    MSUB W13, W12, W11, W10      ; remainder

    LDR X14, =bagBytes

    LDRB W15, [X14, W21, UXTW]
    LDRB W16, [X14, W13, UXTW]
    STRB W16, [X14, W21, UXTW]
    STRB W15, [X14, W13, UXTW]

    SUBS W21, W21, #1
    B.GE grp_shuffle_loop

    MOV W9, #0
    STR W9, [X8]

grp_get_from_bag
    LDR W9, [X8]

    LDR X10, =bagBytes

    LDRB W11, [X10, W9, UXTW]    ; piece type 0..6
    ADD W9, W9, #1
    STR W9, [X8]

    CMP W11, #6
    B.LS grp_piece_type_ok
    MOV W11, #0

grp_piece_type_ok
    STRB W11, [X20, #PIECE_shapeType]

    LDR W9, [X19, #GAME_STATE_boardWidth]
    LSR W9, W9, #1
    SUB W9, W9, #1
    STR W9, [X20, #PIECE_x]

    STR WZR, [X20, #PIECE_y]
    STR WZR, [X20, #PIECE_yFloat]

    LSL W12, W11, #5             ; shapeType * 32

    LDR X13, =SHAPE_TEMPLATES
    ADD X13, X13, W12, UXTW

    ADD X14, X20, #PIECE_blocks
    MOV W15, #8

grp_copy_blocks
    LDR W16, [X13], #4
    STR W16, [X14], #4
    SUBS W15, W15, #1
    B.NE grp_copy_blocks

    ADD W11, W11, #1
    STRB W11, [X20, #PIECE_color]

    LDR X23, [SP, #32]
    LDP X21, X22, [SP, #16]
    LDP X19, X20, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; SpawnNewPiece
; X0 = pGame
; ---------------------------------------------------------------------------
SpawnNewPiece PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0

    ADD X1, X19, #GAME_STATE_currentPiece
    ADD X2, X19, #GAME_STATE_nextPiece
    MOV W3, #6                   ; 48 bytes / 8

snp_copy_loop
    LDR X4, [X2], #8
    STR X4, [X1], #8
    SUBS W3, W3, #1
    B.NE snp_copy_loop

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_nextPiece
    BL GenerateRandomPiece

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, snp_no_collision
    MOV W1, #1
    STRB W1, [X19, #GAME_STATE_gameOver]

snp_no_collision
    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; CheckCollision
; X0 = pGame
; X1 = pPiece
; Returns W0 = 1 if collision, 0 otherwise
; ---------------------------------------------------------------------------
CheckCollision PROC
    STP X19, X20, [SP, #-32]!
    STR X21, [SP, #16]

    MOV X19, X0
    MOV X20, X1
    MOV W21, #0

cc_block_loop
    LSL W8, W21, #3
    ADD X8, X20, #PIECE_blocks
    ADD X8, X8, W8, UXTW

    LDRSW X9, [X8, #POINT_STRUCT_x]
    LDR W10, [X20, #PIECE_x]
    ADD W9, W9, W10

    LDRSW X10, [X8, #POINT_STRUCT_y]
    LDR W11, [X20, #PIECE_y]
    ADD W10, W10, W11

    CMP W9, #0
    B.LT cc_collision

    LDR W11, [X19, #GAME_STATE_boardWidth]
    CMP W9, W11
    B.GE cc_collision

    CMP W10, #0
    B.LT cc_next_block

    LDR W11, [X19, #GAME_STATE_boardHeight]
    CMP W10, W11
    B.GE cc_collision

    LDR W11, [X19, #GAME_STATE_boardWidth]
    MUL W11, W10, W11
    ADD W11, W11, W9

    ADD X12, X19, #GAME_STATE_board
    LDRB W12, [X12, W11, UXTW]
    CBNZ W12, cc_collision

cc_next_block
    ADD W21, W21, #1
    CMP W21, #4
    B.LT cc_block_loop

    MOV W0, #0
    B cc_exit

cc_collision
    MOV W0, #1

cc_exit
    LDR X21, [SP, #16]
    LDP X19, X20, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; LockPiece
; X0 = pGame
; ---------------------------------------------------------------------------
LockPiece PROC
    STP X29, X30, [SP, #-64]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STP X21, X22, [SP, #32]
    STP X23, X24, [SP, #48]

    MOV X19, X0
    ADD X20, X19, #GAME_STATE_currentPiece

    LDRB W21, [X20, #PIECE_color]
    LDR W22, [X20, #PIECE_x]
    LDR W23, [X20, #PIECE_y]
    MOV W24, #0

lp_place_loop
    CMP W24, #4
    B.GE lp_place_done

    ADD X8, X20, #PIECE_blocks
    LSL W9, W24, #3
    ADD X8, X8, W9, UXTW

    LDR W9, [X8, #POINT_STRUCT_x]
    ADD W9, W9, W22

    LDR W10, [X8, #POINT_STRUCT_y]
    ADD W10, W10, W23

    CMP W10, #0
    B.LT lp_skip_block

    LDR W11, [X19, #GAME_STATE_boardHeight]
    CMP W10, W11
    B.GE lp_skip_block

    CMP W9, #0
    B.LT lp_skip_block

    LDR W11, [X19, #GAME_STATE_boardWidth]
    CMP W9, W11
    B.GE lp_skip_block

    LDR W11, [X19, #GAME_STATE_boardWidth]
    MUL W11, W10, W11
    ADD W11, W11, W9

    ADD X12, X19, #GAME_STATE_board
    STRB W21, [X12, W11, UXTW]

lp_skip_block
    ADD W24, W24, #1
    B lp_place_loop

lp_place_done
    MOV X0, X19
    BL ClearFullLines

    MOV X0, X19
    BL SpawnNewPiece

    LDP X23, X24, [SP, #48]
    LDP X21, X22, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #64
    RET
    ENDP

; ---------------------------------------------------------------------------
; ClearFullLines
; X0 = pGame
; Returns W0 = number of full lines
; ---------------------------------------------------------------------------
ClearFullLines PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STR X21, [SP, #32]

    MOV X19, X0

    STRB WZR, [X19, #GAME_STATE_clearCount]
    STR WZR, [X19, #GAME_STATE_clearMask]

    MOV W21, #0                  ; line count

    LDR W20, [X19, #GAME_STATE_boardHeight]
    SUB W20, W20, #1             ; row

cfl_scan_loop
    CMP W20, #0
    B.LT cfl_scan_done

    LDR W8, [X19, #GAME_STATE_boardWidth]
    MUL W8, W20, W8
    ADD X8, X19, #GAME_STATE_board
    ADD X8, X8, W8, UXTW

    MOV W9, #0                   ; column

cfl_check_row
    LDRB W10, [X8, W9, UXTW]
    CBZ W10, cfl_not_full

    ADD W9, W9, #1
    LDR W10, [X19, #GAME_STATE_boardWidth]
    CMP W9, W10
    B.LT cfl_check_row

    ; Row full
    MOV W10, #1
    LSL W10, W10, W20
    LDR W11, [X19, #GAME_STATE_clearMask]
    ORR W11, W11, W10
    STR W11, [X19, #GAME_STATE_clearMask]

    ADD W21, W21, #1

    MOV X0, X19
    MOV W1, W20
    BL SpawnLineExplosion

cfl_not_full
    SUB W20, W20, #1
    B cfl_scan_loop

cfl_scan_done
    CBZ W21, cfl_no_lines

    STRB W21, [X19, #GAME_STATE_clearCount]
    MOV W8, #1
    STRB W8, [X19, #GAME_STATE_clearActive]
    STR WZR, [X19, #GAME_STATE_clearTimer]

cfl_no_lines
    MOV W0, W21

    LDR X21, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; ApplyClearLines
; X0 = pGame
; ---------------------------------------------------------------------------
ApplyClearLines PROC
    STP X29, X30, [SP, #-64]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STP X21, X22, [SP, #32]
    STP X23, X24, [SP, #48]

    MOV X19, X0

    LDR W22, [X19, #GAME_STATE_boardWidth]

    LDR W20, [X19, #GAME_STATE_boardHeight]
    SUB W20, W20, #1             ; dstY
    MOV W21, W20                 ; srcY

acl_compress_loop
    CMP W21, #0
    B.LT acl_fill_top

    MOV W8, #1
    LSL W8, W8, W21
    LDR W9, [X19, #GAME_STATE_clearMask]
    TST W8, W9
    B.NE acl_skip_row

    CMP W21, W20
    B.EQ acl_no_copy

    MUL W8, W21, W22
    ADD X23, X19, #GAME_STATE_board
    ADD X23, X23, W8, UXTW

    MUL W8, W20, W22
    ADD X24, X19, #GAME_STATE_board
    ADD X24, X24, W8, UXTW

    MOV W8, #0

acl_copy_row
    LDRB W9, [X23, W8, UXTW]
    STRB W9, [X24, W8, UXTW]
    ADD W8, W8, #1
    CMP W8, W22
    B.LT acl_copy_row

acl_no_copy
    SUB W20, W20, #1

acl_skip_row
    SUB W21, W21, #1
    B acl_compress_loop

acl_fill_top
    CMP W20, #0
    B.LT acl_update_score

acl_clear_top_loop
    MUL W8, W20, W22
    ADD X23, X19, #GAME_STATE_board
    ADD X23, X23, W8, UXTW

    MOV W8, #0

acl_clear_row
    STRB WZR, [X23, W8, UXTW]
    ADD W8, W8, #1
    CMP W8, W22
    B.LT acl_clear_row

    SUB W20, W20, #1
    CMP W20, #0
    B.GE acl_clear_top_loop

acl_update_score
    LDRB W8, [X19, #GAME_STATE_clearCount]
    LDR W9, [X19, #GAME_STATE_lines]
    ADD W9, W9, W8
    STR W9, [X19, #GAME_STATE_lines]

    MUL W8, W8, W8
    MOV W10, #100
    MUL W8, W8, W10
    LDR W10, [X19, #GAME_STATE_level]
    MUL W8, W8, W10
    LDR W10, [X19, #GAME_STATE_score]
    ADD W10, W10, W8
    STR W10, [X19, #GAME_STATE_score]

    LDR W8, [X19, #GAME_STATE_lines]
    MOV W9, #10
    UDIV W8, W8, W9
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_level]

    LDR W8, [X19, #GAME_STATE_score]
    LDR W9, [X19, #GAME_STATE_highScore]
    CMP W8, W9
    B.LE acl_clear_anim_state

    MOV X0, X19
    BL SaveHighScore

acl_clear_anim_state
    STRB WZR, [X19, #GAME_STATE_clearActive]
    STRB WZR, [X19, #GAME_STATE_clearCount]
    STR WZR, [X19, #GAME_STATE_clearMask]
    STR WZR, [X19, #GAME_STATE_clearTimer]

    LDP X23, X24, [SP, #48]
    LDP X21, X22, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #64
    RET
    ENDP

; ---------------------------------------------------------------------------
; UpdateGame
; X0 = pGame
; W1 = deltaTimeMs
; ---------------------------------------------------------------------------
UpdateGame PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]

    MOV X19, X0
    MOV W20, W1

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, ug_exit

    LDRB W8, [X19, #GAME_STATE_paused]
    CBNZ W8, ug_exit

    LDRB W8, [X19, #GAME_STATE_clearActive]
    CBZ W8, ug_anim_done

    LDR W8, [X19, #GAME_STATE_clearTimer]
    ADD W8, W8, W20
    STR W8, [X19, #GAME_STATE_clearTimer]

    CMP W8, #CLEAR_ANIM_MS
    B.LT ug_anim_done

    MOV X0, X19
    BL ApplyClearLines

ug_anim_done
    MOV X0, X19
    MOV W1, W20
    BL UpdateParticles

    LDR W8, [X19, #GAME_STATE_level]
    SUB W8, W8, #1
    MOV W9, #50
    MUL W8, W8, W9
    ADD W8, W8, #300
    MUL W8, W8, W20
    LSR W8, W8, #3

    LDR W9, [X19, #GAME_STATE_yFloat]
    ADD W9, W9, W8
    STR W9, [X19, #GAME_STATE_yFloat]

ug_check_fall
    LDR W8, [X19, #GAME_STATE_yFloat]
    MOV W9, #10000
    CMP W8, W9
    B.LT ug_exit

    SUB W8, W8, W9
    STR W8, [X19, #GAME_STATE_yFloat]

    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, ug_check_fall

    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    SUB W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    STR WZR, [X19, #GAME_STATE_yFloat]

    MOV X0, X19
    BL LockPiece

ug_exit
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; MoveLeft
; X0 = pGame
; ---------------------------------------------------------------------------
MoveLeft PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, ml_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, ml_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

ml_exit
    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; MoveRight
; X0 = pGame
; ---------------------------------------------------------------------------
MoveRight PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, mr_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, mr_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

mr_exit
    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; MoveDown
; X0 = pGame
; W1 = dy
; Returns W0 = 1 if moved, 0 if blocked/locked
; ---------------------------------------------------------------------------
MoveDown PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]

    MOV X19, X0
    MOV W20, W1

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, md_failed

    LDRB W8, [X19, #GAME_STATE_paused]
    CBNZ W8, md_failed

    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    ADD W8, W8, W20
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, md_success

    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    SUB W8, W8, W20
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    MOV X0, X19
    BL LockPiece

md_failed
    MOV W0, #0
    B md_exit

md_success
    MOV W0, #1

md_exit
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; RotatePiece
; X0 = pGame
; ---------------------------------------------------------------------------
RotatePiece PROC
    STP X29, X30, [SP, #-80]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STR X21, [SP, #32]

    MOV X19, X0

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, rp_exit

    ADD X20, X19, #GAME_STATE_currentPiece

    LDRB W8, [X20, #PIECE_shapeType]
    CMP W8, #1                   ; O piece does not rotate
    B.EQ rp_exit

    ; Backup 8 DWORD block offsets
    ADD X8, X20, #PIECE_blocks
    ADD X9, SP, #48
    MOV W10, #8

rp_backup_loop
    LDR W11, [X8], #4
    STR W11, [X9], #4
    SUBS W10, W10, #1
    B.NE rp_backup_loop

    ; Rotate clockwise around (1,1)
    MOV W8, #0

rp_rotate_loop
    CMP W8, #4
    B.GE rp_rotate_done

    ADD X9, X20, #PIECE_blocks
    LSL W10, W8, #3
    ADD X9, X9, W10, UXTW

    LDR W10, [X9, #POINT_STRUCT_x]
    SUB W10, W10, #1

    LDR W11, [X9, #POINT_STRUCT_y]
    SUB W11, W11, #1

    NEG W12, W11
    ADD W12, W12, #1
    STR W12, [X9, #POINT_STRUCT_x]

    ADD W10, W10, #1
    STR W10, [X9, #POINT_STRUCT_y]

    ADD W8, W8, #1
    B rp_rotate_loop

rp_rotate_done
    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, rp_exit

    LDRB W21, [X20, #PIECE_shapeType]
    CMP W21, #0
    B.NE rp_try_normal

    ; I-piece wall kicks
    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #2
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #3
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #4
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #2
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    B rp_restore

rp_try_normal
    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #2
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    ADD W8, W8, #3
    STR W8, [X19, #GAME_STATE_currentPiece_x]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision
    CBZ W0, rp_exit

    LDR W8, [X19, #GAME_STATE_currentPiece_x]
    SUB W8, W8, #2
    STR W8, [X19, #GAME_STATE_currentPiece_x]

rp_restore
    ADD X8, X20, #PIECE_blocks
    ADD X9, SP, #48
    MOV W10, #8

rp_restore_loop
    LDR W11, [X9], #4
    STR W11, [X8], #4
    SUBS W10, W10, #1
    B.NE rp_restore_loop

rp_exit
    LDR X21, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #80
    RET
    ENDP

; ---------------------------------------------------------------------------
; DropPiece
; X0 = pGame
; ---------------------------------------------------------------------------
DropPiece PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0

    LDRB W8, [X19, #GAME_STATE_gameOver]
    CBNZ W8, dp_exit

    LDRB W8, [X19, #GAME_STATE_paused]
    CBNZ W8, dp_exit

dp_drop_loop
    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    ADD W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    MOV X0, X19
    ADD X1, X19, #GAME_STATE_currentPiece
    BL CheckCollision

    CBZ W0, dp_drop_loop

    LDR W8, [X19, #GAME_STATE_currentPiece_y]
    SUB W8, W8, #1
    STR W8, [X19, #GAME_STATE_currentPiece_y]

    MOV X0, X19
    BL LockPiece

dp_exit
    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; PauseGame
; X0 = pGame
; ---------------------------------------------------------------------------
PauseGame PROC
    MOV W8, #1
    STRB W8, [X0, #GAME_STATE_paused]
    RET
    ENDP

; ---------------------------------------------------------------------------
; ResumeGame
; X0 = pGame
; ---------------------------------------------------------------------------
ResumeGame PROC
    STRB WZR, [X0, #GAME_STATE_paused]
    RET
    ENDP

; ---------------------------------------------------------------------------
; TogglePause
; X0 = pGame
; ---------------------------------------------------------------------------
TogglePause PROC
    LDRB W8, [X0, #GAME_STATE_paused]
    EOR W8, W8, #1
    STRB W8, [X0, #GAME_STATE_paused]
    RET
    ENDP

; ---------------------------------------------------------------------------
; SetPlayerName
; X0 = pGame
; X1 = pName (UTF-16)
; ---------------------------------------------------------------------------
SetPlayerName PROC
    ADD X8, X0, #GAME_STATE_playerName
    MOV X9, X1
    MOV W10, #0

spn_copy_loop
    LSL W11, W10, #1
    LDRH W12, [X9, W11, UXTW]
    STRH W12, [X8, W11, UXTW]

    CBZ W12, spn_done

    ADD W10, W10, #1
    CMP W10, #127
    B.LT spn_copy_loop

spn_done
    LSL W11, W10, #1
    STRH WZR, [X8, W11, UXTW]
    RET
    ENDP

    END