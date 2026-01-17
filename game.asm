.386
.model flat, stdcall
option casemap:none

include windows.inc
include kernel32.inc
includelib kernel32.lib

include data.inc
include proto.inc

.data
; Tetromino shape templates: I, O, Z, S, T, L, J
; Format: x0,y0, x1,y1, x2,y2, x3,y3 (4 blocks per shape)
SHAPE_TEMPLATES dd 0,1,1,1,2,1,3,1  ; I-piece (horizontal)
                dd 0,0,1,0,0,1,1,1  ; O-piece (square)
                dd 1,0,0,1,1,1,2,1  ; Z-piece
                dd 0,1,1,1,1,0,2,0  ; S-piece
                dd 0,0,1,0,1,1,2,1  ; T-piece
                dd 0,0,0,1,1,1,2,1  ; L-piece
                dd 2,0,0,1,1,1,2,1  ; J-piece

; 7-bag randomizer state
bagBytes db 0, 1, 2, 3, 4, 5, 6     ; Bag containing all 7 piece types
bagIndex dd 7                        ; Current position in bag (7 = empty, reshuffle needed)

.code

; Initialize game state with board dimensions
; Args: pGame - pointer to GAME_STATE, boardWidth/Height - dimensions
InitGame proc pGame:DWORD, boardWidth:DWORD, boardHeight:DWORD
    push esi
    push edi
    mov esi, pGame
    
    ; Store board dimensions
    mov eax, boardWidth
    mov [esi].GAME_STATE.boardWidth, eax
    mov eax, boardHeight
    mov [esi].GAME_STATE.boardHeight, eax
    
    ; Reset game metrics
    mov [esi].GAME_STATE.score, 0
    mov [esi].GAME_STATE.lines, 0
    mov [esi].GAME_STATE.level, 1
    mov [esi].GAME_STATE.gameOver, 0
    mov [esi].GAME_STATE.paused, 0
    
    ; Clear board memory
    push esi
    lea eax, [esi].GAME_STATE.board
    mov ecx, boardHeight
    imul ecx, boardWidth
    xor edx, edx
@@:
    mov byte ptr [eax], dl              ; Set cell to empty (0)
    inc eax
    dec ecx
    jnz @B
    pop esi
    
    ; Seed RNG with current tick count
    invoke GetTickCount
    mov [esi].GAME_STATE.rngSeed, eax
    
    ; Force bag reshuffle on first piece
    mov bagIndex, 7
    
    ; Load persistent data from registry
    invoke LoadHighScore, pGame
    invoke LoadPlayerName, pGame
    
    ; Generate first two pieces
    invoke GenerateRandomPiece, pGame, addr [esi].GAME_STATE.nextPiece
    invoke SpawnNewPiece, pGame
    
    pop edi
    pop esi
    ret
InitGame endp

; Reset game state (new game from Game Over)
StartGame proc pGame:DWORD
    push esi
    push edi
    mov esi, pGame
    
    ; Clear entire board
    lea eax, [esi].GAME_STATE.board
    mov ecx, [esi].GAME_STATE.boardHeight
    imul ecx, [esi].GAME_STATE.boardWidth
    xor edx, edx
@@:
    mov byte ptr [eax], dl
    inc eax
    dec ecx
    jnz @B
    
    ; Reset game state to defaults
    mov [esi].GAME_STATE.score, 0
    mov [esi].GAME_STATE.lines, 0
    mov [esi].GAME_STATE.level, 1
    mov [esi].GAME_STATE.gameOver, 0
    mov [esi].GAME_STATE.paused, 0
    
    ; Reset randomizer
    mov bagIndex, 7
    
    ; Spawn initial pieces
    invoke GenerateRandomPiece, pGame, addr [esi].GAME_STATE.nextPiece
    invoke SpawnNewPiece, pGame
    
    pop edi
    pop esi
    ret
StartGame endp

; Generate random piece using 7-bag algorithm (ensures fair distribution)
; Args: pGame - game state, pPiece - output piece structure
GenerateRandomPiece proc pGame:DWORD, pPiece:DWORD
    local blockPtr:DWORD
    push esi
    push edi
    push ebx
    mov esi, pGame
    mov edi, pPiece
    
    ; Check if bag needs reshuffling
    cmp bagIndex, 7
    jl @get_from_bag
    
    ; Fisher-Yates shuffle algorithm
    mov ecx, 6
@shuffle_loop:
    push ecx
    
    ; LCG: seed = seed * 1103515245 + 12345
    mov eax, [esi].GAME_STATE.rngSeed
    imul eax, 1103515245
    add eax, 12345
    mov [esi].GAME_STATE.rngSeed, eax
    
    ; Extract random bits
    shr eax, 16
    and eax, 7FFFh
    
    ; rand % (ecx + 1) for swap index
    xor edx, edx
    mov ecx, [esp]
    inc ecx
    div ecx
    
    pop ecx
    
    ; Swap bagBytes[ecx] with bagBytes[edx]
    lea eax, bagBytes
    mov bl, [eax + ecx]
    mov bh, [eax + edx]
    mov [eax + ecx], bh
    mov [eax + edx], bl
    
    dec ecx
    jns @shuffle_loop
    
    ; Reset bag index after shuffle
    mov bagIndex, 0

@get_from_bag:
    ; Pull next piece from bag
    mov eax, bagIndex
    lea ecx, bagBytes
    movzx edx, byte ptr [ecx + eax]
    inc bagIndex
    
    ; Set piece type and initial position
    mov [edi].PIECE.shapeType, dl
    
    ; Center horizontally at top
    mov eax, [esi].GAME_STATE.boardWidth
    shr eax, 1
    dec eax
    mov [edi].PIECE.x, eax
    mov [edi].PIECE.y, 0
    mov [edi].PIECE.yFloat, 0
    
    ; Copy block template from SHAPE_TEMPLATES
    movzx eax, dl
    mov ebx, eax
    shl eax, 5                          ; shapeType * 32 (8 dwords)
    lea ecx, SHAPE_TEMPLATES
    add ecx, eax
    
    ; Copy 8 dwords (4 blocks * 2 coords each)
    lea eax, [edi].PIECE.blocks
    mov blockPtr, eax
    
    mov eax, [ecx]
    mov edx, blockPtr
    mov [edx], eax
    mov eax, [ecx + 4]
    mov [edx + 4], eax
    
    mov eax, [ecx + 8]
    mov edx, blockPtr
    mov [edx + 8], eax
    mov eax, [ecx + 12]
    mov [edx + 12], eax
    
    mov eax, [ecx + 16]
    mov edx, blockPtr
    mov [edx + 16], eax
    mov eax, [ecx + 20]
    mov [edx + 20], eax
    
    mov eax, [ecx + 24]
    mov edx, blockPtr
    mov [edx + 24], eax
    mov eax, [ecx + 28]
    mov [edx + 28], eax
    
    ; Set color (shapeType + 1)
    inc bl
    mov [edi].PIECE.color, bl
    
    pop ebx
    pop edi
    pop esi
    ret
GenerateRandomPiece endp

; Move nextPiece to currentPiece, generate new nextPiece
SpawnNewPiece proc pGame:DWORD
    push esi
    push edi
    mov esi, pGame
    
    ; Copy nextPiece -> currentPiece (dword by dword)
    lea edi, [esi].GAME_STATE.currentPiece
    lea eax, [esi].GAME_STATE.nextPiece
    mov ecx, sizeof PIECE / 4
@@:
    mov edx, [eax]
    mov [edi], edx
    add eax, 4
    add edi, 4
    dec ecx
    jnz @B
    
    ; Generate next piece for preview
    invoke GenerateRandomPiece, pGame, addr [esi].GAME_STATE.nextPiece
    
    ; Check if spawn position is valid (Game Over check)
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    .IF eax
        mov [esi].GAME_STATE.gameOver, 1
    .ENDIF
    
    pop edi
    pop esi
    ret
SpawnNewPiece endp

; Check if piece collides with board boundaries or locked blocks
; Returns: eax = 1 if collision, 0 if valid
CheckCollision proc pGame:DWORD, pPiece:DWORD
    push esi
    push edi
    push ebx
    mov esi, pGame
    mov edi, pPiece
    
    ; Get piece world position
    mov edx, [edi].PIECE.x
    mov ebx, [edi].PIECE.y
    
    ; Check all 4 blocks
    xor ecx, ecx
@@loop_check:
    cmp ecx, 4
    jge @@no_collision
    
    ; Calculate block world X
    mov eax, [edi + PIECE.blocks + ecx*8]
    add eax, edx
    
    ; Check left boundary
    cmp eax, 0
    jl @collision
    
    ; Check right boundary
    cmp eax, [esi].GAME_STATE.boardWidth
    jge @collision
    
    ; Calculate block world Y
    push eax
    mov eax, [edi + PIECE.blocks + ecx*8 + 4]
    add eax, ebx
    mov edi, eax
    pop eax
    
    ; Check bottom boundary
    cmp edi, [esi].GAME_STATE.boardHeight
    jge @collision
    
    ; Skip board check if above top (allow spawn)
    cmp edi, 0
    jl @@skip_check
    
    ; Check if board cell is occupied
    push eax
    push ecx
    push edx
    imul edi, [esi].GAME_STATE.boardWidth
    add edi, eax
    lea eax, [esi].GAME_STATE.board
    movzx eax, byte ptr [eax + edi]
    pop edx
    pop ecx
    test eax, eax
    pop eax
    jnz @collision
    
@@skip_check:
    mov edi, pPiece
    inc ecx
    jmp @@loop_check
    
@@no_collision:
    xor eax, eax
    jmp @exit
    
@collision:
    mov eax, 1
@exit:
    pop ebx
    pop edi
    pop esi
    ret
CheckCollision endp

; Lock currentPiece to board, clear lines, spawn next piece
LockPiece proc pGame:DWORD
    push esi
    push edi
    push ebx
    mov esi, pGame
    
    ; Get piece data
    lea edi, [esi].GAME_STATE.currentPiece
    movzx ebx, [edi].PIECE.color
    mov edx, [edi].PIECE.x
    mov eax, [edi].PIECE.y
    
    ; Write all 4 blocks to board
    xor ecx, ecx
.WHILE ecx < 4
    push eax
    push ecx
    push edx
    
    ; Calculate block position
    mov eax, [edi + PIECE.blocks + ecx*8]
    add eax, edx
    mov edx, [edi + PIECE.blocks + ecx*8 + 4]
    add edx, [esp+8]
    
    ; Write color to board[y * width + x]
    push eax
    imul edx, [esi].GAME_STATE.boardWidth
    add edx, eax
    lea eax, [esi].GAME_STATE.board
    mov byte ptr [eax + edx], bl
    pop eax
    
    pop edx
    pop ecx
    pop eax
    inc ecx
.ENDW
    
    ; Clear completed lines and get count
    invoke ClearFullLines, pGame
    mov ecx, eax
    
    ; Update score if lines were cleared
    .IF ecx > 0
        add [esi].GAME_STATE.lines, ecx
        
        ; Score = lines² * 100 * level
        push ecx
        imul ecx, ecx
        imul ecx, 100
        imul ecx, [esi].GAME_STATE.level
        add [esi].GAME_STATE.score, ecx
        pop ecx
        
        ; Level up every 10 lines
        mov eax, [esi].GAME_STATE.lines
        xor edx, edx
        mov ecx, 10
        div ecx
        inc eax
        mov [esi].GAME_STATE.level, eax
        
        ; Update high score if beaten
        mov eax, [esi].GAME_STATE.score
        .IF eax > [esi].GAME_STATE.highScore
            invoke SaveHighScore, pGame
        .ENDIF
    .ENDIF
    
    ; Spawn next piece
    invoke SpawnNewPiece, pGame
    
    pop ebx
    pop edi
    pop esi
    ret
LockPiece endp

; Scan board for full lines, remove them, shift rows down
; Returns: eax = number of lines cleared
ClearFullLines proc pGame:DWORD
    push esi
    push edi
    push ebx
    mov esi, pGame
    
    xor ebx, ebx                        ; Lines cleared counter
    mov ecx, [esi].GAME_STATE.boardHeight
    dec ecx
    
    ; Scan from bottom to top
.WHILE SDWORD PTR ecx >= 0
    push ecx
    mov edi, ecx
    imul edi, [esi].GAME_STATE.boardWidth
    lea eax, [esi].GAME_STATE.board
    add edi, eax
    
    ; Check if line is full
    mov edx, 1
    push ecx
    xor ecx, ecx
@@:
    cmp byte ptr [edi + ecx], 0
    je @notfull
    inc ecx
    cmp ecx, [esi].GAME_STATE.boardWidth
    jl @B
    jmp @isfull
@notfull:
    xor edx, edx
@isfull:
    pop ecx
    
    .IF edx
        inc ebx                         ; Increment cleared counter
        
        ; Shift all rows above down by one
        push ecx
.WHILE SDWORD PTR ecx > 0
        push ecx
        mov edi, ecx
        imul edi, [esi].GAME_STATE.boardWidth
        dec ecx
        mov eax, ecx
        imul eax, [esi].GAME_STATE.boardWidth
        
        lea edx, [esi].GAME_STATE.board
        add edi, edx
        add eax, edx
        
        ; Copy row[y-1] to row[y]
        push ecx
        xor ecx, ecx
@@:
        mov dl, byte ptr [eax + ecx]
        mov byte ptr [edi + ecx], dl
        inc ecx
        cmp ecx, [esi].GAME_STATE.boardWidth
        jl @B
        pop ecx
        
        pop ecx
        dec ecx
.ENDW
        pop ecx
        
        ; Clear top row
        lea edi, [esi].GAME_STATE.board
        push ecx
        xor ecx, ecx
@@:
        mov byte ptr [edi + ecx], 0
        inc ecx
        cmp ecx, [esi].GAME_STATE.boardWidth
        jl @B
        pop ecx
        
        ; Re-check same row (shifted down)
        inc ecx
    .ENDIF
    
    pop ecx
    dec ecx
.ENDW
    
    mov eax, ebx
    pop ebx
    pop edi
    pop esi
    ret
ClearFullLines endp

; Update game physics (gravity/falling)
; Args: deltaTimeMs - time since last update in milliseconds
UpdateGame proc pGame:DWORD, deltaTimeMs:DWORD
    push esi
    push edi
    mov esi, pGame
    
    ; Skip update if game over or paused
    cmp [esi].GAME_STATE.gameOver, 0
    jne @@exit_update
    cmp [esi].GAME_STATE.paused, 0
    jne @@exit_update
    
    ; Calculate fall speed: 300ms + (level-1)*50ms per row
    mov eax, [esi].GAME_STATE.level
    dec eax
    imul eax, 50
    add eax, 300
    
    ; Fixed-point gravity accumulation (yFloat in 1/10000 units)
    mov ecx, deltaTimeMs
    imul ecx, eax
    shr ecx, 3
    add [esi].GAME_STATE.yFloat, ecx
    
@@check_fall:
    ; Drop one row when accumulated >= 10000
    cmp [esi].GAME_STATE.yFloat, 10000
    jl @@exit_update
    
    sub [esi].GAME_STATE.yFloat, 10000
    
    ; Try moving piece down
    mov eax, [esi].GAME_STATE.currentPiece.y
    inc eax
    mov [esi].GAME_STATE.currentPiece.y, eax
    
    ; Check collision after move
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    test eax, eax
    jz @@check_fall
    
    ; Collision: undo move, lock piece
    dec [esi].GAME_STATE.currentPiece.y
    mov [esi].GAME_STATE.yFloat, 0
    invoke LockPiece, pGame
    
@@exit_update:
    pop edi
    pop esi
    ret
UpdateGame endp

; Move piece left if no collision
MoveLeft proc pGame:DWORD
    push esi
    mov esi, pGame
    
    .IF [esi].GAME_STATE.gameOver
        pop esi
        ret
    .ENDIF
    
    ; Try move, revert if collision
    dec [esi].GAME_STATE.currentPiece.x
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    .IF eax
        inc [esi].GAME_STATE.currentPiece.x
    .ENDIF
    
    pop esi
    ret
MoveLeft endp

; Move piece right if no collision
MoveRight proc pGame:DWORD
    push esi
    mov esi, pGame
    
    .IF [esi].GAME_STATE.gameOver
        pop esi
        ret
    .ENDIF
    
    ; Try move, revert if collision
    inc [esi].GAME_STATE.currentPiece.x
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    .IF eax
        dec [esi].GAME_STATE.currentPiece.x
    .ENDIF
    
    pop esi
    ret
MoveRight endp

; Move piece down by dy rows
; Returns: eax = 1 if moved, 0 if locked
MoveDown proc pGame:DWORD, dy:DWORD
    push esi
    mov esi, pGame
    
    .IF [esi].GAME_STATE.gameOver || [esi].GAME_STATE.paused
        xor eax, eax
        pop esi
        ret
    .ENDIF
    
    ; Try move down
    mov eax, dy
    add [esi].GAME_STATE.currentPiece.y, eax
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    .IF eax
        ; Collision: undo and lock
        mov eax, dy
        sub [esi].GAME_STATE.currentPiece.y, eax
        invoke LockPiece, pGame
        xor eax, eax
    .ELSE
        mov eax, 1
    .ENDIF
    
    pop esi
    ret
MoveDown endp

; Rotate piece 90° clockwise with collision check
RotatePiece proc pGame:DWORD
    push esi
    push edi
    push ebx
    mov esi, pGame
    
    .IF [esi].GAME_STATE.gameOver
        pop ebx
        pop edi
        pop esi
        ret
    .ENDIF
    
    lea edi, [esi].GAME_STATE.currentPiece
    
    ; O-piece doesn't rotate
    .IF byte ptr [edi].PIECE.shapeType == 1
        pop ebx
        pop edi
        pop esi
        ret
    .ENDIF
    
    ; Rotation pivot point (1,1 for most pieces)
    mov ecx, 1
    mov edx, 1
    
    .IF byte ptr [edi].PIECE.shapeType == 0
        mov ecx, 1
        mov edx, 1
    .ENDIF
    
    ; Apply rotation matrix: (x,y) -> (-y, x) around pivot
    push esi
    xor esi, esi
.WHILE esi < 4
    mov eax, [edi + PIECE.blocks + esi*8]
    sub eax, ecx
    mov ebx, [edi + PIECE.blocks + esi*8 + 4]
    sub ebx, edx
    
    ; new_x = -old_y + pivot_x
    push eax
    mov eax, ebx
    neg eax
    add eax, ecx
    mov [edi + PIECE.blocks + esi*8], eax
    pop eax
    ; new_y = old_x + pivot_y
    add eax, edx
    mov [edi + PIECE.blocks + esi*8 + 4], eax
    
    inc esi
.ENDW
    pop esi
    
    ; Revert rotation if collision
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    .IF eax
        ; Reverse rotation matrix
        push esi
        xor esi, esi
.WHILE esi < 4
        mov eax, [edi + PIECE.blocks + esi*8]
        sub eax, ecx
        mov ebx, [edi + PIECE.blocks + esi*8 + 4]
        sub ebx, edx
        
        push ebx
        mov ebx, eax
        add ebx, ecx
        mov [edi + PIECE.blocks + esi*8], ebx
        pop ebx
        neg ebx
        add ebx, edx
        mov [edi + PIECE.blocks + esi*8 + 4], ebx
        
        inc esi
.ENDW
        pop esi
    .ENDIF
    
    pop ebx
    pop edi
    pop esi
    ret
RotatePiece endp

; Hard drop: instantly drop piece to lowest valid position
DropPiece proc pGame:DWORD
    push esi
    mov esi, pGame
    
    .IF [esi].GAME_STATE.gameOver || [esi].GAME_STATE.paused
        pop esi
        ret
    .ENDIF
    
    ; Move down until collision
@@:
    inc [esi].GAME_STATE.currentPiece.y
    invoke CheckCollision, pGame, addr [esi].GAME_STATE.currentPiece
    test eax, eax
    jz @B
    
    ; Back up one row and lock
    dec [esi].GAME_STATE.currentPiece.y
    invoke LockPiece, pGame
    
    pop esi
    ret
DropPiece endp

; Pause control functions
PauseGame proc pGame:DWORD
    mov eax, pGame
    mov byte ptr [eax].GAME_STATE.paused, 1
    ret
PauseGame endp

ResumeGame proc pGame:DWORD
    mov eax, pGame
    mov byte ptr [eax].GAME_STATE.paused, 0
    ret
ResumeGame endp

TogglePause proc pGame:DWORD
    mov eax, pGame
    xor byte ptr [eax].GAME_STATE.paused, 1
    ret
TogglePause endp

; Copy player name to game state (Unicode string)
SetPlayerName proc pGame:DWORD, pName:DWORD
    push esi
    push edi
    mov esi, pName
    mov edi, pGame
    lea edi, [edi].GAME_STATE.playerName
    
    ; Copy wide chars until null or 127 chars
    xor ecx, ecx
@@:
    mov ax, word ptr [esi + ecx*2]
    mov word ptr [edi + ecx*2], ax
    test ax, ax
    jz @F
    inc ecx
    cmp ecx, 127
    jl @B
@@:
    mov word ptr [edi + ecx*2], 0       ; Null terminate
    
    pop edi
    pop esi
    ret
SetPlayerName endp

end
