; Windows API function prototypes
GetModuleHandleA PROTO :DWORD
GetTickCount PROTO
ExitProcess PROTO :DWORD
RegisterClassExA PROTO :DWORD
CreateWindowExA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
ShowWindow PROTO :DWORD, :DWORD
UpdateWindow PROTO :DWORD
GetMessageA PROTO :DWORD, :DWORD, :DWORD, :DWORD
TranslateMessage PROTO :DWORD
DispatchMessageA PROTO :DWORD
DefWindowProcA PROTO :DWORD, :DWORD, :DWORD, :DWORD
PostQuitMessage PROTO :DWORD
LoadCursorA PROTO :DWORD, :DWORD
LoadLibraryA PROTO :DWORD
ExtractIconA PROTO :DWORD, :DWORD, :DWORD
FreeLibrary PROTO :DWORD
BeginPaint PROTO :DWORD, :DWORD
EndPaint PROTO :DWORD, :DWORD
GetClientRect PROTO :DWORD, :DWORD
AdjustWindowRect PROTO :DWORD, :DWORD, :DWORD
InvalidateRect PROTO :DWORD, :DWORD, :DWORD
SetWindowTextA PROTO :DWORD, :DWORD
CreateFontA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
DeleteObject PROTO :DWORD
GetDC PROTO :DWORD
ReleaseDC PROTO :DWORD, :DWORD
CreateCompatibleDC PROTO :DWORD
CreateCompatibleBitmap PROTO :DWORD, :DWORD, :DWORD
SelectObject PROTO :DWORD, :DWORD
DeleteDC PROTO :DWORD
BitBlt PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreateSolidBrush PROTO :DWORD
FillRect PROTO :DWORD, :DWORD, :DWORD
SetBkMode PROTO :DWORD, :DWORD
SetTextColor PROTO :DWORD, :DWORD
SetBkColor PROTO :DWORD, :DWORD
TextOutA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
CreatePen PROTO :DWORD, :DWORD, :DWORD
MoveToEx PROTO :DWORD, :DWORD, :DWORD, :DWORD
LineTo PROTO :DWORD, :DWORD, :DWORD
CreateHatchBrush PROTO :DWORD, :DWORD
lstrlenA PROTO :DWORD
wsprintfA PROTO C :DWORD, :DWORD, :VARARG
WideCharToMultiByte PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
GetWindowTextW PROTO :DWORD, :DWORD, :DWORD
SetWindowTextW PROTO :DWORD, :DWORD
RegCreateKeyExW PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RegOpenKeyExW PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RegQueryValueExW PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RegSetValueExW PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
RegCloseKey PROTO :DWORD
RegDeleteKeyW PROTO :DWORD, :DWORD
SetTimer PROTO :DWORD, :DWORD, :DWORD, :DWORD
KillTimer PROTO :DWORD, :DWORD
SetFocus PROTO :DWORD
PeekMessageA PROTO :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
TranslateAccelerator PROTO :DWORD, :DWORD, :DWORD
CreateAcceleratorTableA PROTO :DWORD, :DWORD
DestroyAcceleratorTable PROTO :DWORD
MessageBoxA PROTO :DWORD, :DWORD, :DWORD, :DWORD
SendMessageA PROTO :DWORD, :DWORD, :DWORD, :DWORD
Sleep PROTO :DWORD

; Aliases for ANSI functions (map non-suffixed names to A versions) using TEXTEQU
GetModuleHandle TEXTEQU <GetModuleHandleA>
RegisterClassEx TEXTEQU <RegisterClassExA>
CreateWindowEx TEXTEQU <CreateWindowExA>
GetMessage TEXTEQU <GetMessageA>
DefWindowProc TEXTEQU <DefWindowProcA>
LoadCursor TEXTEQU <LoadCursorA>
LoadLibrary TEXTEQU <LoadLibraryA>
ExtractIcon TEXTEQU <ExtractIconA>
SetWindowText TEXTEQU <SetWindowTextA>
CreateFont TEXTEQU <CreateFontA>
TextOut TEXTEQU <TextOutA>
lstrlen TEXTEQU <lstrlenA>
wsprintf TEXTEQU <wsprintfA>
PeekMessage TEXTEQU <PeekMessageA>
CreateAcceleratorTable TEXTEQU <CreateAcceleratorTableA>
MessageBox TEXTEQU <MessageBoxA>
SendMessage TEXTEQU <SendMessageA>
DispatchMessage TEXTEQU <DispatchMessageA>

; Game function prototypes
InitGame PROTO :DWORD, :DWORD, :DWORD
StartGame PROTO :DWORD
GenerateRandomPiece PROTO :DWORD, :DWORD
SpawnNewPiece PROTO :DWORD
CheckCollision PROTO :DWORD, :DWORD
LockPiece PROTO :DWORD
ClearFullLines PROTO :DWORD
UpdateGame PROTO :DWORD, :DWORD
MoveLeft PROTO :DWORD
MoveRight PROTO :DWORD
MoveDown PROTO :DWORD, :DWORD
RotatePiece PROTO :DWORD
DropPiece PROTO :DWORD
PauseGame PROTO :DWORD
ResumeGame PROTO :DWORD
TogglePause PROTO :DWORD
SetPlayerName PROTO :DWORD, :DWORD

InitRenderer PROTO :DWORD, :DWORD
CleanupRenderer PROTO :DWORD
CreateBackBuffer PROTO :DWORD
ResizeRenderer PROTO :DWORD, :DWORD, :DWORD
RenderGame PROTO :DWORD, :DWORD, :DWORD
DrawBoard PROTO :DWORD, :DWORD
DrawGhostPiece PROTO :DWORD, :DWORD
DrawPiece PROTO :DWORD, :DWORD
DrawNextPiece PROTO :DWORD, :DWORD
DrawInfo PROTO :DWORD, :DWORD

SavePlayerName PROTO :DWORD
LoadPlayerName PROTO :DWORD
SaveHighScore PROTO :DWORD
LoadHighScore PROTO :DWORD
ClearRegistry PROTO

WindowProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD