RENDER_ASM EQU 1

    INCLUDE data.inc
    INCLUDE proto.inc

R_BLOCK_SIZE       EQU 25
R_GAME_AREA_HEIGHT EQU 520

    EXPORT InitRenderer
    EXPORT CleanupRenderer
    EXPORT CreateBackBuffer
    EXPORT ResizeRenderer
    EXPORT RenderGame
    EXPORT DrawBoard
    EXPORT DrawGhostPiece
    EXPORT DrawPiece
    EXPORT DrawNextPiece
    EXPORT DrawInfo

; ---------------------------------------------------------------------------
; Read-only data
; ---------------------------------------------------------------------------
    AREA |.rdata|, DATA, READONLY, ALIGN=4
    ALIGN 4

r_szSegoeUI    DCB "Segoe UI", 0
r_szScore      DCB "Score: %d", 0
r_szLines      DCB "Lines: %d", 0
r_szLevel      DCB "Level: %d", 0
r_szRecord     DCB "Record: %d", 0
r_szNext       DCB "Next:", 0
r_szAuthor     DCB "Author:", 0
r_szName       DCB "Marek Wesolowski", 0
r_szEmail      DCB "marek@wesolowski.eu.org", 0
r_szWebsite    DCB "https://kvc.pl", 0
r_szControls   DCB "Controls:", 0
r_szCtrlF2     DCB "F2 - New Game", 0
r_szCtrlP      DCB "P - Pause/Resume", 0
r_szCtrlArrows DCB "Arrows - Move/Rotate", 0
r_szCtrlSpace  DCB "Space - Hard Drop", 0
r_szCtrlEsc    DCB "ESC - Exit", 0
r_szPaused     DCB "PAUSED", 0
r_szGameOver   DCB "GAME OVER!", 0

    ALIGN 4
r_colorTable DCD 0x00000000
             DCD 0x00FFFF00
             DCD 0x0000FFFF
             DCD 0x000000FF
             DCD 0x0000FF00
             DCD 0x00800080
             DCD 0x000080FF
             DCD 0x00FF8000

; ---------------------------------------------------------------------------
; Code
; ---------------------------------------------------------------------------
    AREA |.text|, CODE, READONLY, ALIGN=4
    ALIGN 16

; ---------------------------------------------------------------------------
; InitRenderer
; X0 = pRenderer, X1 = hwnd
; ---------------------------------------------------------------------------
IR_FRAME EQU 0x100
IR_FP    EQU 0xF0
IR_SAVE1 EQU 0xE0

InitRenderer PROC
    SUB SP, SP, #IR_FRAME
    STP X29, X30, [SP, #IR_FP]
    ADD X29, SP, #IR_FP
    STP X19, X20, [SP, #IR_SAVE1]

    MOV X19, X0
    STR X1, [X19, #RENDERER_STATE_hwnd]

    STR XZR, [X19, #RENDERER_STATE_hdcMem]
    STR XZR, [X19, #RENDERER_STATE_hbmMem]
    STR XZR, [X19, #RENDERER_STATE_hbmOld]
    STR WZR, [X19, #RENDERER_STATE_wWidth]
    STR WZR, [X19, #RENDERER_STATE_wHeight]
    STR WZR, [X19, #RENDERER_STATE_pausePulse]

    ; Common CreateFontA stack arguments (args 9..14 at [SP, #0]..[SP, #40])
    STR XZR, [SP, #0]            ; arg 9: iCharSet
    STR XZR, [SP, #8]            ; arg 10: iOutPrecision
    STR XZR, [SP, #16]           ; arg 11: iClipPrecision
    STR XZR, [SP, #24]           ; arg 12: iQuality
    STR XZR, [SP, #32]           ; arg 13: iPitchAndFamily

    LDR X8, =r_szSegoeUI
    STR X8, [SP, #40]            ; arg 14: pszFaceName

    ; hFontNormal: 20, bold
    MOV X0, #20                  ; arg 1: cHeight
    MOV X1, #0                   ; arg 2: cWidth
    MOV X2, #0                   ; arg 3: cEscapement
    MOV X3, #0                   ; arg 4: cOrientation
    MOV X4, #700                 ; arg 5: cWeight
    MOV X5, #0                   ; arg 6: bItalic
    MOV X6, #0                   ; arg 7: bUnderline
    MOV X7, #0                   ; arg 8: bStrikeOut
    BL CreateFontA
    STR X0, [X19, #RENDERER_STATE_hFontNormal]

    ; hFontSmall: 14, normal
    MOV X0, #14
    MOV X1, #0
    MOV X2, #0
    MOV X3, #0
    MOV X4, #400
    MOV X5, #0
    MOV X6, #0
    MOV X7, #0
    BL CreateFontA
    STR X0, [X19, #RENDERER_STATE_hFontSmall]

    ; hFontPause: 26, bold
    MOV X0, #26
    MOV X1, #0
    MOV X2, #0
    MOV X3, #0
    MOV X4, #700
    MOV X5, #0
    MOV X6, #0
    MOV X7, #0
    BL CreateFontA
    STR X0, [X19, #RENDERER_STATE_hFontPause]

    ; hFontGameOver: 30, bold
    MOV X0, #30
    MOV X1, #0
    MOV X2, #0
    MOV X3, #0
    MOV X4, #700
    MOV X5, #0
    MOV X6, #0
    MOV X7, #0
    BL CreateFontA
    STR X0, [X19, #RENDERER_STATE_hFontGameOver]

    ; Create color brushes
    MOV X20, #0
ir_brush_loop
    CMP X20, #8
    B.GE ir_done

    LDR X8, =r_colorTable
    LSL W9, W20, #2
    LDR W0, [X8, W9, UXTW]
    BL CreateSolidBrush

    ADD X8, X19, #RENDERER_STATE_colorBrushes
    STR X0, [X8, X20, LSL #3]

    ADD X20, X20, #1
    B ir_brush_loop

ir_done
    LDP X19, X20, [SP, #IR_SAVE1]
    LDP X29, X30, [SP, #IR_FP]
    ADD SP, SP, #IR_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; CleanupRenderer
; X0 = pRenderer
; ---------------------------------------------------------------------------
CleanupRenderer PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]

    MOV X19, X0

    LDR X0, [X19, #RENDERER_STATE_hFontNormal]
    CBZ X0, cr_skip_font1
    BL DeleteObject
cr_skip_font1

    LDR X0, [X19, #RENDERER_STATE_hFontSmall]
    CBZ X0, cr_skip_font2
    BL DeleteObject
cr_skip_font2

    LDR X0, [X19, #RENDERER_STATE_hFontPause]
    CBZ X0, cr_skip_font3
    BL DeleteObject
cr_skip_font3

    LDR X0, [X19, #RENDERER_STATE_hFontGameOver]
    CBZ X0, cr_skip_font4
    BL DeleteObject
cr_skip_font4

    MOV X20, #0
cr_brush_loop
    CMP X20, #8
    B.GE cr_brush_done

    ADD X8, X19, #RENDERER_STATE_colorBrushes
    LDR X0, [X8, X20, LSL #3]
    CBZ X0, cr_skip_brush
    BL DeleteObject

cr_skip_brush
    ADD X20, X20, #1
    B cr_brush_loop

cr_brush_done
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    CBZ X0, cr_skip_dc

    LDR X1, [X19, #RENDERER_STATE_hbmOld]
    CBZ X1, cr_skip_select
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    BL SelectObject

cr_skip_select
    LDR X0, [X19, #RENDERER_STATE_hbmMem]
    CBZ X0, cr_skip_bitmap
    BL DeleteObject

cr_skip_bitmap
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    BL DeleteDC

cr_skip_dc
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; CreateBackBuffer
; X0 = pRenderer
; ---------------------------------------------------------------------------
CreateBackBuffer PROC
    STP X29, X30, [SP, #-48]!
    MOV X29, SP
    STP X19, X20, [SP, #16]

    MOV X19, X0

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    CBZ X0, cbb_create_new

    LDR X1, [X19, #RENDERER_STATE_hbmOld]
    CBZ X1, cbb_skip_old
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    BL SelectObject

cbb_skip_old
    LDR X0, [X19, #RENDERER_STATE_hbmMem]
    CBZ X0, cbb_skip_bmp
    BL DeleteObject

cbb_skip_bmp
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    BL DeleteDC

cbb_create_new
    LDR X0, [X19, #RENDERER_STATE_hwnd]
    BL GetDC
    MOV X20, X0

    MOV X0, X20
    BL CreateCompatibleDC
    STR X0, [X19, #RENDERER_STATE_hdcMem]

    MOV X0, X20
    LDR W1, [X19, #RENDERER_STATE_wWidth]
    LDR W2, [X19, #RENDERER_STATE_wHeight]
    BL CreateCompatibleBitmap
    STR X0, [X19, #RENDERER_STATE_hbmMem]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    LDR X1, [X19, #RENDERER_STATE_hbmMem]
    BL SelectObject
    STR X0, [X19, #RENDERER_STATE_hbmOld]

    LDR X0, [X19, #RENDERER_STATE_hwnd]
    MOV X1, X20
    BL ReleaseDC

    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #48
    RET
    ENDP

; ---------------------------------------------------------------------------
; ResizeRenderer
; X0 = pRenderer, W1 = width, W2 = height
; ---------------------------------------------------------------------------
ResizeRenderer PROC
    STP X29, X30, [SP, #-32]!
    MOV X29, SP
    STR X19, [SP, #16]

    MOV X19, X0
    STR W1, [X19, #RENDERER_STATE_wWidth]
    STR W2, [X19, #RENDERER_STATE_wHeight]

    MOV X0, X19
    BL CreateBackBuffer

    LDR X19, [SP, #16]
    LDP X29, X30, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; RenderGame
; X0 = pRenderer, X1 = pGame, X2 = hdc
; ---------------------------------------------------------------------------
RG_FRAME EQU 0x100
RG_FP    EQU 0xF0
RG_SAVE1 EQU 0xE0
RG_SAVE2 EQU 0xD0
RG_RECT  EQU 0x40

RenderGame PROC
    SUB SP, SP, #RG_FRAME
    STP X29, X30, [SP, #RG_FP]
    ADD X29, SP, #RG_FP
    STP X19, X20, [SP, #RG_SAVE1]
    STP X21, X22, [SP, #RG_SAVE2]

    MOV X19, X0
    MOV X20, X1
    MOV X21, X2

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    CBZ X0, rg_exit

    ; Dark game area
    STR WZR, [SP, #(RG_RECT + 0)]
    STR WZR, [SP, #(RG_RECT + 4)]
    LDR W8, [X19, #RENDERER_STATE_wWidth]
    STR W8, [SP, #(RG_RECT + 8)]
    MOV W8, #R_GAME_AREA_HEIGHT
    STR W8, [SP, #(RG_RECT + 12)]

    MOVZ W0, #0x1414
    MOVK W0, #0x0014, LSL #16
    BL CreateSolidBrush
    MOV X22, X0

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #RG_RECT
    MOV X2, X22
    BL FillRect

    MOV X0, X22
    BL DeleteObject

    ; Bottom control area
    STR WZR, [SP, #(RG_RECT + 0)]
    MOV W8, #R_GAME_AREA_HEIGHT
    STR W8, [SP, #(RG_RECT + 4)]
    LDR W8, [X19, #RENDERER_STATE_wWidth]
    STR W8, [SP, #(RG_RECT + 8)]
    LDR W8, [X19, #RENDERER_STATE_wHeight]
    STR W8, [SP, #(RG_RECT + 12)]

    MOVZ W0, #0xF0F0
    MOVK W0, #0x00F0, LSL #16
    BL CreateSolidBrush
    MOV X22, X0

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #RG_RECT
    MOV X2, X22
    BL FillRect

    MOV X0, X22
    BL DeleteObject

    MOV X0, X19
    MOV X1, X20
    BL DrawBoard

    MOV X0, X19
    MOV X1, X20
    BL RenderParticles

    MOV X0, X19
    MOV X1, X20
    BL DrawGhostPiece

    MOV X0, X19
    ADD X1, X20, #GAME_STATE_currentPiece
    BL DrawPiece

    MOV X0, X19
    MOV X1, X20
    BL DrawInfo

    MOV X0, X19
    ADD X1, X20, #GAME_STATE_nextPiece
    BL DrawNextPiece

    ; BitBlt game area to screen (9 args: X0..X7, [SP,#0])
    MOV X0, X21                  ; arg 1: hdcDest
    MOV X1, #0                   ; arg 2: x
    MOV X2, #0                   ; arg 3: y
    LDR W3, [X19, #RENDERER_STATE_wWidth] ; arg 4: cx
    MOV X4, #R_GAME_AREA_HEIGHT  ; arg 5: cy
    LDR X5, [X19, #RENDERER_STATE_hdcMem] ; arg 6: hdcSrc
    MOV X6, #0                   ; arg 7: x1
    MOV X7, #0                   ; arg 8: y1

    MOVZ W8, #0x0020
    MOVK W8, #0x00CC, LSL #16   ; SRCCOPY = 0x00CC0020
    STR X8, [SP, #0]             ; arg 9: rop

    BL BitBlt

rg_exit
    LDP X21, X22, [SP, #RG_SAVE2]
    LDP X19, X20, [SP, #RG_SAVE1]
    LDP X29, X30, [SP, #RG_FP]
    ADD SP, SP, #RG_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; DrawBoard
; X0 = pRenderer, X1 = pGame
; ---------------------------------------------------------------------------
DB_FRAME EQU 0x140
DB_FP    EQU 0x130
DB_SAVE1 EQU 0x120
DB_SAVE2 EQU 0x110
DB_SAVE3 EQU 0x100
DB_SAVE4 EQU 0xF0
DB_RECT  EQU 0x40

DrawBoard PROC
    SUB SP, SP, #DB_FRAME
    STP X29, X30, [SP, #DB_FP]
    ADD X29, SP, #DB_FP
    STP X19, X20, [SP, #DB_SAVE1]
    STP X21, X22, [SP, #DB_SAVE2]
    STP X23, X24, [SP, #DB_SAVE3]
    STP X25, X26, [SP, #DB_SAVE4]

    MOV X19, X0
    MOV X20, X1
    LDR X21, [X19, #RENDERER_STATE_hdcMem]

    ; Grid pen
    MOV X0, #0
    MOV X1, #1
    MOVZ W2, #0x3232
    MOVK W2, #0x0032, LSL #16
    BL CreatePen
    MOV X23, X0

    MOV X0, X21
    MOV X1, X23
    BL SelectObject
    MOV X22, X0

    ; Horizontal grid lines
    MOV X24, #0
db_hline_loop
    LDR W8, [X20, #GAME_STATE_boardHeight]
    ADD W8, W8, #1
    CMP W24, W8
    B.GE db_hline_done

    MOV W8, W24
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #20
    MOV W26, W8                  ; y

    MOV X0, X21
    MOV X1, #20
    MOV X2, X26
    MOV X3, #0
    BL MoveToEx

    LDR W8, [X20, #GAME_STATE_boardWidth]
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #20

    MOV X0, X21
    MOV X1, X8
    MOV X2, X26
    BL LineTo

    ADD X24, X24, #1
    B db_hline_loop

db_hline_done
    ; Vertical grid lines
    MOV X24, #0
db_vline_loop
    LDR W8, [X20, #GAME_STATE_boardWidth]
    ADD W8, W8, #1
    CMP W24, W8
    B.GE db_vline_done

    MOV W8, W24
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #20
    MOV W26, W8                  ; x

    MOV X0, X21
    MOV X1, X26
    MOV X2, #20
    MOV X3, #0
    BL MoveToEx

    LDR W8, [X20, #GAME_STATE_boardHeight]
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #20

    MOV X0, X21
    MOV X1, X26
    MOV X2, X8
    BL LineTo

    ADD X24, X24, #1
    B db_vline_loop

db_vline_done
    ; Restore old pen and delete grid pen
    MOV X0, X21
    MOV X1, X22
    BL SelectObject

    MOV X0, X23
    BL DeleteObject

    ; Draw occupied cells
    MOV X24, #0                  ; y
db_outer_loop
    LDR W8, [X20, #GAME_STATE_boardHeight]
    CMP W24, W8
    B.GE db_outer_done

    MOV X25, #0                  ; x
db_inner_loop
    LDR W8, [X20, #GAME_STATE_boardWidth]
    CMP W25, W8
    B.GE db_inner_done

    LDR W8, [X20, #GAME_STATE_boardWidth]
    MUL W8, W24, W8
    ADD W8, W8, W25

    ADD X9, X20, #GAME_STATE_board
    LDRB W8, [X9, W8, UXTW]
    CBZ W8, db_skip_block

    AND W10, W8, #7

    MOV W9, W25
    MOV W11, #R_BLOCK_SIZE
    MUL W9, W9, W11
    ADD W9, W9, #21
    STR W9, [SP, #(DB_RECT + 0)]

    MOV W9, W24
    MUL W9, W9, W11
    ADD W9, W9, #21
    STR W9, [SP, #(DB_RECT + 4)]

    LDR W9, [SP, #(DB_RECT + 0)]
    ADD W9, W9, #23
    STR W9, [SP, #(DB_RECT + 8)]

    LDR W9, [SP, #(DB_RECT + 4)]
    ADD W9, W9, #23
    STR W9, [SP, #(DB_RECT + 12)]

    ADD X11, X19, #RENDERER_STATE_colorBrushes
    LDR X2, [X11, X10, LSL #3]

    MOV X0, X21
    ADD X1, SP, #DB_RECT
    BL FillRect

db_skip_block
    ADD X25, X25, #1
    B db_inner_loop

db_inner_done
    ADD X24, X24, #1
    B db_outer_loop

db_outer_done
    ; Line clear fade overlay
    LDRB W8, [X20, #GAME_STATE_clearActive]
    CBZ W8, db_no_overlay

    LDR W8, [X20, #GAME_STATE_clearTimer]
    MOV W9, #300
    SUBS W9, W9, W8
    B.LE db_no_overlay

    MOV W10, W9                  ; remaining intensity

    MOV W8, #255
    MUL W8, W8, W10
    MOV W9, #300
    UDIV W8, W8, W9
    MOV W11, W8                  ; R

    MOV W8, #215
    MUL W8, W8, W10
    UDIV W8, W8, W9

    LSL W8, W8, #8
    ORR W8, W8, W11

    MOV X0, X8
    BL CreateSolidBrush
    MOV X23, X0

    MOV X24, #0
db_overlay_loop
    LDR W8, [X20, #GAME_STATE_boardHeight]
    CMP W24, W8
    B.GE db_overlay_done

    MOV W8, #1
    LSL W8, W8, W24
    LDR W9, [X20, #GAME_STATE_clearMask]
    TST W8, W9
    B.EQ db_overlay_next

    MOV W8, #21
    STR W8, [SP, #(DB_RECT + 0)]

    MOV W8, W24
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #21
    STR W8, [SP, #(DB_RECT + 4)]

    LDR W8, [X20, #GAME_STATE_boardWidth]
    MUL W8, W8, W9
    ADD W8, W8, #19
    STR W8, [SP, #(DB_RECT + 8)]

    MOV W8, W24
    MUL W8, W8, W9
    ADD W8, W8, #44
    STR W8, [SP, #(DB_RECT + 12)]

    MOV X0, X21
    ADD X1, SP, #DB_RECT
    MOV X2, X23
    BL FillRect

db_overlay_next
    ADD X24, X24, #1
    B db_overlay_loop

db_overlay_done
    MOV X0, X23
    BL DeleteObject

db_no_overlay
    LDP X25, X26, [SP, #DB_SAVE4]
    LDP X23, X24, [SP, #DB_SAVE3]
    LDP X21, X22, [SP, #DB_SAVE2]
    LDP X19, X20, [SP, #DB_SAVE1]
    LDP X29, X30, [SP, #DB_FP]
    ADD SP, SP, #DB_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; DrawGhostPiece
; X0 = pRenderer, X1 = pGame
; ---------------------------------------------------------------------------
DGP_FRAME      EQU 0x140
DGP_FP         EQU 0x130
DGP_SAVE1      EQU 0x120
DGP_SAVE2      EQU 0x110
DGP_SAVE3      EQU 0x100
DGP_SAVE4      EQU 0xF0
DGP_RECT       EQU 0x40
DGP_GHOST      EQU 0x80
DGP_GHOST_X    EQU DGP_GHOST + PIECE_x
DGP_GHOST_Y    EQU DGP_GHOST + PIECE_y
DGP_GHOST_BLKS EQU DGP_GHOST + PIECE_blocks

DrawGhostPiece PROC
    SUB SP, SP, #DGP_FRAME
    STP X29, X30, [SP, #DGP_FP]
    ADD X29, SP, #DGP_FP
    STP X19, X20, [SP, #DGP_SAVE1]
    STP X21, X22, [SP, #DGP_SAVE2]
    STP X23, X24, [SP, #DGP_SAVE3]
    STP X25, X26, [SP, #DGP_SAVE4]

    MOV X19, X0
    MOV X20, X1

    LDRB W8, [X20, #GAME_STATE_gameOver]
    CBNZ W8, dgp_exit

    LDRB W8, [X20, #GAME_STATE_paused]
    CBNZ W8, dgp_exit

    LDRB W8, [X20, #GAME_STATE_showGhost]
    CBZ W8, dgp_exit

    ; Copy current piece to local ghost piece
    ADD X8, SP, #DGP_GHOST
    ADD X9, X20, #GAME_STATE_currentPiece
    MOV W10, #PIECE_SIZE
dgp_copy_loop
    LDRB W11, [X9], #1
    STRB W11, [X8], #1
    SUBS W10, W10, #1
    B.NE dgp_copy_loop

dgp_find_landing
    LDR W8, [SP, #DGP_GHOST_Y]
    ADD W8, W8, #1
    STR W8, [SP, #DGP_GHOST_Y]

    MOV X0, X20
    ADD X1, SP, #DGP_GHOST
    BL CheckCollision

    CBZ W0, dgp_find_landing

    LDR W8, [SP, #DGP_GHOST_Y]
    SUB W8, W8, #1
    STR W8, [SP, #DGP_GHOST_Y]

    ADD X8, X20, #GAME_STATE_currentPiece
    LDR W9, [X8, #PIECE_y]
    LDR W10, [SP, #DGP_GHOST_Y]
    CMP W9, W10
    B.GE dgp_exit

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV X1, #1
    BL SetBkMode

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOVZ W1, #0x1818
    MOVK W1, #0x0018, LSL #16
    BL SetBkColor

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOVZ W1, #0x4848
    MOVK W1, #0x0048, LSL #16
    BL SetTextColor

    MOV X0, #5
    MOVZ W1, #0x4848
    MOVK W1, #0x0048, LSL #16
    BL CreateHatchBrush
    MOV X21, X0

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV X1, X21
    BL SelectObject
    MOV X22, X0

    LDR W24, [SP, #DGP_GHOST_X]
    LDR W25, [SP, #DGP_GHOST_Y]
    MOV X23, #0

dgp_block_loop
    CMP W23, #4
    B.GE dgp_block_done

    LSL W8, W23, #3
    ADD X9, SP, #DGP_GHOST_BLKS
    ADD X9, X9, W8, UXTW

    LDR W10, [X9, #0]
    ADD W10, W10, W24
    LDR W11, [X9, #4]
    ADD W11, W11, W25

    CMP W11, #0
    B.LT dgp_skip_draw

    MOV W8, W10
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #21
    STR W8, [SP, #(DGP_RECT + 0)]

    MOV W8, W11
    MUL W8, W8, W9
    ADD W8, W8, #21
    STR W8, [SP, #(DGP_RECT + 4)]

    LDR W8, [SP, #(DGP_RECT + 0)]
    ADD W8, W8, #23
    STR W8, [SP, #(DGP_RECT + 8)]

    LDR W8, [SP, #(DGP_RECT + 4)]
    ADD W8, W8, #23
    STR W8, [SP, #(DGP_RECT + 12)]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #DGP_RECT
    MOV X2, X21
    BL FillRect

dgp_skip_draw
    ADD X23, X23, #1
    B dgp_block_loop

dgp_block_done
    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV X1, X22
    BL SelectObject

    MOV X0, X21
    BL DeleteObject

dgp_exit
    LDP X25, X26, [SP, #DGP_SAVE4]
    LDP X23, X24, [SP, #DGP_SAVE3]
    LDP X21, X22, [SP, #DGP_SAVE2]
    LDP X19, X20, [SP, #DGP_SAVE1]
    LDP X29, X30, [SP, #DGP_FP]
    ADD SP, SP, #DGP_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; DrawPiece
; X0 = pRenderer, X1 = pPiece
; ---------------------------------------------------------------------------
DP_FRAME EQU 0x100
DP_FP    EQU 0xF0
DP_SAVE1 EQU 0xE0
DP_SAVE2 EQU 0xD0
DP_SAVE3 EQU 0xC0
DP_RECT  EQU 0x40

DrawPiece PROC
    SUB SP, SP, #DP_FRAME
    STP X29, X30, [SP, #DP_FP]
    ADD X29, SP, #DP_FP
    STP X19, X20, [SP, #DP_SAVE1]
    STP X21, X22, [SP, #DP_SAVE2]
    STP X23, X24, [SP, #DP_SAVE3]

    MOV X19, X0
    MOV X20, X1

    LDRB W8, [X20, #PIECE_color]
    AND W8, W8, #7
    ADD X9, X19, #RENDERER_STATE_colorBrushes
    LDR X21, [X9, X8, LSL #3]

    LDR W23, [X20, #PIECE_x]
    LDR W24, [X20, #PIECE_y]
    MOV X22, #0

dp_block_loop
    CMP W22, #4
    B.GE dp_block_done

    LSL W8, W22, #3
    ADD X9, X20, #PIECE_blocks
    ADD X9, X9, W8, UXTW

    LDR W10, [X9, #0]
    ADD W10, W10, W23
    LDR W11, [X9, #4]
    ADD W11, W11, W24

    CMP W11, #0
    B.LT dp_skip_draw

    MOV W8, W10
    MOV W9, #R_BLOCK_SIZE
    MUL W8, W8, W9
    ADD W8, W8, #21
    STR W8, [SP, #(DP_RECT + 0)]

    MOV W8, W11
    MUL W8, W8, W9
    ADD W8, W8, #21
    STR W8, [SP, #(DP_RECT + 4)]

    LDR W8, [SP, #(DP_RECT + 0)]
    ADD W8, W8, #23
    STR W8, [SP, #(DP_RECT + 8)]

    LDR W8, [SP, #(DP_RECT + 4)]
    ADD W8, W8, #23
    STR W8, [SP, #(DP_RECT + 12)]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #DP_RECT
    MOV X2, X21
    BL FillRect

dp_skip_draw
    ADD X22, X22, #1
    B dp_block_loop

dp_block_done
    LDP X23, X24, [SP, #DP_SAVE3]
    LDP X21, X22, [SP, #DP_SAVE2]
    LDP X19, X20, [SP, #DP_SAVE1]
    LDP X29, X30, [SP, #DP_FP]
    ADD SP, SP, #DP_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; DrawNextPiece
; X0 = pRenderer, X1 = pPiece
; ---------------------------------------------------------------------------
DNP_FRAME EQU 0x100
DNP_FP    EQU 0xF0
DNP_SAVE1 EQU 0xE0
DNP_SAVE2 EQU 0xD0
DNP_SAVE3 EQU 0xC0
DNP_RECT  EQU 0x40

DrawNextPiece PROC
    SUB SP, SP, #DNP_FRAME
    STP X29, X30, [SP, #DNP_FP]
    ADD X29, SP, #DNP_FP
    STP X19, X20, [SP, #DNP_SAVE1]
    STP X21, X22, [SP, #DNP_SAVE2]
    STP X23, X24, [SP, #DNP_SAVE3]

    MOV X19, X0
    MOV X20, X1

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV X1, #1
    BL SetBkMode

    LDRB W8, [X20, #PIECE_color]
    AND W8, W8, #7
    LDR X9, =r_colorTable
    LDR W8, [X9, W8, UXTW #2]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV W1, W8
    BL SetTextColor

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    LDR X1, [X19, #RENDERER_STATE_hFontNormal]
    BL SelectObject
    MOV X22, X0

    LDR X0, =r_szNext
    BL lstrlenA
    MOV X4, X0                   ; arg 5: length

    LDR X0, [X19, #RENDERER_STATE_hdcMem] ; arg 1: hdc
    MOV X1, #300                 ; arg 2: x
    MOV X2, #185                 ; arg 3: y
    LDR X3, =r_szNext            ; arg 4: lpString
    BL TextOutA

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    MOV X1, X22
    BL SelectObject

    LDRB W8, [X20, #PIECE_color]
    AND W8, W8, #7
    ADD X9, X19, #RENDERER_STATE_colorBrushes
    LDR X21, [X9, X8, LSL #3]

    MOV X23, #0
dnp_block_loop
    CMP W23, #4
    B.GE dnp_block_done

    LSL W8, W23, #3
    ADD X9, X20, #PIECE_blocks
    ADD X9, X9, W8, UXTW

    LDR W10, [X9, #0]
    MOV W11, #R_BLOCK_SIZE
    MUL W10, W10, W11
    ADD W10, W10, #321
    STR W10, [SP, #(DNP_RECT + 0)]

    LDR W10, [X9, #4]
    MUL W10, W10, W11
    ADD W10, W10, #221
    STR W10, [SP, #(DNP_RECT + 4)]

    LDR W10, [SP, #(DNP_RECT + 0)]
    ADD W10, W10, #23
    STR W10, [SP, #(DNP_RECT + 8)]

    LDR W10, [SP, #(DNP_RECT + 4)]
    ADD W10, W10, #23
    STR W10, [SP, #(DNP_RECT + 12)]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #DNP_RECT
    MOV X2, X21
    BL FillRect

    ADD X23, X23, #1
    B dnp_block_loop

dnp_block_done
    LDP X23, X24, [SP, #DNP_SAVE3]
    LDP X21, X22, [SP, #DNP_SAVE2]
    LDP X19, X20, [SP, #DNP_SAVE1]
    LDP X29, X30, [SP, #DNP_FP]
    ADD SP, SP, #DNP_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; DrawInfo
; X0 = pRenderer, X1 = pGame
; ---------------------------------------------------------------------------
DI_FRAME EQU 0x200
DI_FP    EQU 0x1F0
DI_SAVE1 EQU 0x1E0
DI_SAVE2 EQU 0x1D0
DI_SAVE3 EQU 0x1C0
DI_BUF   EQU 0x40
DI_MB    EQU 0x140

DrawInfo PROC
    SUB SP, SP, #DI_FRAME
    STP X29, X30, [SP, #DI_FP]
    ADD X29, SP, #DI_FP
    STP X19, X20, [SP, #DI_SAVE1]
    STP X21, X22, [SP, #DI_SAVE2]
    STP X23, X24, [SP, #DI_SAVE3]

    MOV X19, X0
    MOV X20, X1
    LDR X24, [X19, #RENDERER_STATE_hdcMem]

    MOV X0, X24
    MOV X1, #1
    BL SetBkMode

    MOV X0, X24
    MOVZ W1, #0xFFFF
    MOVK W1, #0x00FF, LSL #16
    BL SetTextColor

    MOV X0, X24
    LDR X1, [X19, #RENDERER_STATE_hFontSmall]
    BL SelectObject
    MOV X21, X0

    MOV X0, X24
    MOVZ W1, #0xFF80
    MOVK W1, #0x0080, LSL #16
    BL SetTextColor

    ; "Controls:"
    LDR X0, =r_szControls
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #15
    LDR X3, =r_szControls
    BL TextOutA

    ; Separator line under Controls
    MOV X0, #0
    MOV X1, #1
    MOVZ W2, #0x3232
    MOVK W2, #0x0032, LSL #16
    BL CreatePen
    MOV X23, X0

    MOV X0, X24
    MOV X1, X23
    BL SelectObject
    MOV X22, X0

    MOV X0, X24
    MOV X1, #295
    MOV X2, #32
    MOV X3, #0
    BL MoveToEx

    MOV X0, X24
    MOV X1, #465
    MOV X2, #32
    BL LineTo

    MOV X0, X24
    MOV X1, X22
    BL SelectObject

    MOV X0, X23
    BL DeleteObject

    MOV X0, X24
    MOVZ W1, #0xC0C0
    MOVK W1, #0x00C0, LSL #16
    BL SetTextColor

    ; F2
    LDR X0, =r_szCtrlF2
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #305
    MOV X2, #36
    LDR X3, =r_szCtrlF2
    BL TextOutA

    ; P
    LDR X0, =r_szCtrlP
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #305
    MOV X2, #49
    LDR X3, =r_szCtrlP
    BL TextOutA

    ; Arrows
    LDR X0, =r_szCtrlArrows
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #305
    MOV X2, #62
    LDR X3, =r_szCtrlArrows
    BL TextOutA

    ; Space
    LDR X0, =r_szCtrlSpace
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #305
    MOV X2, #75
    LDR X3, =r_szCtrlSpace
    BL TextOutA

    ; ESC
    LDR X0, =r_szCtrlEsc
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #305
    MOV X2, #88
    LDR X3, =r_szCtrlEsc
    BL TextOutA

    ; Separator line under controls list
    MOV X0, #0
    MOV X1, #1
    MOVZ W2, #0x3232
    MOVK W2, #0x0032, LSL #16
    BL CreatePen
    MOV X23, X0

    MOV X0, X24
    MOV X1, X23
    BL SelectObject
    MOV X22, X0

    MOV X0, X24
    MOV X1, #295
    MOV X2, #105
    MOV X3, #0
    BL MoveToEx

    MOV X0, X24
    MOV X1, #465
    MOV X2, #105
    BL LineTo

    MOV X0, X24
    MOV X1, X22
    BL SelectObject

    MOV X0, X23
    BL DeleteObject

    ; Restore small font, select normal font
    MOV X0, X24
    MOV X1, X21
    BL SelectObject

    MOV X0, X24
    MOVZ W1, #0xFFFF
    MOVK W1, #0x00FF, LSL #16
    BL SetTextColor

    MOV X0, X24
    LDR X1, [X19, #RENDERER_STATE_hFontNormal]
    BL SelectObject
    MOV X21, X0

    ; Score
    ADD X0, SP, #DI_BUF
    LDR X1, =r_szScore
    LDR W2, [X20, #GAME_STATE_score]
    BL wsprintfA

    ADD X0, SP, #DI_BUF
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #110
    ADD X3, SP, #DI_BUF
    BL TextOutA

    ; Lines
    ADD X0, SP, #DI_BUF
    LDR X1, =r_szLines
    LDR W2, [X20, #GAME_STATE_lines]
    BL wsprintfA

    ADD X0, SP, #DI_BUF
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #135
    ADD X3, SP, #DI_BUF
    BL TextOutA

    ; Level
    ADD X0, SP, #DI_BUF
    LDR X1, =r_szLevel
    LDR W2, [X20, #GAME_STATE_level]
    BL wsprintfA

    ADD X0, SP, #DI_BUF
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #160
    ADD X3, SP, #DI_BUF
    BL TextOutA

    ; Record
    MOV X0, X24
    MOVZ W1, #0xD7FF
    BL SetTextColor

    ADD X0, SP, #DI_BUF
    LDR X1, =r_szRecord
    LDR W2, [X20, #GAME_STATE_highScore]
    BL wsprintfA

    ADD X0, SP, #DI_BUF
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #310
    ADD X3, SP, #DI_BUF
    BL TextOutA

    ; High score name
    ADD X8, X20, #GAME_STATE_highScoreName
    LDRH W9, [X8]
    CBZ W9, di_skip_name

    MOV X0, #0                   ; arg 1: CodePage
    MOV X1, #0                   ; arg 2: dwFlags
    ADD X2, X20, #GAME_STATE_highScoreName ; arg 3: lpWideCharStr
    MOVN W3, #0                  ; arg 4: cchWideChar (-1)
    ADD X4, SP, #DI_MB           ; arg 5: lpMultiByteStr
    MOV X5, #128                 ; arg 6: cbMultiByte
    MOV X6, #0                   ; arg 7: lpDefaultChar
    MOV X7, #0                   ; arg 8: lpUsedDefaultChar
    BL WideCharToMultiByte

    ADD X0, SP, #DI_MB
    BL lstrlenA
    MOV X4, X0

    MOV X0, X24
    MOV X1, #300
    MOV X2, #285
    ADD X3, SP, #DI_MB
    BL TextOutA

di_skip_name
    MOV X0, X24
    MOVZ W1, #0xFFFF
    MOVK W1, #0x00FF, LSL #16
    BL SetTextColor

    MOV X0, X24
    MOV X1, X21
    BL SelectObject

    ; Separator before author
    MOV X0, #0
    MOV X1, #1
    MOVZ W2, #0x3232
    MOVK W2, #0x0032, LSL #16
    BL CreatePen
    MOV X23, X0

    MOV X0, X24
    MOV X1, X23
    BL SelectObject
    MOV X22, X0

    MOV X0, X24
    MOV X1, #295
    MOV X2, #355
    MOV X3, #0
    BL MoveToEx

    MOV X0, X24
    MOV X1, #465
    MOV X2, #355
    BL LineTo

    MOV X0, X24
    MOV X1, X22
    BL SelectObject

    MOV X0, X23
    BL DeleteObject

    ; Author block
    MOV X0, X24
    LDR X1, [X19, #RENDERER_STATE_hFontSmall]
    BL SelectObject
    MOV X21, X0

    MOV X0, X24
    MOVZ W1, #0xA0A0
    MOVK W1, #0x00A0, LSL #16
    BL SetTextColor

    LDR X0, =r_szAuthor
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #365
    LDR X3, =r_szAuthor
    BL TextOutA

    LDR X0, =r_szName
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #385
    LDR X3, =r_szName
    BL TextOutA

    LDR X0, =r_szEmail
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #405
    LDR X3, =r_szEmail
    BL TextOutA

    LDR X0, =r_szWebsite
    BL lstrlenA
    MOV X4, X0
    MOV X0, X24
    MOV X1, #300
    MOV X2, #425
    LDR X3, =r_szWebsite
    BL TextOutA

    MOV X0, X24
    MOV X1, X21
    BL SelectObject

    ; PAUSED overlay
    LDRB W8, [X20, #GAME_STATE_paused]
    CBZ W8, di_check_gameover

    LDRB W8, [X20, #GAME_STATE_gameOver]
    CBNZ W8, di_check_gameover

    LDR W8, [X19, #RENDERER_STATE_pausePulse]
    ADD W8, W8, #4
    AND W8, W8, #0xFF
    STR W8, [X19, #RENDERER_STATE_pausePulse]

    MOV W9, W8
    SUB W9, W9, #128
    CMP W9, #0
    B.GE di_pulse_pos
    NEG W9, W9

di_pulse_pos
    MOV W10, #128
    SUB W10, W10, W9
    ADD W10, W10, #127

    MOV W11, W10
    LSL W11, W11, #8
    ORR W10, W10, W11

    MOV X0, X24
    MOV W1, W10
    BL SetTextColor

    MOV X0, X24
    LDR X1, [X19, #RENDERER_STATE_hFontPause]
    BL SelectObject
    MOV X21, X0

    LDR X0, =r_szPaused
    BL lstrlenA
    MOV X4, X0

    MOV X0, X24
    MOV X1, #300
    MOV X2, #470
    LDR X3, =r_szPaused
    BL TextOutA

    MOV X0, X24
    MOV X1, X21
    BL SelectObject

di_check_gameover
    LDRB W8, [X20, #GAME_STATE_gameOver]
    CBZ W8, di_done_overlays

    MOV X0, X24
    MOVZ W1, #0x00FF
    BL SetTextColor

    MOV X0, X24
    LDR X1, [X19, #RENDERER_STATE_hFontGameOver]
    BL SelectObject
    MOV X21, X0

    LDR X0, =r_szGameOver
    BL lstrlenA
    MOV X4, X0

    MOV X0, X24
    MOV X1, #280
    MOV X2, #470
    LDR X3, =r_szGameOver
    BL TextOutA

    MOV X0, X24
    MOV X1, X21
    BL SelectObject

di_done_overlays
    LDP X23, X24, [SP, #DI_SAVE3]
    LDP X21, X22, [SP, #DI_SAVE2]
    LDP X19, X20, [SP, #DI_SAVE1]
    LDP X29, X30, [SP, #DI_FP]
    ADD SP, SP, #DI_FRAME
    RET
    ENDP

    END