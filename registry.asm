.386
.model flat, stdcall
option casemap:none

include windows.inc
include advapi32.inc
include kernel32.inc
includelib advapi32.lib
includelib kernel32.lib

include data.inc
include proto.inc

.const
REG_PATH_W equ <L"Software\Tetris">
REG_PLAYER_NAME_W equ <L"PlayerName">
REG_HIGH_SCORE_W equ <L"HighScore">
REG_HIGH_SCORE_NAME_W equ <L"HighScoreName">

.data
; Registry paths and keys (Unicode wide strings)
szRegPath dw 'S','o','f','t','w','a','r','e','\','T','e','t','r','i','s',0
szPlayerName dw 'P','l','a','y','e','r','N','a','m','e',0
szHighScore dw 'H','i','g','h','S','c','o','r','e',0
szHighScoreName dw 'H','i','g','h','S','c','o','r','e','N','a','m','e',0

.code

; Calculate length of Unicode string (in characters, not bytes)
; Args: pString - pointer to wide string
; Returns: eax = string length
StrLenW proc pString:DWORD
    push esi
    mov esi, pString
    xor eax, eax
@@:
    cmp word ptr [esi + eax*2], 0
    je @F
    inc eax
    jmp @B
@@:
    pop esi
    ret
StrLenW endp

; Save player name to registry (HKCU\Software\Tetris\PlayerName)
; Args: pName - pointer to Unicode string
; Returns: eax = 1 if success, 0 if failed
SavePlayerName proc pName:DWORD
    local hKey:DWORD
    local result:DWORD
    local nameLen:DWORD
    
    ; Create or open registry key
    invoke RegCreateKeyExW, HKEY_CURRENT_USER, offset szRegPath, 0, NULL,
        REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, addr hKey, NULL
    .IF eax != ERROR_SUCCESS
        xor eax, eax
        ret
    .ENDIF
    
    ; Calculate string byte size (length + 1) * 2
    invoke StrLenW, pName
    inc eax
    shl eax, 1
    mov nameLen, eax
    
    ; Write REG_SZ value
    invoke RegSetValueExW, hKey, offset szPlayerName, 0, REG_SZ,
        pName, nameLen
    mov result, eax
    
    invoke RegCloseKey, hKey
    
    ; Return success/failure
    mov eax, result
    .IF eax == ERROR_SUCCESS
        mov eax, 1
    .ELSE
        xor eax, eax
    .ENDIF
    ret
SavePlayerName endp

; Load player name from registry
; Args: pGame - pointer to GAME_STATE
; Returns: eax = 1 if loaded, 0 if not found
LoadPlayerName proc pGame:DWORD
    local hKey:DWORD
    local buffer[256]:WORD
    local bufferSize:DWORD
    local regType:DWORD
    push esi
    push edi
    
    ; Try to open registry key
    invoke RegOpenKeyExW, HKEY_CURRENT_USER, offset szRegPath, 0, KEY_READ, addr hKey
    .IF eax != ERROR_SUCCESS
        ; Key not found, set empty name
        mov esi, pGame
        lea edi, [esi].GAME_STATE.playerName
        mov word ptr [edi], 0
        pop edi
        pop esi
        xor eax, eax
        ret
    .ENDIF
    
    ; Read PlayerName value
    mov bufferSize, sizeof buffer
    invoke RegQueryValueExW, hKey, offset szPlayerName, NULL, addr regType,
        addr buffer, addr bufferSize
    
    push eax
    invoke RegCloseKey, hKey
    pop eax
    
    .IF eax == ERROR_SUCCESS
        mov eax, regType
        .IF eax == REG_SZ
            ; Copy buffer to game state (max 127 chars)
            mov esi, pGame
            lea edi, [esi].GAME_STATE.playerName
            lea esi, buffer
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
            mov word ptr [edi + ecx*2], 0
            pop edi
            pop esi
            mov eax, 1
            ret
        .ENDIF
    .ENDIF
    
    ; Failed to read, set empty name
    mov esi, pGame
    lea edi, [esi].GAME_STATE.playerName
    mov word ptr [edi], 0
    pop edi
    pop esi
    xor eax, eax
    ret
LoadPlayerName endp

; Save high score and scorer name to registry
; Args: pGame - pointer to GAME_STATE
; Returns: eax = 1 if success, 0 if failed
SaveHighScore proc pGame:DWORD
    local hKey:DWORD
    local result:DWORD
    local scoreValue:DWORD
    local nameLen:DWORD
    push esi
    mov esi, pGame
    
    ; Create or open registry key
    invoke RegCreateKeyExW, HKEY_CURRENT_USER, offset szRegPath, 0, NULL,
        REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, addr hKey, NULL
    .IF eax != ERROR_SUCCESS
        pop esi
        xor eax, eax
        ret
    .ENDIF
    
    ; Write high score (REG_DWORD)
    mov eax, [esi].GAME_STATE.score
    mov scoreValue, eax
    invoke RegSetValueExW, hKey, offset szHighScore, 0, REG_DWORD,
        addr scoreValue, sizeof DWORD
    .IF eax != ERROR_SUCCESS
        invoke RegCloseKey, hKey
        pop esi
        xor eax, eax
        ret
    .ENDIF
    
    ; Determine scorer name (current player or "Anonymous")
    lea eax, [esi].GAME_STATE.playerName
    cmp word ptr [eax], 0
    jne @F
    ; No player name, use "Anonymous"
    lea eax, [esi].GAME_STATE.highScoreName
    mov word ptr [eax], 'A'
    mov word ptr [eax+2], 'n'
    mov word ptr [eax+4], 'o'
    mov word ptr [eax+6], 'n'
    mov word ptr [eax+8], 'y'
    mov word ptr [eax+10], 'm'
    mov word ptr [eax+12], 'o'
    mov word ptr [eax+14], 'u'
    mov word ptr [eax+16], 's'
    mov word ptr [eax+18], 0
    jmp @name_ready
@@:
    ; Copy player name to high score name
    push esi
    lea esi, [esi].GAME_STATE.playerName
    lea edi, [edi].GAME_STATE.highScoreName
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
    mov word ptr [edi + ecx*2], 0
    pop esi
@name_ready:
    
    ; Update game state high score
    mov eax, [esi].GAME_STATE.score
    mov [esi].GAME_STATE.highScore, eax
    
    ; Calculate name byte size
    lea eax, [esi].GAME_STATE.highScoreName
    invoke StrLenW, eax
    inc eax
    shl eax, 1
    mov nameLen, eax
    
    ; Write high score name (REG_SZ)
    lea eax, [esi].GAME_STATE.highScoreName
    invoke RegSetValueExW, hKey, offset szHighScoreName, 0, REG_SZ,
        eax, nameLen
    mov result, eax
    
    invoke RegCloseKey, hKey
    
    ; Return success/failure
    mov eax, result
    .IF eax == ERROR_SUCCESS
        mov eax, 1
    .ELSE
        xor eax, eax
    .ENDIF
    
    pop esi
    ret
SaveHighScore endp

; Load high score and scorer name from registry
; Args: pGame - pointer to GAME_STATE
; Returns: eax = 1 if loaded, 0 if not found
LoadHighScore proc pGame:DWORD
    local hKey:DWORD
    local score:DWORD
    local bufferSize:DWORD
    local regType:DWORD
    local buffer[256]:WORD
    push esi
    push edi
    mov esi, pGame
    
    ; Try to open registry key
    invoke RegOpenKeyExW, HKEY_CURRENT_USER, offset szRegPath, 0, KEY_READ, addr hKey
    .IF eax != ERROR_SUCCESS
        ; No saved data, set defaults
        mov [esi].GAME_STATE.highScore, 0
        mov word ptr [esi].GAME_STATE.highScoreName, 0
        pop edi
        pop esi
        xor eax, eax
        ret
    .ENDIF
    
    ; Read high score value
    mov bufferSize, sizeof DWORD
    invoke RegQueryValueExW, hKey, offset szHighScore, NULL, addr regType,
        addr score, addr bufferSize
    
    .IF eax == ERROR_SUCCESS
        mov eax, regType
        .IF eax == REG_DWORD
            mov eax, score
            mov [esi].GAME_STATE.highScore, eax
        .ELSE
            mov [esi].GAME_STATE.highScore, 0
        .ENDIF
    .ELSE
        mov [esi].GAME_STATE.highScore, 0
    .ENDIF
    
    ; Read high score name
    mov bufferSize, sizeof buffer
    invoke RegQueryValueExW, hKey, offset szHighScoreName, NULL, addr regType,
        addr buffer, addr bufferSize
    
    .IF eax == ERROR_SUCCESS
        mov eax, regType
        .IF eax == REG_SZ
            ; Copy buffer to game state (max 127 chars)
            lea edi, [esi].GAME_STATE.highScoreName
            lea esi, buffer
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
            mov word ptr [edi + ecx*2], 0
        .ELSE
            mov word ptr [esi].GAME_STATE.highScoreName, 0
        .ENDIF
    .ELSE
        mov word ptr [esi].GAME_STATE.highScoreName, 0
    .ENDIF
    
    invoke RegCloseKey, hKey
    
    pop edi
    pop esi
    mov eax, 1
    ret
LoadHighScore endp

; Delete entire registry key (clears all saved data)
; Returns: eax = 1 if success, 0 if failed
ClearRegistry proc
    invoke RegDeleteKeyW, HKEY_CURRENT_USER, offset szRegPath
    .IF eax == ERROR_SUCCESS
        mov eax, 1
        ret
    .ELSEIF eax == ERROR_FILE_NOT_FOUND
        ; Key doesn't exist, treat as success
        mov eax, 1
        ret
    .ENDIF
    xor eax, eax
    ret
ClearRegistry endp

end