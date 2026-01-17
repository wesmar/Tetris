.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include gdi32.inc
include kernel32.inc
includelib user32.lib
includelib gdi32.lib
includelib kernel32.lib

include data.inc
include proto.inc

.const
BLOCK_SIZE equ 25                       ; Pixel size of each tetromino block
BOARD_X equ 20                          ; Board top-left X position
BOARD_Y equ 20                          ; Board top-left Y position
INFO_X equ 300                          ; Info panel X position
INFO_Y equ 20                           ; Info panel Y position
GAME_AREA_HEIGHT equ 520

.data
szArial db "Arial", 0
szScore db "Score: %d", 0
szLines db "Lines: %d", 0
szLevel db "Level: %d", 0
szRecord db "Record: %d", 0
szNext db "Next:", 0
szAuthor db "Author:", 0
szName db "Marek Wesolowski", 0
szEmail db "marek@wesolowski.eu.org", 0
szWebsite db "https://kvc.pl", 0
szPaused db "PAUSED", 0
szGameOver db "GAME OVER!", 0
; Color palette (BGR format): empty, I, O, Z, S, T, L, J
colorTable dd 00000000h                 ; 0: Empty (black)
           dd 00FFFF00h                 ; 1: Cyan (I-piece)
           dd 0000FFFFh                 ; 2: Yellow (O-piece)
           dd 00FF00FFh                 ; 3: Magenta (Z-piece)
           dd 0000FF00h                 ; 4: Green (S-piece)
           dd 00FF8000h                 ; 5: Purple (T-piece)
           dd 00FF8000h                 ; 6: Orange (L-piece)
           dd 000080FFh                 ; 7: Red (J-piece)

.code

; Initialize renderer state and create GDI resources
; Args: pRenderer - renderer state, hwnd - window handle
InitRenderer proc pRenderer:DWORD, hwnd:DWORD
    push esi
    mov esi, pRenderer
    
    ; Store window handle and clear backbuffer state
    mov eax, hwnd
    mov [esi].RENDERER_STATE.hwnd, eax
    mov [esi].RENDERER_STATE.hdcMem, 0
    mov [esi].RENDERER_STATE.hbmMem, 0
    mov [esi].RENDERER_STATE.hbmOld, 0
    mov [esi].RENDERER_STATE.wWidth, 0
    mov [esi].RENDERER_STATE.wHeight, 0
    
    ; Create fonts for different UI elements
    invoke CreateFont, 20, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov [esi].RENDERER_STATE.hFontNormal, eax
    
    invoke CreateFont, 14, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov [esi].RENDERER_STATE.hFontSmall, eax
    
    invoke CreateFont, 26, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov [esi].RENDERER_STATE.hFontPause, eax
    
    invoke CreateFont, 30, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov [esi].RENDERER_STATE.hFontGameOver, eax
    
    ; Create brushes for all 8 colors
    xor ecx, ecx
@@:
    push ecx
    mov eax, ecx
    shl eax, 2
    lea edx, colorTable
    mov eax, [edx + eax]
    invoke CreateSolidBrush, eax
    pop ecx
    mov [esi + RENDERER_STATE.colorBrushes + ecx*4], eax
    inc ecx
    cmp ecx, 8
    jl @B
    
    pop esi
    ret
InitRenderer endp

; Free all GDI resources
CleanupRenderer proc pRenderer:DWORD
    push esi
    mov esi, pRenderer
    
    ; Delete fonts
    .IF [esi].RENDERER_STATE.hFontNormal
        invoke DeleteObject, [esi].RENDERER_STATE.hFontNormal
    .ENDIF
    .IF [esi].RENDERER_STATE.hFontSmall
        invoke DeleteObject, [esi].RENDERER_STATE.hFontSmall
    .ENDIF
    .IF [esi].RENDERER_STATE.hFontPause
        invoke DeleteObject, [esi].RENDERER_STATE.hFontPause
    .ENDIF
    .IF [esi].RENDERER_STATE.hFontGameOver
        invoke DeleteObject, [esi].RENDERER_STATE.hFontGameOver
    .ENDIF
    
    ; Delete color brushes
    xor ecx, ecx
@@:
    push ecx
    mov eax, [esi + RENDERER_STATE.colorBrushes + ecx*4]
    .IF eax
        invoke DeleteObject, eax
    .ENDIF
    pop ecx
    inc ecx
    cmp ecx, 8
    jl @B
    
    ; Delete backbuffer
    .IF [esi].RENDERER_STATE.hdcMem
        .IF [esi].RENDERER_STATE.hbmOld
            invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hbmOld
        .ENDIF
        .IF [esi].RENDERER_STATE.hbmMem
            invoke DeleteObject, [esi].RENDERER_STATE.hbmMem
        .ENDIF
        invoke DeleteDC, [esi].RENDERER_STATE.hdcMem
    .ENDIF
    
    pop esi
    ret
CleanupRenderer endp

; Create double-buffer bitmap for flicker-free rendering
CreateBackBuffer proc pRenderer:DWORD
    local hdc:DWORD
    push esi
    mov esi, pRenderer
    
    ; Delete old backbuffer if exists
    .IF [esi].RENDERER_STATE.hdcMem
        .IF [esi].RENDERER_STATE.hbmOld
            invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hbmOld
        .ENDIF
        .IF [esi].RENDERER_STATE.hbmMem
            invoke DeleteObject, [esi].RENDERER_STATE.hbmMem
        .ENDIF
        invoke DeleteDC, [esi].RENDERER_STATE.hdcMem
    .ENDIF
    
    ; Create new compatible DC and bitmap
    invoke GetDC, [esi].RENDERER_STATE.hwnd
    mov hdc, eax
    invoke CreateCompatibleDC, eax
    mov [esi].RENDERER_STATE.hdcMem, eax
	invoke CreateCompatibleBitmap, hdc, [esi].RENDERER_STATE.wWidth, [esi].RENDERER_STATE.wHeight
	mov [esi].RENDERER_STATE.hbmMem, eax
	invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hbmMem
	mov [esi].RENDERER_STATE.hbmOld, eax
    invoke ReleaseDC, [esi].RENDERER_STATE.hwnd, hdc
    
    pop esi
    ret
CreateBackBuffer endp

; Handle window resize - recreate backbuffer with new dimensions
ResizeRenderer proc pRenderer:DWORD, wWidth:DWORD, wHeight:DWORD
    push esi
    mov esi, pRenderer
    
    ; Store new dimensions
    mov eax, wWidth
    mov [esi].RENDERER_STATE.wWidth, eax
    mov eax, wHeight
    mov [esi].RENDERER_STATE.wHeight, eax
    
    ; Recreate backbuffer with new size
    invoke CreateBackBuffer, pRenderer
    
    pop esi
    ret
ResizeRenderer endp

; Main rendering function - draws entire game state
; Args: pRenderer, pGame - state pointers, hdc - target DC
RenderGame proc pRenderer:DWORD, pGame:DWORD, hdc:DWORD
    local rect:RECT
    local hbrBg:HBRUSH
    local hbrControl:HBRUSH
    push esi
    push edi
    mov esi, pRenderer
    mov edi, pGame
    
    ; Skip if backbuffer not initialized
    .IF ![esi].RENDERER_STATE.hdcMem
        pop edi
        pop esi
        ret
    .ENDIF
    
    ; Clear game area with dark background
    mov rect.left, 0
    mov rect.top, 0
    mov eax, [esi].RENDERER_STATE.wWidth
    mov rect.right, eax
    mov rect.bottom, GAME_AREA_HEIGHT
    invoke CreateSolidBrush, 00141414h  ; Dark gray
    mov hbrBg, eax
    invoke FillRect, [esi].RENDERER_STATE.hdcMem, addr rect, eax
    invoke DeleteObject, hbrBg
    
    ; Clear control area with light background
    mov rect.left, 0
    mov rect.top, GAME_AREA_HEIGHT
    mov eax, [esi].RENDERER_STATE.wWidth
    mov rect.right, eax
    mov eax, [esi].RENDERER_STATE.wHeight
    mov rect.bottom, eax
    invoke CreateSolidBrush, 00F0F0F0h  ; Light gray
    mov hbrControl, eax
    invoke FillRect, [esi].RENDERER_STATE.hdcMem, addr rect, eax
    invoke DeleteObject, hbrControl
    
    ; Draw all game elements
    invoke DrawBoard, pRenderer, pGame
    invoke DrawPiece, pRenderer, addr [edi].GAME_STATE.currentPiece
    invoke DrawInfo, pRenderer, pGame
    invoke DrawNextPiece, pRenderer, addr [edi].GAME_STATE.nextPiece
    
    ; BitBlt backbuffer to screen (flip)
    invoke BitBlt, hdc, 0, 0, [esi].RENDERER_STATE.wWidth, GAME_AREA_HEIGHT,
        [esi].RENDERER_STATE.hdcMem, 0, 0, SRCCOPY
    
    pop edi
    pop esi
    ret
RenderGame endp

; Draw game board grid and locked blocks
DrawBoard proc pRenderer:DWORD, pGame:DWORD
    local hpenGrid:HPEN
    local hpenOld:HPEN
    local rect:RECT
    local x:DWORD
    local y:DWORD
    local maxX:DWORD
    local maxY:DWORD
    push esi
    push edi
    push ebx
    mov esi, pRenderer
    mov edi, pGame
    
    ; Create dark gray grid pen
    invoke CreatePen, PS_SOLID, 1, 00323232h
    mov hpenGrid, eax
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, eax
    mov hpenOld, eax
    
    ; Calculate grid line counts
    mov eax, [edi].GAME_STATE.boardHeight
    inc eax
    mov maxY, eax
    mov eax, [edi].GAME_STATE.boardWidth
    inc eax
    mov maxX, eax
    
    ; Draw horizontal grid lines
    xor ecx, ecx
@@hline_loop:
    cmp ecx, maxY
    jge @@hline_done
    push ecx
    imul ecx, BLOCK_SIZE
    add ecx, BOARD_Y
    mov eax, [edi].GAME_STATE.boardWidth
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    push eax
    push ecx
    invoke MoveToEx, [esi].RENDERER_STATE.hdcMem, BOARD_X, ecx, NULL
    pop ecx
    pop eax
    invoke LineTo, [esi].RENDERER_STATE.hdcMem, eax, ecx
    pop ecx
    inc ecx
    jmp @@hline_loop
@@hline_done:
    
    ; Draw vertical grid lines
    xor ecx, ecx
@@vline_loop:
    cmp ecx, maxX
    jge @@vline_done
    push ecx
    imul ecx, BLOCK_SIZE
    add ecx, BOARD_X
    mov eax, [edi].GAME_STATE.boardHeight
    imul eax, BLOCK_SIZE
    add eax, BOARD_Y
    push eax
    push ecx
    invoke MoveToEx, [esi].RENDERER_STATE.hdcMem, ecx, BOARD_Y, NULL
    pop ecx
    pop eax
    invoke LineTo, [esi].RENDERER_STATE.hdcMem, ecx, eax
    pop ecx
    inc ecx
    jmp @@vline_loop
@@vline_done:
    
    ; Restore old pen and delete grid pen
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hpenOld
    invoke DeleteObject, hpenGrid
    
    ; Draw all locked blocks from board array
    mov y, 0
@@outer_loop:
    mov eax, y
    cmp eax, [edi].GAME_STATE.boardHeight
    jge @@outer_done
    
    mov x, 0
@@inner_loop:
    mov eax, x
    cmp eax, [edi].GAME_STATE.boardWidth
    jge @@inner_done
    
    ; Get block color from board[y * width + x]
    mov eax, y
    imul eax, [edi].GAME_STATE.boardWidth
    add eax, x
    lea ebx, [edi].GAME_STATE.board
    movzx ecx, byte ptr [ebx + eax]
    
    ; Skip empty cells
    test ecx, ecx
    jz @@skip_block
    
    ; Calculate block rectangle (with 1px gap)
    mov eax, x
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    inc eax
    mov rect.left, eax
    
    mov eax, y
    imul eax, BLOCK_SIZE
    add eax, BOARD_Y
    inc eax
    mov rect.top, eax
    
    mov eax, x
    inc eax
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    dec eax
    mov rect.right, eax
    
    mov eax, y
    inc eax
    imul eax, BLOCK_SIZE
    add eax, BOARD_Y
    dec eax
    mov rect.bottom, eax
    
    ; Fill with color brush
    and ecx, 7
    mov eax, [esi + RENDERER_STATE.colorBrushes + ecx*4]
    invoke FillRect, [esi].RENDERER_STATE.hdcMem, addr rect, eax
    
@@skip_block:
    inc x
    jmp @@inner_loop
    
@@inner_done:
    inc y
    jmp @@outer_loop
    
@@outer_done:
    
    pop ebx
    pop edi
    pop esi
    ret
DrawBoard endp

; Draw current falling piece
DrawPiece proc pRenderer:DWORD, pPiece:DWORD
    local rect:RECT
    local px:DWORD
    local py:DWORD
    push esi
    push edi
    push ebx
    mov esi, pRenderer
    mov edi, pPiece
    
    ; Get piece color brush
    movzx eax, [edi].PIECE.color
    and eax, 7
    mov ebx, [esi + RENDERER_STATE.colorBrushes + eax*4]
    
    ; Get piece world position
    mov eax, [edi].PIECE.x
    mov px, eax
    mov eax, [edi].PIECE.y
    mov py, eax
    
    ; Draw all 4 blocks
    xor ecx, ecx
@@loop_blocks:
    cmp ecx, 4
    jge @@loop_done
    
    push ecx
    mov eax, [edi + PIECE.blocks + ecx*8]
    add eax, px
    mov edx, [edi + PIECE.blocks + ecx*8 + 4]
    add edx, py
    
    ; Skip blocks above top of screen
    cmp edx, 0
    jl @@skip_draw
    
    ; Calculate block rectangle (with 1px gap)
    push eax
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    inc eax
    mov rect.left, eax
    
    imul edx, BLOCK_SIZE
    add edx, BOARD_Y
    inc edx
    mov rect.top, edx
    
    pop eax
    inc eax
    imul eax, BLOCK_SIZE
    add eax, BOARD_X
    dec eax
    mov rect.right, eax
    
    mov eax, rect.top
    add eax, BLOCK_SIZE - 2
    mov rect.bottom, eax
    
    ; Fill with color brush
    invoke FillRect, [esi].RENDERER_STATE.hdcMem, addr rect, ebx
    
@@skip_draw:
    pop ecx
    inc ecx
    jmp @@loop_blocks
    
@@loop_done:
    
    pop ebx
    pop edi
    pop esi
    ret
DrawPiece endp

; Draw "Next:" label and preview of next piece
DrawNextPiece proc pRenderer:DWORD, pPiece:DWORD
    local rect:RECT
    local hOldFont:HFONT
    push esi
    push edi
    push ebx
    mov esi, pRenderer
    mov edi, pPiece
    
    ; Set text rendering mode
    invoke SetBkMode, [esi].RENDERER_STATE.hdcMem, TRANSPARENT
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 00FFFFFFh
    
    ; Draw "Next:" label
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hFontNormal
    mov hOldFont, eax
    
    invoke lstrlen, offset szNext
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 150, offset szNext, eax
    
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hOldFont
    
    ; Get piece color brush
    movzx eax, [edi].PIECE.color
    and eax, 7
    mov ebx, [esi + RENDERER_STATE.colorBrushes + eax*4]
    
    ; Draw all 4 blocks in preview area
    xor ecx, ecx
@@loop_next:
    cmp ecx, 4
    jge @@loop_next_done
    
    push ecx
    ; Calculate preview position (offset from INFO panel)
    mov eax, [edi + PIECE.blocks + ecx*8]
    imul eax, BLOCK_SIZE
    add eax, INFO_X + 20
    inc eax
    mov rect.left, eax
    
    mov edx, [edi + PIECE.blocks + ecx*8 + 4]
    imul edx, BLOCK_SIZE
    add edx, INFO_Y + 180
    inc edx
    mov rect.top, edx
    
    add eax, BLOCK_SIZE - 2
    mov rect.right, eax
    
    add edx, BLOCK_SIZE - 2
    mov rect.bottom, edx
    
    invoke FillRect, [esi].RENDERER_STATE.hdcMem, addr rect, ebx
    
    pop ecx
    inc ecx
    jmp @@loop_next
    
@@loop_next_done:
    
    pop ebx
    pop edi
    pop esi
    ret
DrawNextPiece endp

; Draw score, lines, level, high score, and game state messages
DrawInfo proc pRenderer:DWORD, pGame:DWORD
    local buffer[64]:WORD
    local hOldFont:HFONT
    local rect:RECT
    local hpenSep:HPEN
    local hpenOld:HPEN
    local namePtr:DWORD
    local nameLen:DWORD
    push esi
    push edi
    mov esi, pRenderer
    mov edi, pGame
    
    ; Setup text rendering
    invoke SetBkMode, [esi].RENDERER_STATE.hdcMem, TRANSPARENT
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 00FFFFFFh
    
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hFontNormal
    mov hOldFont, eax
    
    ; Draw score
    invoke wsprintf, addr buffer, offset szScore, [edi].GAME_STATE.score
    invoke lstrlen, addr buffer
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y, addr buffer, eax
    
    ; Draw lines
    invoke wsprintf, addr buffer, offset szLines, [edi].GAME_STATE.lines
    invoke lstrlen, addr buffer
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 30, addr buffer, eax
    
    ; Draw level
    invoke wsprintf, addr buffer, offset szLevel, [edi].GAME_STATE.level
    invoke lstrlen, addr buffer
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 60, addr buffer, eax
    
    ; Draw high score in gold color
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 0000D7FFh
    invoke wsprintf, addr buffer, offset szRecord, [edi].GAME_STATE.highScore
    invoke lstrlen, addr buffer
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 100, addr buffer, eax
    
    ; Draw high scorer name (Unicode)
    lea ebx, [edi].GAME_STATE.highScoreName
    cmp word ptr [ebx], 0
    je @skip_name
    push ebx
    call lstrlenW
    push eax
    push ebx
    push INFO_Y + 125
    push INFO_X
    mov ecx, [esi].RENDERER_STATE.hdcMem
    push ecx
    call TextOutW
@skip_name:
    
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 00FFFFFFh
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hOldFont
    
    ; Draw thin horizontal separator line
    invoke CreatePen, PS_SOLID, 1, 00323232h
    mov hpenSep, eax
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, eax
    mov hpenOld, eax
    invoke MoveToEx, [esi].RENDERER_STATE.hdcMem, INFO_X - 5, INFO_Y + 305, NULL
    invoke LineTo, [esi].RENDERER_STATE.hdcMem, INFO_X + 165, INFO_Y + 305
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hpenOld
    invoke DeleteObject, hpenSep
    
    ; Draw author info
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hFontSmall
    mov hOldFont, eax
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 00A0A0A0h
    
    invoke lstrlen, offset szAuthor
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 315, offset szAuthor, eax
    invoke lstrlen, offset szName
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 335, offset szName, eax
    invoke lstrlen, offset szEmail
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 355, offset szEmail, eax
    invoke lstrlen, offset szWebsite
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 375, offset szWebsite, eax
    
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hOldFont
    
    ; Draw "PAUSED" overlay if paused (not game over)
    mov al, [edi].GAME_STATE.paused
    test al, al
    jz @F
    mov al, [edi].GAME_STATE.gameOver
    test al, al
    jnz @F
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 0000FFFFh
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hFontPause
    mov hOldFont, eax
    invoke lstrlen, offset szPaused
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X, INFO_Y + 250, offset szPaused, eax
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hOldFont
@@:
    
    ; Draw "GAME OVER!" overlay if game over
    mov al, [edi].GAME_STATE.gameOver
    test al, al
    jz @F
    invoke SetTextColor, [esi].RENDERER_STATE.hdcMem, 000000FFh
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, [esi].RENDERER_STATE.hFontGameOver
    mov hOldFont, eax
    invoke lstrlen, offset szGameOver
    invoke TextOut, [esi].RENDERER_STATE.hdcMem, INFO_X - 20, INFO_Y + 240, offset szGameOver, eax
    invoke SelectObject, [esi].RENDERER_STATE.hdcMem, hOldFont
@@:
    
    pop edi
    pop esi
    ret
DrawInfo endp

end
