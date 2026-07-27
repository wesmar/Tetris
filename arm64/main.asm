    INCLUDE data.inc
    INCLUDE proto.inc

; ---------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------
WINDOW_WIDTH        EQU 480
WINDOW_HEIGHT       EQU 570
CW_USEDEFAULT       EQU 0x80000000

WS_OVERLAPPEDWINDOW EQU 0x00CF0000
WS_VISIBLE          EQU 0x10000000
WS_CHILD            EQU 0x40000000
WS_BORDER           EQU 0x00800000
WS_CLIPCHILDREN     EQU 0x02000000
WS_EX_CLIENTEDGE    EQU 0x00000200

SS_LEFT             EQU 0
ES_AUTOHSCROLL      EQU 0x0080
BS_PUSHBUTTON       EQU 0

STYLE_STATIC        EQU 0x50000000
STYLE_EDIT          EQU 0x50800080
STYLE_BUTTON        EQU 0x50000000
STYLE_MAIN_ADJUST   EQU 0x00CA0000
STYLE_MAIN_CREATE   EQU 0x02CA0000

CS_VREDRAW          EQU 0x0001
CS_HREDRAW          EQU 0x0002
COLOR_BTNFACE       EQU 15
IDC_ARROW           EQU 32512
SW_SHOWDEFAULT      EQU 10

WM_CREATE           EQU 0x0001
WM_DESTROY          EQU 0x0002
WM_PAINT            EQU 0x000F
WM_KEYDOWN          EQU 0x0100
WM_COMMAND          EQU 0x0111
WM_TIMER            EQU 0x0113
WM_SETFONT          EQU 0x0030
WM_CTLCOLOREDIT     EQU 0x0133

VK_ESCAPE           EQU 0x1B
VK_SPACE            EQU 0x20
VK_LEFT             EQU 0x25
VK_UP               EQU 0x26
VK_RIGHT            EQU 0x27
VK_DOWN             EQU 0x28
VK_P                EQU 0x50
VK_F2               EQU 0x71

GAME_TIMER_ID       EQU 1
GAME_TICK_MS        EQU 16
EDIT_TIMER_ID       EQU 2
EDIT_SAVE_DELAY_MS  EQU 1000

IDC_EDIT_NAME       EQU 1001
IDC_BUTTON_CLEAR    EQU 1002
IDC_BUTTON_START    EQU 1003
IDC_BUTTON_GHOST    EQU 1004
EN_CHANGE           EQU 0x0300

DWMWA_USE_IMMERSIVE_DARK_MODE EQU 20
DWMWA_SYSTEMBACKDROP_TYPE      EQU 38
DWMSBT_MAINWINDOW              EQU 2

; ---------------------------------------------------------------------------
; WindowProc stack layout
; ---------------------------------------------------------------------------
WP_FRAME_SIZE EQU 0x460
WP_FP_LR      EQU 0x450
WP_SAVE1      EQU 0x440
WP_SAVE2      EQU 0x430
WP_SAVE3      EQU 0x420
WP_RECT       EQU 0x100
WP_TEXT1      EQU 0x120
WP_TEXT2      EQU 0x220

; ---------------------------------------------------------------------------
; WinMain stack layout
; ---------------------------------------------------------------------------
WM_FRAME EQU 0x140
WM_FP_LR EQU 0x130
WM_SAVE1 EQU 0x120
WM_SAVE2 EQU 0x110
WM_SAVE3 EQU 0x100
WM_RECT  EQU 0x60
WM_DWM   EQU 0x70
WM_SHELL EQU 0x78
WM_WC    EQU 0x80

RECT_LEFT   EQU WM_RECT + 0
RECT_TOP    EQU WM_RECT + 4
RECT_RIGHT  EQU WM_RECT + 8
RECT_BOTTOM EQU WM_RECT + 12

WC_cbSize    EQU WM_WC + 0
WC_style     EQU WM_WC + 4
WC_lpfn      EQU WM_WC + 8
WC_clsExtra  EQU WM_WC + 16
WC_wndExtra  EQU WM_WC + 20
WC_hInstance EQU WM_WC + 24
WC_hIcon     EQU WM_WC + 32
WC_hCursor   EQU WM_WC + 40
WC_hbr       EQU WM_WC + 48
WC_menu      EQU WM_WC + 56
WC_class     EQU WM_WC + 64
WC_iconSm    EQU WM_WC + 72

MSG_wParam   EQU WM_WC + 16

    EXPORT start

; ---------------------------------------------------------------------------
; Initialized data
; ---------------------------------------------------------------------------
    AREA |.data|, DATA, READWRITE, ALIGN=4

szClassName     DCB "TetrisWindowClass", 0
szWindowTitle   DCB "Tetris ARM64", 0
szSegoeUI       DCB "Segoe UI", 0
szShell32       DCB "shell32.dll", 0
szStaticClass   DCB "STATIC", 0
szEditClass     DCB "EDIT", 0
szButtonClass   DCB "BUTTON", 0
szPlayerLabel   DCB "Player:", 0
szPauseGame     DCB "&Pause Game", 0
szResumeGame    DCB "&Resume Game", 0
szClearRecord   DCB "&Clear Record", 0
szGhostOn       DCB "Ghost: ON", 0
szGhostOff      DCB "Ghost: OFF", 0

    ALIGN 8
g_hInstance     DCQ 0
g_hWnd          DCQ 0
g_hButtonStart  DCQ 0
g_hButtonClear  DCQ 0
g_hButtonGhost  DCQ 0
g_hEditName     DCQ 0
g_hBrushGreen   DCQ 0
g_hFontButtons  DCQ 0

    ALIGN 16
g_game          SPACE GAME_STATE_SIZE

    ALIGN 16
g_renderer      SPACE RENDERER_STATE_SIZE

    ALIGN 16
ps              SPACE 80

; ---------------------------------------------------------------------------
; Code
; ---------------------------------------------------------------------------
    AREA |.text|, CODE, READONLY, ALIGN=4
    ALIGN 16

; ---------------------------------------------------------------------------
; WindowProc
; X0 = hwnd, X1 = uMsg, X2 = wParam, X3 = lParam
; ---------------------------------------------------------------------------
WindowProc PROC
    SUB SP, SP, #WP_FRAME_SIZE

    ADD X8, SP, #WP_FP_LR
    STP X29, X30, [X8]
    ADD X29, SP, #WP_FP_LR

    ADD X8, SP, #WP_SAVE1
    STP X19, X20, [X8]
    ADD X8, SP, #WP_SAVE2
    STP X21, X22, [X8]
    ADD X8, SP, #WP_SAVE3
    STP X23, X24, [X8]

    MOV X19, X0                  ; hwnd
    MOV X20, X1                  ; uMsg
    MOV X21, X2                  ; wParam
    MOV X22, X3                  ; lParam

    CMP W20, #WM_CREATE
    B.EQ wp_create
    CMP W20, #WM_DESTROY
    B.EQ wp_destroy
    CMP W20, #WM_PAINT
    B.EQ wp_paint
    CMP W20, #WM_COMMAND
    B.EQ wp_command
    CMP W20, #WM_TIMER
    B.EQ wp_timer
    CMP W20, #WM_KEYDOWN
    B.EQ wp_keydown
    CMP W20, #WM_CTLCOLOREDIT
    B.EQ wp_ctlcoloredit

wp_default
    MOV X0, X19
    MOV X1, X20
    MOV X2, X21
    MOV X3, X22
    BL DefWindowProcA
    B wp_exit

; ---------------------------------------------------------------------------
; WM_CREATE
; ---------------------------------------------------------------------------
wp_create
    LDR X0, =g_game
    MOV W1, #10
    MOV W2, #20
    BL InitGame

    LDR X0, =g_renderer
    MOV X1, X19
    BL InitRenderer

    MOV X0, X19
    ADD X1, SP, #WP_RECT
    BL GetClientRect

    LDR W1, [SP, #WP_RECT + 8]   ; rect.right
    LDR W2, [SP, #WP_RECT + 12]  ; rect.bottom
    LDR X0, =g_renderer
    BL ResizeRenderer

    LDR X0, =g_game
    BL StartGame

    ; Green brush for edit control
    MOVZ W0, #0xFFE0
    MOVK W0, #0x00E0, LSL #16    ; 0x00E0FFE0
    BL CreateSolidBrush
    LDR X8, =g_hBrushGreen
    STR X0, [X8]

    ; Static label "Player:"
    MOV X0, #0                   ; dwExStyle
    LDR X1, =szStaticClass       ; lpClassName
    LDR X2, =szPlayerLabel       ; lpWindowName
    MOVZ W3, #0x5000, LSL #16    ; dwStyle (WS_CHILD | WS_VISIBLE)
    MOV X4, #10                  ; X
    MOV X5, #533                 ; Y
    MOV X6, #100                 ; nWidth
    MOV X7, #18                  ; nHeight
    STR X19, [SP, #0]            ; hWndParent
    STR XZR, [SP, #8]            ; hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]            ; hInstance
    STR XZR, [SP, #24]           ; lpParam
    BL CreateWindowExA

    ; Edit control
    MOV X0, #WS_EX_CLIENTEDGE    ; dwExStyle
    LDR X1, =szEditClass         ; lpClassName
    MOV X2, #0                   ; lpWindowName
    MOVZ W3, #0x0080
    MOVK W3, #0x5080, LSL #16    ; dwStyle
    MOV X4, #70                  ; X
    MOV X5, #530                 ; Y
    MOV X6, #90                  ; nWidth
    MOV X7, #24                  ; nHeight
    STR X19, [SP, #0]            ; hWndParent
    MOV X8, #IDC_EDIT_NAME
    STR X8, [SP, #8]             ; hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]            ; hInstance
    STR XZR, [SP, #24]           ; lpParam
    BL CreateWindowExA

    LDR X8, =g_hEditName
    STR X0, [X8]

    ; Set saved player name
    LDR X0, =g_hEditName
    LDR X0, [X0]
    LDR X1, =g_game
    ADD X1, X1, #GAME_STATE_playerName
    BL SetWindowTextW

    LDR X0, =g_hEditName
    LDR X0, [X0]
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect

    ; Pause/Resume button
    MOV X0, #0
    LDR X1, =szButtonClass
    LDR X2, =szPauseGame
    MOVZ W3, #0x5000, LSL #16
    MOV X4, #170                 ; X
    MOV X5, #527                 ; Y
    MOV X6, #105                 ; nWidth
    MOV X7, #30                  ; nHeight
    STR X19, [SP, #0]            ; hWndParent
    MOV X8, #IDC_BUTTON_START
    STR X8, [SP, #8]             ; hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]            ; hInstance
    STR XZR, [SP, #24]           ; lpParam
    BL CreateWindowExA

    LDR X8, =g_hButtonStart
    STR X0, [X8]

    ; Clear Record button
    MOV X0, #0
    LDR X1, =szButtonClass
    LDR X2, =szClearRecord
    MOVZ W3, #0x5000, LSL #16
    MOV X4, #280                 ; X
    MOV X5, #527                 ; Y
    MOV X6, #95                  ; nWidth
    MOV X7, #30                  ; nHeight
    STR X19, [SP, #0]            ; hWndParent
    MOV X8, #IDC_BUTTON_CLEAR
    STR X8, [SP, #8]             ; hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]            ; hInstance
    STR XZR, [SP, #24]           ; lpParam
    BL CreateWindowExA

    LDR X8, =g_hButtonClear
    STR X0, [X8]

    ; Ghost toggle button
    MOV X0, #0
    LDR X1, =szButtonClass
    LDR X2, =szGhostOff
    MOVZ W3, #0x5000, LSL #16
    MOV X4, #380                 ; X
    MOV X5, #527                 ; Y
    MOV X6, #90                  ; nWidth
    MOV X7, #30                  ; nHeight
    STR X19, [SP, #0]            ; hWndParent
    MOV X8, #IDC_BUTTON_GHOST
    STR X8, [SP, #8]             ; hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]            ; hInstance
    STR XZR, [SP, #24]           ; lpParam
    BL CreateWindowExA

    LDR X8, =g_hButtonGhost
    STR X0, [X8]

    ; Button font: CreateFontA(-14, 0,0,0, 400, 0,0,0,0,0,0,0,0, "Segoe UI")
    MOVN W0, #13                 ; arg 1: -14
    MOV X1, #0                   ; arg 2: 0
    MOV X2, #0                   ; arg 3: 0
    MOV X3, #0                   ; arg 4: 0
    MOV X4, #400                 ; arg 5: cWeight
    MOV X5, #0                   ; arg 6: bItalic
    MOV X6, #0                   ; arg 7: bUnderline
    MOV X7, #0                   ; arg 8: bStrikeOut
    STR XZR, [SP, #0]            ; arg 9: iCharSet
    STR XZR, [SP, #8]            ; arg 10: iOutPrecision
    STR XZR, [SP, #16]           ; arg 11: iClipPrecision
    STR XZR, [SP, #24]           ; arg 12: iQuality
    STR XZR, [SP, #32]           ; arg 13: iPitchAndFamily
    LDR X8, =szSegoeUI
    STR X8, [SP, #40]            ; arg 14: pszFaceName
    BL CreateFontA

    LDR X8, =g_hFontButtons
    STR X0, [X8]

    LDR X0, =g_hButtonStart
    LDR X0, [X0]
    MOV X1, #WM_SETFONT
    LDR X2, =g_hFontButtons
    LDR X2, [X2]
    MOV X3, #1
    BL SendMessageA

    LDR X0, =g_hButtonClear
    LDR X0, [X0]
    MOV X1, #WM_SETFONT
    LDR X2, =g_hFontButtons
    LDR X2, [X2]
    MOV X3, #1
    BL SendMessageA

    LDR X0, =g_hButtonGhost
    LDR X0, [X0]
    MOV X1, #WM_SETFONT
    LDR X2, =g_hFontButtons
    LDR X2, [X2]
    MOV X3, #1
    BL SendMessageA

    ; Game timer
    MOV X0, X19
    MOV X1, #GAME_TIMER_ID
    MOV X2, #GAME_TICK_MS
    MOV X3, #0
    BL SetTimer

    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; WM_PAINT
; ---------------------------------------------------------------------------
wp_paint
    MOV X0, X19
    LDR X1, =ps
    BL BeginPaint

    MOV X23, X0                  ; hdc

    LDR X0, =g_renderer
    LDR X1, =g_game
    MOV X2, X23
    BL RenderGame

    MOV X0, X19
    LDR X1, =ps
    BL EndPaint

    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; WM_COMMAND
; ---------------------------------------------------------------------------
wp_command
    UXTH W8, W21                 ; low word = control ID

    CMP W8, #IDC_EDIT_NAME
    B.EQ wp_cmd_edit
    CMP W8, #IDC_BUTTON_START
    B.EQ wp_cmd_pause
    CMP W8, #IDC_BUTTON_CLEAR
    B.EQ wp_cmd_clear
    CMP W8, #IDC_BUTTON_GHOST
    B.EQ wp_cmd_ghost
    B wp_cmd_done

wp_cmd_edit
    LSR W8, W21, #16
    CMP W8, #EN_CHANGE
    B.NE wp_cmd_done

    LDR X0, =g_hEditName
    LDR X0, [X0]
    ADD X1, SP, #WP_TEXT1
    MOV X2, #128
    BL GetWindowTextW

    LDR X0, =g_game
    ADD X1, SP, #WP_TEXT1
    BL SetPlayerName

    MOV X0, X19
    MOV X1, #EDIT_TIMER_ID
    BL KillTimer

    MOV X0, X19
    MOV X1, #EDIT_TIMER_ID
    MOV X2, #EDIT_SAVE_DELAY_MS
    MOV X3, #0
    BL SetTimer

    LDR X0, =g_hEditName
    LDR X0, [X0]
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect

    B wp_cmd_done

wp_cmd_pause
    LDR X0, =g_game
    BL TogglePause

    LDR X8, =g_game
    LDRB W8, [X8, #GAME_STATE_paused]
    CBZ W8, wp_cmd_pause_set_text

    LDR X0, =g_hButtonStart
    LDR X0, [X0]
    LDR X1, =szResumeGame
    BL SetWindowTextA
    B wp_cmd_pause_redraw

wp_cmd_pause_set_text
    LDR X0, =g_hButtonStart
    LDR X0, [X0]
    LDR X1, =szPauseGame
    BL SetWindowTextA

wp_cmd_pause_redraw
    MOV X0, X19
    BL SetFocus

    MOV X0, X19
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect
    B wp_cmd_done

wp_cmd_clear
    LDR X8, =g_game
    STR WZR, [X8, #GAME_STATE_highScore]
    STRH WZR, [X8, #GAME_STATE_highScoreName]

    BL ClearRegistry

    LDR X0, =g_hEditName
    LDR X0, [X0]
    ADD X1, SP, #WP_TEXT1
    MOV X2, #128
    BL GetWindowTextW

    CBZ W0, wp_cmd_clear_skip_save
    ADD X0, SP, #WP_TEXT1
    BL SavePlayerName

wp_cmd_clear_skip_save
    MOV X0, X19
    BL SetFocus

    MOV X0, X19
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect
    B wp_cmd_done

wp_cmd_ghost
    LDR X8, =g_game
    LDRB W9, [X8, #GAME_STATE_showGhost]
    EOR W9, W9, #1
    STRB W9, [X8, #GAME_STATE_showGhost]

    CBZ W9, wp_cmd_ghost_off

    LDR X0, =g_hButtonGhost
    LDR X0, [X0]
    LDR X1, =szGhostOn
    BL SetWindowTextA
    B wp_cmd_ghost_redraw

wp_cmd_ghost_off
    LDR X0, =g_hButtonGhost
    LDR X0, [X0]
    LDR X1, =szGhostOff
    BL SetWindowTextA

wp_cmd_ghost_redraw
    MOV X0, X19
    BL SetFocus

    MOV X0, X19
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect
    B wp_cmd_done

wp_cmd_done
    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; WM_TIMER
; ---------------------------------------------------------------------------
wp_timer
    CMP X21, #GAME_TIMER_ID
    B.EQ wp_timer_game
    CMP X21, #EDIT_TIMER_ID
    B.EQ wp_timer_edit
    B wp_timer_done

wp_timer_game
    LDR X0, =g_game
    MOV W1, #GAME_TICK_MS
    BL UpdateGame

    MOV X0, X19
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect
    B wp_timer_done

wp_timer_edit
    LDR X0, =g_hEditName
    LDR X0, [X0]
    ADD X1, SP, #WP_TEXT1
    MOV X2, #128
    BL GetWindowTextW

    CBZ W0, wp_timer_edit_skip_save
    ADD X0, SP, #WP_TEXT1
    BL SavePlayerName

wp_timer_edit_skip_save
    MOV X0, X19
    BL SetFocus

    MOV X0, X19
    MOV X1, #EDIT_TIMER_ID
    BL KillTimer

wp_timer_done
    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; WM_KEYDOWN
; ---------------------------------------------------------------------------
wp_keydown
    CMP W21, #VK_LEFT
    B.EQ wp_key_left
    CMP W21, #VK_RIGHT
    B.EQ wp_key_right
    CMP W21, #VK_UP
    B.EQ wp_key_rotate
    CMP W21, #VK_DOWN
    B.EQ wp_key_down
    CMP W21, #VK_SPACE
    B.EQ wp_key_drop
    CMP W21, #VK_P
    B.EQ wp_cmd_pause
    CMP W21, #VK_F2
    B.EQ wp_key_f2
    CMP W21, #VK_ESCAPE
    B.EQ wp_key_escape
    B wp_key_done

wp_key_left
    LDR X0, =g_game
    BL MoveLeft
    B wp_key_redraw

wp_key_right
    LDR X0, =g_game
    BL MoveRight
    B wp_key_redraw

wp_key_rotate
    LDR X0, =g_game
    BL RotatePiece
    B wp_key_redraw

wp_key_down
    LDR X0, =g_game
    MOV W1, #1
    BL MoveDown
    B wp_key_redraw

wp_key_drop
    LDR X0, =g_game
    BL DropPiece
    B wp_key_redraw

wp_key_f2
    LDR X0, =g_game
    BL StartGame

    LDR X0, =g_hButtonStart
    LDR X0, [X0]
    LDR X1, =szPauseGame
    BL SetWindowTextA
    B wp_key_redraw

wp_key_escape
    MOV X0, #0
    BL PostQuitMessage
    B wp_key_done

wp_key_redraw
    MOV X0, X19
    MOV X1, #0
    MOV X2, #0
    BL InvalidateRect

wp_key_done
    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; WM_CTLCOLOREDIT
; ---------------------------------------------------------------------------
wp_ctlcoloredit
    LDR X8, =g_hEditName
    LDR X8, [X8]
    CMP X22, X8
    B.NE wp_default

    LDR X0, =g_hEditName
    LDR X0, [X0]
    ADD X1, SP, #WP_TEXT2
    MOV X2, #128
    BL GetWindowTextW

    CBZ W0, wp_default

    MOV X0, X21                  ; HDC
    MOVZ W1, #0xFFE0
    MOVK W1, #0x00E0, LSL #16    ; 0x00E0FFE0
    BL SetBkColor

    MOV X0, X21                  ; HDC
    MOV W1, #1                   ; TRANSPARENT
    BL SetBkMode

    LDR X0, =g_hBrushGreen
    LDR X0, [X0]
    B wp_exit

; ---------------------------------------------------------------------------
; WM_DESTROY
; ---------------------------------------------------------------------------
wp_destroy
    LDR X0, =g_renderer
    BL CleanupRenderer

    LDR X0, =g_hBrushGreen
    LDR X0, [X0]
    CBZ X0, wp_destroy_skip_brush
    BL DeleteObject

wp_destroy_skip_brush
    LDR X0, =g_hFontButtons
    LDR X0, [X0]
    CBZ X0, wp_destroy_skip_font
    BL DeleteObject

wp_destroy_skip_font
    MOV X0, #0
    BL PostQuitMessage

    MOV W0, #0
    B wp_exit

; ---------------------------------------------------------------------------
; Exit
; ---------------------------------------------------------------------------
wp_exit
    ADD X8, SP, #WP_SAVE3
    LDP X23, X24, [X8]
    ADD X8, SP, #WP_SAVE2
    LDP X21, X22, [X8]
    ADD X8, SP, #WP_SAVE1
    LDP X19, X20, [X8]
    ADD X8, SP, #WP_FP_LR
    LDP X29, X30, [X8]
    ADD SP, SP, #WP_FRAME_SIZE
    RET
    ENDP

; ---------------------------------------------------------------------------
; WinMain
; ---------------------------------------------------------------------------
WinMain PROC
    SUB SP, SP, #WM_FRAME

    STP X29, X30, [SP, #WM_FP_LR]
    ADD X29, SP, #WM_FP_LR
    STP X19, X20, [SP, #WM_SAVE1]
    STP X21, X22, [SP, #WM_SAVE2]
    STP X23, X24, [SP, #WM_SAVE3]

    ; WNDCLASSEX
    MOV W8, #80
    STR W8, [SP, #WC_cbSize]

    MOV W8, #(CS_HREDRAW + CS_VREDRAW)
    STR W8, [SP, #WC_style]

    LDR X8, =WindowProc
    STR X8, [SP, #WC_lpfn]

    STR WZR, [SP, #WC_clsExtra]
    STR WZR, [SP, #WC_wndExtra]

    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #WC_hInstance]

    STR XZR, [SP, #WC_hIcon]
    STR XZR, [SP, #WC_hCursor]

    MOV X8, #(COLOR_BTNFACE + 1)
    STR X8, [SP, #WC_hbr]

    STR XZR, [SP, #WC_menu]

    LDR X8, =szClassName
    STR X8, [SP, #WC_class]

    STR XZR, [SP, #WC_iconSm]

    ; Cursor
    MOV X0, #0
    MOV X1, #IDC_ARROW
    BL LoadCursorA
    STR X0, [SP, #WC_hCursor]

    ; Icon from shell32.dll
    LDR X0, =szShell32
    BL LoadLibraryA
    STR X0, [SP, #WM_SHELL]

    LDR X0, =g_hInstance
    LDR X0, [X0]
    LDR X1, =szShell32
    MOV X2, #80
    BL ExtractIconA

    STR X0, [SP, #WC_hIcon]
    STR X0, [SP, #WC_iconSm]

    LDR X0, [SP, #WM_SHELL]
    BL FreeLibrary

    ; Register class
    ADD X0, SP, #WM_WC
    BL RegisterClassExA

    ; Adjust window size
    STR WZR, [SP, #RECT_LEFT]
    STR WZR, [SP, #RECT_TOP]
    MOV W8, #WINDOW_WIDTH
    STR W8, [SP, #RECT_RIGHT]
    MOV W8, #WINDOW_HEIGHT
    STR W8, [SP, #RECT_BOTTOM]

    ADD X0, SP, #WM_RECT
    MOVZ W1, #0x00CA, LSL #16    ; STYLE_MAIN_ADJUST
    MOV X2, #0
    BL AdjustWindowRect

    LDR W8, [SP, #RECT_RIGHT]
    LDR W9, [SP, #RECT_LEFT]
    SUB W19, W8, W9

    LDR W8, [SP, #RECT_BOTTOM]
    LDR W9, [SP, #RECT_TOP]
    SUB W20, W8, W9

    ; Create main window: CreateWindowExA(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)
    MOV X0, #0                           ; arg 1: dwExStyle
    LDR X1, =szClassName                 ; arg 2: lpClassName
    LDR X2, =szWindowTitle               ; arg 3: lpWindowName
    MOVZ W3, #0x02CA, LSL #16            ; arg 4: dwStyle (STYLE_MAIN_CREATE)
    MOVZ X4, #0x8000, LSL #16            ; arg 5: X (CW_USEDEFAULT)
    MOVZ X5, #0x8000, LSL #16            ; arg 6: Y (CW_USEDEFAULT)
    MOV X6, X19                          ; arg 7: nWidth
    MOV X7, X20                          ; arg 8: nHeight
    STR XZR, [SP, #0]                    ; arg 9: hWndParent
    STR XZR, [SP, #8]                    ; arg 10: hMenu
    LDR X8, =g_hInstance
    LDR X8, [X8]
    STR X8, [SP, #16]                    ; arg 11: hInstance
    STR XZR, [SP, #24]                   ; arg 12: lpParam

    BL CreateWindowExA

    CBZ X0, wm_fail
    MOV X23, X0                  ; hwnd

    LDR X8, =g_hWnd
    STR X23, [X8]

    ; Dark title bar
    MOV W8, #1
    STR W8, [SP, #WM_DWM]
    MOV X0, X23
    MOV X1, #DWMWA_USE_IMMERSIVE_DARK_MODE
    ADD X2, SP, #WM_DWM
    MOV X3, #4
    BL DwmSetWindowAttribute

    ; Mica backdrop
    MOV W8, #DWMSBT_MAINWINDOW
    STR W8, [SP, #WM_DWM]
    MOV X0, X23
    MOV X1, #DWMWA_SYSTEMBACKDROP_TYPE
    ADD X2, SP, #WM_DWM
    MOV X3, #4
    BL DwmSetWindowAttribute

    MOV X0, X23
    MOV X1, #SW_SHOWDEFAULT
    BL ShowWindow

    MOV X0, X23
    BL UpdateWindow

wm_msgloop
    ADD X0, SP, #WM_WC
    MOV X1, #0
    MOV X2, #0
    MOV X3, #0
    BL GetMessageA

    CMP W0, #0
    B.LE wm_exit_loop

    ADD X0, SP, #WM_WC
    BL TranslateMessage

    ADD X0, SP, #WM_WC
    BL DispatchMessageA

    B wm_msgloop

wm_exit_loop
    LDR W0, [SP, #MSG_wParam]
    B wm_ret

wm_fail
    MOV W0, #1

wm_ret
    LDP X23, X24, [SP, #WM_SAVE3]
    LDP X21, X22, [SP, #WM_SAVE2]
    LDP X19, X20, [SP, #WM_SAVE1]
    LDP X29, X30, [SP, #WM_FP_LR]
    ADD SP, SP, #WM_FRAME
    RET
    ENDP

; ---------------------------------------------------------------------------
; Entry point
; ---------------------------------------------------------------------------
start PROC
    MOV X0, #0
    BL GetModuleHandleA

    LDR X1, =g_hInstance
    STR X0, [X1]

    BL WinMain
    BL ExitProcess
    ENDP

    END