.386
.model flat, stdcall
option casemap:none

include windows.inc
include user32.inc
include gdi32.inc
include kernel32.inc
include shell32.inc
includelib user32.lib
includelib gdi32.lib
includelib kernel32.lib
includelib shell32.lib

include data.inc
include proto.inc

.const
WINDOW_WIDTH equ 480
WINDOW_HEIGHT equ 570
GAME_AREA_HEIGHT equ 520
TIMER_ID equ 1

; Control IDs
IDC_EDIT_NAME equ 1001
IDC_BUTTON_CLEAR equ 1002
IDC_BUTTON_START equ 1003
IDC_BUTTON_GHOST equ 1004

; Menu/Accelerator IDs
IDM_PAUSE equ 2001
IDM_RESUME equ 2002
IDM_CLEAR equ 2003

TARGET_FPS equ 60
FRAME_TIME_MS equ 16                    ; ~60 FPS (1000ms / 60)

.data
szClassName db "TetrisWindowClass", 0
szWindowTitle db "Tetris - Win32", 0
szShell32 db "shell32.dll", 0
szPlayerLabel db "Player:", 0
szPauseGame db "&Pause Game", 0
szResumeGame db "&Resume Game", 0
szClearRecord db "&Clear Record", 0
szGhostOn db "Ghost: ON", 0
szGhostOff db "Ghost: OFF", 0
szRecordCleared db "Record cleared successfully!", 0
szTetris db "Tetris", 0
szArial db "Arial", 0
szStaticClass db "STATIC", 0
szEditClass db "EDIT", 0
szButtonClass db "BUTTON", 0

; Global handles and state
g_hInstance dd 0
g_hEditName dd 0
g_hButtonClear dd 0
g_hButtonStart dd 0
g_hButtonGhost dd 0
g_lastTickCount dd 0

.data?
g_game GAME_STATE <>
g_renderer RENDERER_STATE <>

.code

start:
    ; Get application instance handle
    invoke GetModuleHandle, NULL
    mov g_hInstance, eax
    
    ; Start main window procedure
    invoke WinMain, eax, NULL, NULL, SW_SHOWDEFAULT
    invoke ExitProcess, eax

; Main entry point - creates window and runs message loop
WinMain proc hInst:DWORD, hPrevInst:DWORD, lpCmdLine:DWORD, nCmdShow:DWORD
    local wc:WNDCLASSEX
    local msg:MSG
    local hwnd:HWND
    local rect:RECT
    local accel[3]:ACCEL
    local hAccel:HACCEL
    local hLabelName:HWND
    local hLabelFont:HFONT
    local hEditFont:HFONT
    local hShell:DWORD
    
    ; Register window class with all properties
    mov wc.cbSize, sizeof WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov wc.lpfnWndProc, offset WindowProc
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    push hInst
    pop wc.hInstance
    
    ; Set standard arrow cursor
    invoke LoadCursor, NULL, IDC_ARROW
    mov wc.hCursor, eax
    
    ; Set window background color
    mov wc.hbrBackground, COLOR_BTNFACE + 1
    mov wc.lpszMenuName, NULL
    mov wc.lpszClassName, offset szClassName
    
    ; Load gamepad icon from shell32.dll (icon index 19)
    invoke LoadLibrary, offset szShell32
    mov hShell, eax
    invoke ExtractIcon, g_hInstance, offset szShell32, 19
    mov wc.hIcon, eax
    mov wc.hIconSm, eax
    invoke FreeLibrary, hShell
    
    ; Register the window class
    invoke RegisterClassEx, addr wc
    
    ; Create keyboard accelerators for Alt+P, Alt+R, Alt+C
    mov accel[0 * (sizeof ACCEL)].fVirt, FALT or FVIRTKEY
    mov accel[0 * (sizeof ACCEL)].key, 'P'
    mov accel[0 * (sizeof ACCEL)].cmd, IDM_PAUSE
    mov accel[1 * (sizeof ACCEL)].fVirt, FALT or FVIRTKEY
    mov accel[1 * (sizeof ACCEL)].key, 'R'
    mov accel[1 * (sizeof ACCEL)].cmd, IDM_RESUME
    mov accel[2 * (sizeof ACCEL)].fVirt, FALT or FVIRTKEY
    mov accel[2 * (sizeof ACCEL)].key, 'C'
    mov accel[2 * (sizeof ACCEL)].cmd, IDM_CLEAR
    invoke CreateAcceleratorTable, addr accel, 3
    mov hAccel, eax
    
    ; Calculate window size including borders and title bar
    mov rect.left, 0
    mov rect.top, 0
    mov rect.right, WINDOW_WIDTH
    mov rect.bottom, WINDOW_HEIGHT
    invoke AdjustWindowRect, addr rect, WS_OVERLAPPEDWINDOW and not WS_THICKFRAME and not WS_MAXIMIZEBOX, FALSE
    
    mov eax, rect.right
    sub eax, rect.left
    mov ecx, rect.bottom
    sub ecx, rect.top
    
    ; Create main window (non-resizable, no maximize button)
    invoke CreateWindowEx, 0, addr szClassName, addr szWindowTitle,
        WS_OVERLAPPEDWINDOW and not WS_THICKFRAME and not WS_MAXIMIZEBOX or WS_CLIPCHILDREN,
        CW_USEDEFAULT, CW_USEDEFAULT, eax, ecx,
        NULL, NULL, hInst, NULL
    mov hwnd, eax
    
    ; Initialize game state with 10x20 board
    invoke InitGame, addr g_game, 10, 20
    
    ; Initialize renderer with window handle
    invoke InitRenderer, addr g_renderer, hwnd
    
    ; Get client area size and setup renderer
    invoke GetClientRect, hwnd, addr rect
    mov eax, rect.right
    mov ecx, rect.bottom
    invoke ResizeRenderer, addr g_renderer, eax, ecx
    
    ; Create "Player:" label
    invoke CreateWindowEx, 0, addr szStaticClass, offset szPlayerLabel,
        WS_CHILD or WS_VISIBLE or SS_LEFT,
        10, 533, 100, 18,
        hwnd, NULL, hInst, NULL
    mov hLabelName, eax
    
    ; Create bold font for label
    invoke CreateFont, 16, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov hLabelFont, eax
    invoke SendMessage, hLabelName, WM_SETFONT, eax, TRUE
    
    ; Create player name text input box
    invoke CreateWindowEx, WS_EX_CLIENTEDGE, addr szEditClass, NULL,
        WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL or WS_BORDER,
        70, 530, 90, 24,
        hwnd, IDC_EDIT_NAME, hInst, NULL
    mov g_hEditName, eax

    ; Create normal font for text input
    invoke CreateFont, 15, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    mov hEditFont, eax
    invoke SendMessage, g_hEditName, WM_SETFONT, eax, TRUE

    ; Create smaller font for buttons
    invoke CreateFont, 13, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        DEFAULT_QUALITY, DEFAULT_PITCH or FF_DONTCARE, offset szArial
    push eax

    ; Create Pause/Resume button
    invoke CreateWindowEx, 0, addr szButtonClass, offset szPauseGame,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        170, 527, 105, 30,
        hwnd, IDC_BUTTON_START, hInst, NULL
    mov g_hButtonStart, eax
    invoke SendMessage, g_hButtonStart, WM_SETFONT, dword ptr [esp], TRUE

    ; Create Clear Record button
    invoke CreateWindowEx, 0, addr szButtonClass, offset szClearRecord,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        280, 527, 95, 30,
        hwnd, IDC_BUTTON_CLEAR, hInst, NULL
    mov g_hButtonClear, eax
    invoke SendMessage, g_hButtonClear, WM_SETFONT, dword ptr [esp], TRUE

    ; Create Ghost toggle button
    invoke CreateWindowEx, 0, addr szButtonClass, offset szGhostOn,
        WS_CHILD or WS_VISIBLE or BS_PUSHBUTTON,
        380, 527, 90, 30,
        hwnd, IDC_BUTTON_GHOST, hInst, NULL
    mov g_hButtonGhost, eax
    invoke SendMessage, g_hButtonGhost, WM_SETFONT, dword ptr [esp], TRUE

    pop eax
    
    ; Load saved player name from registry and display it
    invoke LoadPlayerName, addr g_game
    invoke SetWindowTextW, g_hEditName, addr g_game.playerName
    
    ; Show window on screen
    invoke ShowWindow, hwnd, nCmdShow
    invoke UpdateWindow, hwnd
    
    ; Initialize frame timer for game loop
    invoke GetTickCount
    mov g_lastTickCount, eax
    
    ; Main message loop with custom frame timing
.WHILE TRUE
    ; Check for Windows messages
    invoke PeekMessage, addr msg, NULL, 0, 0, PM_REMOVE
    .IF eax
        ; Exit if quit message received
        .IF msg.message == WM_QUIT
            .BREAK
        .ENDIF
        
        ; Process keyboard accelerators
        invoke TranslateAccelerator, hwnd, hAccel, addr msg
        .IF eax == 0
            ; Translate and dispatch regular messages
            invoke TranslateMessage, addr msg
            invoke DispatchMessage, addr msg
        .ENDIF
    .ELSE
        ; Check if enough time has passed for next frame (60 FPS target)
        invoke GetTickCount
        mov ecx, g_lastTickCount
        sub eax, ecx
        .IF eax >= FRAME_TIME_MS
            ; Update frame timer
            invoke GetTickCount
            mov g_lastTickCount, eax
            
            ; Update game physics and logic
            invoke UpdateGame, addr g_game, FRAME_TIME_MS
            
            ; Redraw only game area (not UI controls)
            mov rect.left, 0
            mov rect.top, 0
            mov rect.right, 480
            mov rect.bottom, GAME_AREA_HEIGHT
            invoke InvalidateRect, hwnd, addr rect, FALSE
        .ELSE
            ; Yield CPU to prevent busy-waiting
            invoke Sleep, 1
        .ENDIF
    .ENDIF
.ENDW
    
    ; Cleanup resources before exit
    invoke DestroyAcceleratorTable, hAccel
    invoke CleanupRenderer, addr g_renderer
    
    ; Return exit code
    mov eax, msg.wParam
    ret
WinMain endp

; Window message handler - processes all window events
WindowProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    local ps:PAINTSTRUCT
    local hdc:HDC
    local rect:RECT
    local buffer[256]:WORD
    local playerName[128]:WORD
    
    .IF uMsg == WM_DESTROY
        ; User closed window - exit application
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
        
    .ELSEIF uMsg == WM_PAINT
        ; Redraw window contents
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        
        ; Render game board, pieces, and UI
        invoke RenderGame, addr g_renderer, addr g_game, hdc
        
        ; Fill control area with light gray background
        mov rect.left, 0
        mov rect.top, GAME_AREA_HEIGHT
        mov rect.right, 480
        mov rect.bottom, WINDOW_HEIGHT
        invoke CreateSolidBrush, 00F0F0F0h
        push eax
        invoke FillRect, hdc, addr rect, eax
        call DeleteObject
        
        invoke EndPaint, hWnd, addr ps
        xor eax, eax
        ret
        
    .ELSEIF uMsg == WM_SIZE
        ; Window was resized - recreate backbuffer
        movzx eax, word ptr [lParam]
        movzx ecx, word ptr [lParam+2]
        invoke ResizeRenderer, addr g_renderer, eax, ecx
        xor eax, eax
        ret
        
    .ELSEIF uMsg == WM_COMMAND
        ; Handle control notifications and menu commands
        mov eax, wParam
        and eax, 0FFFFh
        
        .IF eax == IDC_EDIT_NAME
            ; Player name text box changed
            mov eax, wParam
            shr eax, 16
            .IF eax == EN_CHANGE
                ; Save new player name to game state and registry
                invoke GetWindowTextW, g_hEditName, addr buffer, 256
                invoke SetPlayerName, addr g_game, addr buffer
                invoke SavePlayerName, addr buffer
            .ENDIF
            
        .ELSEIF eax == IDM_PAUSE
            ; Alt+P pressed - pause game
            mov al, g_game.gameOver
            or al, g_game.paused
            .IF !al
                invoke PauseGame, addr g_game
                invoke SetWindowText, g_hButtonStart, offset szResumeGame
                invoke SetFocus, hWnd
                
                ; Redraw game area to show PAUSED overlay
                mov rect.left, 0
                mov rect.top, 0
                mov rect.right, 480
                mov rect.bottom, GAME_AREA_HEIGHT
                invoke InvalidateRect, hWnd, addr rect, FALSE
            .ENDIF
            
        .ELSEIF eax == IDM_RESUME
            ; Alt+R pressed - resume game
            mov al, g_game.gameOver
            .IF !al
                cmp g_game.paused, 0
                je @F
                invoke ResumeGame, addr g_game
                invoke SetWindowText, g_hButtonStart, offset szPauseGame
                invoke SetFocus, hWnd
                
                ; Redraw to remove PAUSED overlay
                mov rect.left, 0
                mov rect.top, 0
                mov rect.right, 480
                mov rect.bottom, GAME_AREA_HEIGHT
                invoke InvalidateRect, hWnd, addr rect, FALSE
            @@:
            .ENDIF
            
        .ELSEIF eax == IDM_CLEAR
            ; Alt+C pressed - clear high score
            invoke ClearRegistry
            .IF eax
                ; Reload default high score (0)
                invoke LoadHighScore, addr g_game
                
                ; Redraw to update score display
                mov rect.left, 0
                mov rect.top, 0
                mov rect.right, 480
                mov rect.bottom, GAME_AREA_HEIGHT
                invoke InvalidateRect, hWnd, addr rect, FALSE
                
                ; Show confirmation message
                invoke MessageBox, hWnd, offset szRecordCleared, offset szTetris, MB_OK or MB_ICONINFORMATION
            .ENDIF
            invoke SetFocus, hWnd
            
        .ELSEIF eax == IDC_BUTTON_START
            ; Pause/Resume button clicked
            mov eax, wParam
            shr eax, 16
            .IF eax == BN_CLICKED
                .IF g_game.gameOver
                    ; Game over - start new game
                    invoke StartGame, addr g_game
                    invoke SetWindowText, g_hButtonStart, offset szPauseGame
                .ELSEIF g_game.paused
                    ; Currently paused - resume
                    invoke ResumeGame, addr g_game
                    invoke SetWindowText, g_hButtonStart, offset szPauseGame
                .ELSE
                    ; Currently playing - pause
                    invoke PauseGame, addr g_game
                    invoke SetWindowText, g_hButtonStart, offset szResumeGame
                .ENDIF
                
                invoke SetFocus, hWnd
                
                ; Redraw game area
                mov rect.left, 0
                mov rect.top, 0
                mov rect.right, 480
                mov rect.bottom, GAME_AREA_HEIGHT
                invoke InvalidateRect, hWnd, addr rect, FALSE
            .ENDIF
            
        .ELSEIF eax == IDC_BUTTON_CLEAR
            ; Clear Record button clicked
            mov eax, wParam
            shr eax, 16
            .IF eax == BN_CLICKED
                invoke ClearRegistry
                .IF eax
                    ; Reload and redraw
                    invoke LoadHighScore, addr g_game
                    mov rect.left, 0
                    mov rect.top, 0
                    mov rect.right, 480
                    mov rect.bottom, GAME_AREA_HEIGHT
                    invoke InvalidateRect, hWnd, addr rect, FALSE
                    invoke MessageBox, hWnd, offset szRecordCleared, offset szTetris, MB_OK or MB_ICONINFORMATION
                .ENDIF
                invoke SetFocus, hWnd
            .ENDIF

        .ELSEIF eax == IDC_BUTTON_GHOST
            ; Ghost toggle button clicked
            mov eax, wParam
            shr eax, 16
            .IF eax == BN_CLICKED
                ; Toggle ghost piece visibility
                xor g_game.showGhost, 1
                .IF g_game.showGhost
                    invoke SetWindowText, g_hButtonGhost, offset szGhostOn
                .ELSE
                    invoke SetWindowText, g_hButtonGhost, offset szGhostOff
                .ENDIF

                invoke SetFocus, hWnd

                ; Redraw game area
                mov rect.left, 0
                mov rect.top, 0
                mov rect.right, 480
                mov rect.bottom, GAME_AREA_HEIGHT
                invoke InvalidateRect, hWnd, addr rect, FALSE
            .ENDIF
        .ENDIF
        xor eax, eax
        ret
        
    .ELSEIF uMsg == WM_KEYDOWN
        ; Handle keyboard input for game controls
        mov rect.left, 0
        mov rect.top, 0
        mov rect.right, 480
        mov rect.bottom, GAME_AREA_HEIGHT
        
        .IF wParam == VK_LEFT
            ; Left arrow - move piece left
            invoke MoveLeft, addr g_game
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_RIGHT
            ; Right arrow - move piece right
            invoke MoveRight, addr g_game
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_DOWN
            ; Down arrow - move piece down faster
            invoke MoveDown, addr g_game, 1
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_UP
            ; Up arrow - rotate piece clockwise
            invoke RotatePiece, addr g_game
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_SPACE
            ; Space - hard drop (instant drop to bottom)
            invoke DropPiece, addr g_game
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == 'P'
            ; P key - pause/resume or restart if game over
            .IF g_game.gameOver
                invoke StartGame, addr g_game
                invoke SetWindowText, g_hButtonStart, offset szPauseGame
            .ELSE
                invoke TogglePause, addr g_game
                .IF g_game.paused
                    invoke SetWindowText, g_hButtonStart, offset szResumeGame
                .ELSE
                    invoke SetWindowText, g_hButtonStart, offset szPauseGame
                .ENDIF
            .ENDIF
            invoke SetFocus, hWnd
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_F2
            ; F2 - start new game
            invoke StartGame, addr g_game
            invoke SetWindowText, g_hButtonStart, offset szPauseGame
            invoke SetFocus, hWnd
            invoke InvalidateRect, hWnd, addr rect, FALSE
            
        .ELSEIF wParam == VK_ESCAPE
            ; ESC - quit application
            invoke PostQuitMessage, 0
        .ENDIF
        xor eax, eax
        ret
    .ENDIF
    
    ; Let Windows handle all other messages
    invoke DefWindowProc, hWnd, uMsg, wParam, lParam
    ret
WindowProc endp

end start
