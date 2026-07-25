PARTICLES_ASM EQU 1

    INCLUDE data.inc
    INCLUDE proto.inc

P_MAX_PARTICLES   EQU 64
P_LIFETIME        EQU 30
P_SIZE            EQU 4
P_GRAVITY         EQU 2
P_PER_CELL        EQU 3
P_CELL_CENTER     EQU 32       ; BOARD_Y + BLOCK_SIZE/2 = 20 + 12

    EXPORT InitParticles
    EXPORT SpawnLineExplosion
    EXPORT UpdateParticles
    EXPORT RenderParticles

    AREA |.text|, CODE, READONLY, ALIGN=4
    ALIGN 16

; ---------------------------------------------------------------------------
; InitParticles
; X0 = pGame
; ---------------------------------------------------------------------------
InitParticles PROC
    STP X19, X20, [SP, #-32]!
    STR X21, [SP, #16]

    MOV X19, X0

    STR WZR, [X19, #GAME_STATE_particleCount]

    ADD X20, X19, #GAME_STATE_particles
    MOV W21, #P_MAX_PARTICLES

ip_clear_loop
    STRB WZR, [X20, #PARTICLE_active]
    ADD X20, X20, #PARTICLE_STRUCT_SIZE
    SUBS W21, W21, #1
    B.NE ip_clear_loop

    LDR X21, [SP, #16]
    LDP X19, X20, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; SpawnLineExplosion
; X0 = pGame, W1 = lineY
; ---------------------------------------------------------------------------
SpawnLineExplosion PROC
    STP X19, X20, [SP, #-80]!
    STP X21, X22, [SP, #16]
    STP X23, X24, [SP, #32]
    STP X25, X26, [SP, #48]
    STP X27, X28, [SP, #64]

    MOV X19, X0                  ; pGame
    MOV W20, W1                  ; lineY

    ; pixelY = lineY * 25 + 20 + 12
    MOV W8, W20
    MOV W9, #25
    MUL W8, W8, W9
    ADD W8, W8, #P_CELL_CENTER
    MOV W21, W8

    LDR W22, [X19, #GAME_STATE_boardWidth]

    ; RNG multiplier: 1103515245
    MOVZ W28, #0x4E6D
    MOVK W28, #0x41C6, LSL #16

    MOV W23, #0                  ; column

sle_column_loop
    CMP W23, W22
    B.GE sle_done

    ; color = board[lineY * width + column]
    MUL W8, W20, W22
    ADD W8, W8, W23
    ADD X9, X19, #GAME_STATE_board
    LDRB W24, [X9, W8, UXTW]

    CBZ W24, sle_next_column

    ; pixelX = column * 25 + 20 + 12
    MOV W8, W23
    MOV W9, #25
    MUL W8, W8, W9
    ADD W8, W8, #P_CELL_CENTER
    MOV W25, W8

    MOV W26, #P_PER_CELL

sle_spawn_particle
    CBZ W26, sle_next_column

    ; Find inactive particle slot
    ADD X27, X19, #GAME_STATE_particles
    MOV W8, #0

sle_find_slot
    CMP W8, #P_MAX_PARTICLES
    B.GE sle_next_column

    LDRB W9, [X27, #PARTICLE_active]
    CBZ W9, sle_found_slot

    ADD X27, X27, #PARTICLE_STRUCT_SIZE
    ADD W8, W8, #1
    B sle_find_slot

sle_found_slot
    MOV W9, #1
    STRB W9, [X27, #PARTICLE_active]

    ; color = cellColor & 7
    MOV W11, #7
    AND W9, W24, W11
    STRB W9, [X27, #PARTICLE_color]

    MOV W9, #P_LIFETIME
    STRB W9, [X27, #PARTICLE_life]

    ; X position with random offset (-8..+7)
    LDR W9, [X19, #GAME_STATE_rngSeed]
    MUL W9, W9, W28
    MOV W10, #12345
    ADD W9, W9, W10
    STR W9, [X19, #GAME_STATE_rngSeed]

    LSR W10, W9, #16
    MOV W11, #15
    AND W10, W10, W11
    SUB W10, W10, #8
    ADD W10, W10, W25
    STR W10, [X27, #PARTICLE_x]

    ; Y position with random offset (-8..+7)
    LDR W9, [X19, #GAME_STATE_rngSeed]
    MUL W9, W9, W28
    MOV W10, #12345
    ADD W9, W9, W10
    STR W9, [X19, #GAME_STATE_rngSeed]

    LSR W10, W9, #16
    MOV W11, #15
    AND W10, W10, W11
    SUB W10, W10, #8
    ADD W10, W10, W21
    STR W10, [X27, #PARTICLE_y]

    ; X velocity (-6..+5)
    LDR W9, [X19, #GAME_STATE_rngSeed]
    MUL W9, W9, W28
    MOV W10, #12345
    ADD W9, W9, W10
    STR W9, [X19, #GAME_STATE_rngSeed]

    LSR W10, W9, #16
    MOV W11, #11
    AND W10, W10, W11
    SUB W10, W10, #6
    STR W10, [X27, #PARTICLE_vx]

    ; Y velocity (-8..-1)
    LDR W9, [X19, #GAME_STATE_rngSeed]
    MUL W9, W9, W28
    MOV W10, #12345
    ADD W9, W9, W10
    STR W9, [X19, #GAME_STATE_rngSeed]

    LSR W10, W9, #16
    MOV W11, #7
    AND W10, W10, W11
    SUB W10, W10, #8
    STR W10, [X27, #PARTICLE_vy]

    LDR W9, [X19, #GAME_STATE_particleCount]
    ADD W9, W9, #1
    STR W9, [X19, #GAME_STATE_particleCount]

    SUB W26, W26, #1
    B sle_spawn_particle

sle_next_column
    ADD W23, W23, #1
    B sle_column_loop

sle_done
    LDP X27, X28, [SP, #64]
    LDP X25, X26, [SP, #48]
    LDP X23, X24, [SP, #32]
    LDP X21, X22, [SP, #16]
    LDP X19, X20, [SP], #80
    RET
    ENDP

; ---------------------------------------------------------------------------
; UpdateParticles
; X0 = pGame, W1 = deltaTimeMs
; ---------------------------------------------------------------------------
UpdateParticles PROC
    STP X19, X20, [SP, #-32]!
    STR X21, [SP, #16]

    MOV X19, X0

    LDR W8, [X19, #GAME_STATE_particleCount]
    CBZ W8, up_done

    ADD X20, X19, #GAME_STATE_particles
    MOV W21, #0

up_update_loop
    CMP W21, #P_MAX_PARTICLES
    B.GE up_done

    LDRB W8, [X20, #PARTICLE_active]
    CBZ W8, up_next_particle

    ; x += vx
    LDR W8, [X20, #PARTICLE_x]
    LDR W9, [X20, #PARTICLE_vx]
    ADD W8, W8, W9
    STR W8, [X20, #PARTICLE_x]

    ; y += vy
    LDR W8, [X20, #PARTICLE_y]
    LDR W9, [X20, #PARTICLE_vy]
    ADD W8, W8, W9
    STR W8, [X20, #PARTICLE_y]

    ; vy += gravity
    LDR W8, [X20, #PARTICLE_vy]
    ADD W8, W8, #P_GRAVITY
    STR W8, [X20, #PARTICLE_vy]

    ; life--
    LDRB W8, [X20, #PARTICLE_life]
    SUBS W8, W8, #1
    STRB W8, [X20, #PARTICLE_life]
    B.NE up_next_particle

    STRB WZR, [X20, #PARTICLE_active]

    LDR W8, [X19, #GAME_STATE_particleCount]
    CBZ W8, up_skip_dec
    SUB W8, W8, #1
    STR W8, [X19, #GAME_STATE_particleCount]

up_skip_dec

up_next_particle
    ADD X20, X20, #PARTICLE_STRUCT_SIZE
    ADD W21, W21, #1
    B up_update_loop

up_done
    LDR X21, [SP, #16]
    LDP X19, X20, [SP], #32
    RET
    ENDP

; ---------------------------------------------------------------------------
; RenderParticles
; X0 = pRenderer, X1 = pGame
; ---------------------------------------------------------------------------
RP_FRAME EQU 0x80
RP_RECT  EQU 0x40

RenderParticles PROC
    STP X29, X30, [SP, #-RP_FRAME]!
    MOV X29, SP
    STP X19, X20, [SP, #16]
    STP X21, X22, [SP, #32]
    STP X23, X24, [SP, #48]

    MOV X19, X0
    MOV X20, X1

    LDR W8, [X20, #GAME_STATE_particleCount]
    CBZ W8, rp_done

    ADD X21, X20, #GAME_STATE_particles
    MOV W22, #0

rp_render_loop
    CMP W22, #P_MAX_PARTICLES
    B.GE rp_done

    LDRB W8, [X21, #PARTICLE_active]
    CBZ W8, rp_next_render

    ; Brush from particle color
    LDRB W8, [X21, #PARTICLE_color]
    MOV W9, #7
    AND W8, W8, W9

    ADD X9, X19, #RENDERER_STATE_colorBrushes
    LDR X23, [X9, X8, LSL #3]

    ; RECT: left = x, top = y
    LDR W8, [X21, #PARTICLE_x]
    STR W8, [SP, #(RP_RECT + 0)]

    LDR W8, [X21, #PARTICLE_y]
    STR W8, [SP, #(RP_RECT + 4)]

    ; size = life * P_SIZE / P_LIFETIME, minimum 1
    LDRB W8, [X21, #PARTICLE_life]
    MOV W9, #P_SIZE
    MUL W8, W8, W9
    MOV W9, #P_LIFETIME
    UDIV W8, W8, W9

    CBNZ W8, rp_size_ok
    MOV W8, #1

rp_size_ok
    LDR W9, [SP, #(RP_RECT + 0)]
    ADD W9, W9, W8
    STR W9, [SP, #(RP_RECT + 8)]

    LDR W9, [SP, #(RP_RECT + 4)]
    ADD W9, W9, W8
    STR W9, [SP, #(RP_RECT + 12)]

    LDR X0, [X19, #RENDERER_STATE_hdcMem]
    ADD X1, SP, #RP_RECT
    MOV X2, X23
    BL FillRect

rp_next_render
    ADD X21, X21, #PARTICLE_STRUCT_SIZE
    ADD W22, W22, #1
    B rp_render_loop

rp_done
    LDP X23, X24, [SP, #48]
    LDP X21, X22, [SP, #32]
    LDP X19, X20, [SP, #16]
    LDP X29, X30, [SP], #RP_FRAME
    RET
    ENDP

    END