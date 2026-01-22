; Windows API types
HWND typedef DWORD
HINSTANCE typedef DWORD
HMENU typedef DWORD
WPARAM typedef DWORD
LPARAM typedef DWORD
HICON typedef DWORD
HCURSOR typedef DWORD
HBRUSH typedef DWORD
LPSTR typedef DWORD
LRESULT typedef DWORD
HDC typedef DWORD
HFONT typedef DWORD
HBITMAP typedef DWORD
HPEN typedef DWORD
UINT typedef DWORD
BOOL typedef DWORD
HMODULE typedef DWORD
HACCEL typedef DWORD
HKEY typedef DWORD

; Window message constants
WM_CREATE equ 0001h
WM_DESTROY equ 0002h
WM_PAINT equ 000Fh
WM_QUIT equ 0012h
WM_KEYDOWN equ 0100h
WM_COMMAND equ 0111h
WM_SETFONT equ 0030h
WM_SIZE equ 0005h

; Virtual key codes
VK_LEFT equ 25h
VK_UP equ 26h
VK_RIGHT equ 27h
VK_DOWN equ 28h
VK_SPACE equ 20h
VK_ESCAPE equ 1Bh
VK_F2 equ 71h

; Window styles
WS_OVERLAPPED equ 00000000h
WS_CAPTION equ 00C00000h
WS_SYSMENU equ 00080000h
WS_THICKFRAME equ 00040000h
WS_MINIMIZEBOX equ 00020000h
WS_MAXIMIZEBOX equ 00010000h
WS_OVERLAPPEDWINDOW equ 00CF0000h
WS_CHILD equ 40000000h
WS_VISIBLE equ 10000000h
WS_BORDER equ 00800000h
WS_CLIPCHILDREN equ 02000000h

; Extended window styles
WS_EX_CLIENTEDGE equ 00000200h

; Class styles
CS_HREDRAW equ 0002h
CS_VREDRAW equ 0001h

; Static control styles
SS_LEFT equ 0

; Edit control styles
ES_AUTOHSCROLL equ 0080h

; Button styles
BS_PUSHBUTTON equ 0
BN_CLICKED equ 0

; Edit control notifications
EN_CHANGE equ 0300h

; ShowWindow constants
SW_SHOWDEFAULT equ 10

; Color constants
COLOR_BTNFACE equ 15

; Standard cursors
IDC_ARROW equ 32512

; Standard position
CW_USEDEFAULT equ 80000000h

; Message box constants
MB_OK equ 0
MB_ICONINFORMATION equ 40h

; NULL constant
NULL equ 0

; TRUE/FALSE
FALSE equ 0
TRUE equ 1

; Font constants
FW_NORMAL equ 400
FW_BOLD equ 700
DEFAULT_CHARSET equ 1
OUT_DEFAULT_PRECIS equ 0
CLIP_DEFAULT_PRECIS equ 0
DEFAULT_QUALITY equ 0
DEFAULT_PITCH equ 0
FF_DONTCARE equ 0

; PeekMessage constants
PM_REMOVE equ 1

; Accelerator constants
FALT equ 10h
FVIRTKEY equ 1

; Registry constants
HKEY_CURRENT_USER equ 80000001h
KEY_ALL_ACCESS equ 000F003Fh
REG_SZ equ 1
REG_DWORD equ 4
REG_OPTION_NON_VOLATILE equ 0
ERROR_SUCCESS equ 0

; GDI constants
TRANSPARENT equ 1
OPAQUE equ 2
SRCCOPY equ 00CC0020h
PS_SOLID equ 0
HS_DIAGCROSS equ 5

; Code page constants
CP_ACP equ 0

; Additional registry constants
KEY_READ equ 20019h
KEY_WRITE equ 20006h
ERROR_FILE_NOT_FOUND equ 2

; Window structures
WNDCLASSEX STRUCT
    cbSize DWORD ?
    style DWORD ?
    lpfnWndProc DWORD ?
    cbClsExtra DWORD ?
    cbWndExtra DWORD ?
    hInstance DWORD ?
    hIcon DWORD ?
    hCursor DWORD ?
    hbrBackground DWORD ?
    lpszMenuName DWORD ?
    lpszClassName DWORD ?
    hIconSm DWORD ?
WNDCLASSEX ENDS

MSG STRUCT
    hwnd DWORD ?
    message DWORD ?
    wParam DWORD ?
    lParam DWORD ?
    time DWORD ?
    pt_x DWORD ?
    pt_y DWORD ?
MSG ENDS

PAINTSTRUCT STRUCT
    hdc DWORD ?
    fErase DWORD ?
    rcPaint_left DWORD ?
    rcPaint_top DWORD ?
    rcPaint_right DWORD ?
    rcPaint_bottom DWORD ?
    fRestore DWORD ?
    fIncUpdate DWORD ?
    rgbReserved BYTE 32 DUP(?)
PAINTSTRUCT ENDS

RECT STRUCT
    left DWORD ?
    top DWORD ?
    right DWORD ?
    bottom DWORD ?
RECT ENDS

ACCEL STRUCT
    fVirt WORD ?
    key WORD ?
    cmd WORD ?
ACCEL ENDS

; Game-specific structures
POINT_STRUCT STRUCT
    x DWORD ?
    y DWORD ?
POINT_STRUCT ENDS

PIECE STRUCT
    shapeType BYTE ?
    color BYTE ?
    padding WORD ?
    x DWORD ?
    y DWORD ?
    yFloat DWORD ?
    blocks POINT_STRUCT 4 DUP(<>)
PIECE ENDS

GAME_STATE STRUCT
    boardWidth DWORD ?
    boardHeight DWORD ?
    board BYTE 400 DUP(?)
    currentPiece PIECE <>
    nextPiece PIECE <>
    score DWORD ?
    lines DWORD ?
    level DWORD ?
    gameOver BYTE ?
    paused BYTE ?
    showGhost BYTE ?
    padding BYTE ?
    rngSeed DWORD ?
    playerName WORD 128 DUP(?)
    highScore DWORD ?
    highScoreName WORD 128 DUP(?)
    yFloat DWORD ?
GAME_STATE ENDS

RENDERER_STATE STRUCT
    hwnd DWORD ?
    hdcMem DWORD ?
    hbmMem DWORD ?
    hbmOld DWORD ?
    wWidth DWORD ?
    wHeight DWORD ?
    hFontNormal DWORD ?
    hFontSmall DWORD ?
    hFontPause DWORD ?
    hFontGameOver DWORD ?
    colorBrushes DWORD 8 DUP(?)
	pausePulse DWORD ?
RENDERER_STATE ENDS
