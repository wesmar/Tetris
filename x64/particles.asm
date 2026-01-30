INCLUDE data.inc
INCLUDE proto.inc

.CONST
ALIGN 16
MAX_PARTICLES equ 64
PARTICLE_LIFETIME equ 30               ; Particle lifetime in frames
PARTICLE_SIZE equ 4                    ; Particle size in pixels
PARTICLE_GRAVITY equ 2                 ; Gravity per frame
PARTICLES_PER_CELL equ 3               ; Particles spawned per cell

; Rendering constants (must match render.asm)
BLOCK_SIZE equ 25
BOARD_X equ 20
BOARD_Y equ 20

.CODE
ALIGN 16

; Initialize particle system (called from InitGame/StartGame)
; RCX = pGame
InitParticles PROC pGame:QWORD
    push rsi
    push rdi
    sub rsp, 28h

    mov rsi, rcx

    ; Reset particle count
    mov DWORD PTR [rsi].GAME_STATE.particleCount, 0

    ; Clear all particles to inactive state
    lea rdi, [rsi].GAME_STATE.particles
    mov ecx, MAX_PARTICLES

@@clear_loop:
    mov BYTE PTR [rdi].PARTICLE.active, 0
    add rdi, SIZEOF PARTICLE
    dec ecx
    jnz @@clear_loop

    add rsp, 28h
    pop rdi
    pop rsi
    ret
InitParticles ENDP

; Spawn explosion particles from a cleared line
; RCX = pGame, EDX = lineY (board row)
SpawnLineExplosion PROC pGame:QWORD, lineY:DWORD
    push rsi
    push rdi
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48h

    mov rsi, rcx                         ; pGame
    mov r12d, edx                        ; lineY

    ; Calculate base pixel Y position for this row
    mov eax, r12d
    imul eax, BLOCK_SIZE
    add eax, BOARD_Y
    add eax, BLOCK_SIZE / 2              ; Center of cell
    mov r14d, eax                        ; pixelY base

    ; Get board width for column iteration
    mov r15d, [rsi].GAME_STATE.boardWidth

    ; Iterate through each column
    xor ebx, ebx                         ; column counter

@@column_loop:
    cmp ebx, r15d
    jge @@done

    ; Get cell color from board
    mov eax, r12d
    imul eax, [rsi].GAME_STATE.boardWidth
    add eax, ebx
    lea rcx, [rsi].GAME_STATE.board
    movzx r13d, BYTE PTR [rcx + rax]     ; r13d = cell color

    ; Skip empty cells
    test r13d, r13d
    jz @@next_column

    ; Calculate base pixel X position for this column
    mov eax, ebx
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    add eax, BLOCK_SIZE / 2              ; Center of cell
    mov [rsp+40h], eax                   ; Save pixelX base

    ; Spawn PARTICLES_PER_CELL particles for this cell
    mov r8d, PARTICLES_PER_CELL

@@spawn_particle:
    test r8d, r8d
    jz @@next_column

    ; Find an inactive particle slot
    lea rdi, [rsi].GAME_STATE.particles
    xor ecx, ecx

@@find_slot:
    cmp ecx, MAX_PARTICLES
    jge @@next_column                    ; No free slots available

    cmp BYTE PTR [rdi].PARTICLE.active, 0
    je @@found_slot

    add rdi, SIZEOF PARTICLE
    inc ecx
    jmp @@find_slot

@@found_slot:
    ; Mark as active
    mov BYTE PTR [rdi].PARTICLE.active, 1

    ; Set color
    mov eax, r13d
    and eax, 7
    mov [rdi].PARTICLE.color, al

    ; Set lifetime
    mov BYTE PTR [rdi].PARTICLE.life, PARTICLE_LIFETIME

    ; Set X position with small random offset
    mov eax, [rsi].GAME_STATE.rngSeed
    imul eax, 1103515245
    add eax, 12345
    mov [rsi].GAME_STATE.rngSeed, eax
    shr eax, 16
    and eax, 15                          ; 0-15 random offset
    sub eax, 8                           ; -8 to +7
    add eax, [rsp+40h]                   ; Add base X
    mov [rdi].PARTICLE.x, eax

    ; Set Y position with small random offset
    mov eax, [rsi].GAME_STATE.rngSeed
    imul eax, 1103515245
    add eax, 12345
    mov [rsi].GAME_STATE.rngSeed, eax
    shr eax, 16
    and eax, 15
    sub eax, 8
    add eax, r14d                        ; Add base Y
    mov [rdi].PARTICLE.y, eax

    ; Set random X velocity (-6 to +5 pixels per frame)
    mov eax, [rsi].GAME_STATE.rngSeed
    imul eax, 1103515245
    add eax, 12345
    mov [rsi].GAME_STATE.rngSeed, eax
    shr eax, 16
    and eax, 11                          ; 0-11
    sub eax, 6                           ; -6 to +5
    mov [rdi].PARTICLE.vx, eax

    ; Set random Y velocity (-8 to -1 pixels per frame, upward bias)
    mov eax, [rsi].GAME_STATE.rngSeed
    imul eax, 1103515245
    add eax, 12345
    mov [rsi].GAME_STATE.rngSeed, eax
    shr eax, 16
    and eax, 7                           ; 0-7
    sub eax, 8                           ; -8 to -1 (upward)
    mov [rdi].PARTICLE.vy, eax

    ; Increment active particle count
    inc DWORD PTR [rsi].GAME_STATE.particleCount

    ; Move to next particle spawn
    dec r8d
    jmp @@spawn_particle

@@next_column:
    inc ebx
    jmp @@column_loop

@@done:
    add rsp, 48h
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rdi
    pop rsi
    ret
SpawnLineExplosion ENDP

; Update all active particles (called from UpdateGame)
; RCX = pGame, EDX = deltaTimeMs
UpdateParticles PROC pGame:QWORD, deltaTimeMs:DWORD
    push rsi
    push rdi
    push rbx
    push r12
    sub rsp, 28h

    mov rsi, rcx
    mov r12d, edx                        ; deltaTimeMs

    ; Skip if no particles
    cmp DWORD PTR [rsi].GAME_STATE.particleCount, 0
    je @@done

    lea rdi, [rsi].GAME_STATE.particles
    xor ebx, ebx                         ; particle index

@@update_loop:
    cmp ebx, MAX_PARTICLES
    jge @@done

    cmp BYTE PTR [rdi].PARTICLE.active, 0
    je @@next_particle

    ; Update X position
    mov eax, [rdi].PARTICLE.x
    add eax, [rdi].PARTICLE.vx
    mov [rdi].PARTICLE.x, eax

    ; Update Y position
    mov eax, [rdi].PARTICLE.y
    add eax, [rdi].PARTICLE.vy
    mov [rdi].PARTICLE.y, eax

    ; Apply gravity (increase Y velocity)
    mov eax, [rdi].PARTICLE.vy
    add eax, PARTICLE_GRAVITY
    mov [rdi].PARTICLE.vy, eax

    ; Decrease lifetime
    dec BYTE PTR [rdi].PARTICLE.life
    jnz @@next_particle

    ; Particle died - mark as inactive
    mov BYTE PTR [rdi].PARTICLE.active, 0
    dec DWORD PTR [rsi].GAME_STATE.particleCount

@@next_particle:
    add rdi, SIZEOF PARTICLE
    inc ebx
    jmp @@update_loop

@@done:
    add rsp, 28h
    pop r12
    pop rbx
    pop rdi
    pop rsi
    ret
UpdateParticles ENDP

; Render all active particles (called from RenderGame)
; RCX = pRenderer, RDX = pGame
RenderParticles PROC pRenderer:QWORD, pGame:QWORD
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 70h

    mov [rsp+50h], rsi
    mov [rsp+58h], rdi
    mov [rsp+60h], rbx
    mov [rsp+68h], r12

    mov rsi, rcx                         ; pRenderer
    mov rdi, rdx                         ; pGame

    ; Skip if no particles
    cmp DWORD PTR [rdi].GAME_STATE.particleCount, 0
    je @@done

    lea rbx, [rdi].GAME_STATE.particles
    xor r12d, r12d                       ; particle index

@@render_loop:
    cmp r12d, MAX_PARTICLES
    jge @@done

    cmp BYTE PTR [rbx].PARTICLE.active, 0
    je @@next_render

    ; Get particle color brush
    movzx eax, BYTE PTR [rbx].PARTICLE.color
    and eax, 7
    mov r8, QWORD PTR [rsi + RENDERER_STATE.colorBrushes + rax*8]
    mov [rsp+48h], r8                    ; Save brush handle

    ; Calculate particle rectangle
    mov eax, [rbx].PARTICLE.x
    mov DWORD PTR [rsp+20h], eax         ; left

    mov eax, [rbx].PARTICLE.y
    mov DWORD PTR [rsp+24h], eax         ; top

    ; Calculate size based on remaining lifetime (shrinking effect)
    movzx eax, BYTE PTR [rbx].PARTICLE.life
    imul eax, PARTICLE_SIZE
    xor edx, edx
    mov ecx, PARTICLE_LIFETIME
    div ecx                              ; eax = size

    ; Minimum size of 1
    test eax, eax
    jnz @@size_ok
    mov eax, 1
@@size_ok:
    mov ecx, eax                         ; ecx = size

    mov eax, [rsp+20h]
    add eax, ecx
    mov DWORD PTR [rsp+28h], eax         ; right

    mov eax, [rsp+24h]
    add eax, ecx
    mov DWORD PTR [rsp+2Ch], eax         ; bottom

    ; Draw particle rectangle
    mov rcx, [rsi].RENDERER_STATE.hdcMem
    lea rdx, [rsp+20h]
    mov r8, [rsp+48h]
    mov [rsp+40h], r12                   ; Save loop counter
    call FillRect
    mov r12, [rsp+40h]                   ; Restore loop counter

@@next_render:
    add rbx, SIZEOF PARTICLE
    inc r12d
    jmp @@render_loop

@@done:
    mov rsi, [rsp+50h]
    mov rdi, [rsp+58h]
    mov rbx, [rsp+60h]
    mov r12, [rsp+68h]

    mov rsp, rbp
    pop rbp
    ret
RenderParticles ENDP

END
