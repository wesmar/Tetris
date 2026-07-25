; proto.inc
; ARM64 (armasm64, Windows)
;
; Linker must link at least:
; kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib dwmapi.lib msimg32.lib

; ---------------------------------------------------------------------------
; Windows API imports
; ---------------------------------------------------------------------------
    IMPORT GetModuleHandleA
    IMPORT GetTickCount
    IMPORT ExitProcess

    IMPORT RegisterClassExA
    IMPORT CreateWindowExA
    IMPORT ShowWindow
    IMPORT UpdateWindow
    IMPORT GetMessageA
    IMPORT TranslateMessage
    IMPORT DispatchMessageA
    IMPORT DefWindowProcA
    IMPORT PostQuitMessage

    IMPORT LoadCursorA
    IMPORT LoadLibraryA
    IMPORT ExtractIconA
    IMPORT FreeLibrary

    IMPORT BeginPaint
    IMPORT EndPaint
    IMPORT GetClientRect
    IMPORT AdjustWindowRect
    IMPORT InvalidateRect

    IMPORT SetWindowTextA
    IMPORT CreateFontA
    IMPORT DeleteObject

    IMPORT GetDC
    IMPORT ReleaseDC
    IMPORT CreateCompatibleDC
    IMPORT CreateCompatibleBitmap
    IMPORT SelectObject
    IMPORT DeleteDC
    IMPORT BitBlt

    IMPORT CreateSolidBrush
    IMPORT FillRect
    IMPORT SetBkMode
    IMPORT SendMessageA
    IMPORT SetTextColor
    IMPORT SetBkColor
    IMPORT TextOutA

    IMPORT CreatePen
    IMPORT MoveToEx
    IMPORT LineTo
    IMPORT CreateHatchBrush

    IMPORT lstrlenA
    IMPORT wsprintfA
    IMPORT WideCharToMultiByte

    IMPORT GetWindowTextW
    IMPORT SetWindowTextW

    IMPORT RegCreateKeyExW
    IMPORT RegOpenKeyExW
    IMPORT RegQueryValueExW
    IMPORT RegSetValueExW
    IMPORT RegCloseKey
    IMPORT RegDeleteKeyW

    IMPORT SetTimer
    IMPORT KillTimer
    IMPORT SetFocus

    IMPORT DwmSetWindowAttribute
    IMPORT GradientFill

; ---------------------------------------------------------------------------
; Internal game functions (game.asm)
; Define GAME_ASM before including proto.inc in game.asm
; ---------------------------------------------------------------------------
    IF :DEF: GAME_ASM
    ; Locally defined in game.asm
    ELSE
    IMPORT InitGame
    IMPORT StartGame
    IMPORT GenerateRandomPiece
    IMPORT SpawnNewPiece
    IMPORT CheckCollision
    IMPORT LockPiece
    IMPORT ClearFullLines
    IMPORT ApplyClearLines
    IMPORT UpdateGame
    IMPORT MoveLeft
    IMPORT MoveRight
    IMPORT MoveDown
    IMPORT RotatePiece
    IMPORT DropPiece
    IMPORT PauseGame
    IMPORT ResumeGame
    IMPORT TogglePause
    IMPORT SetPlayerName
    ENDIF

; ---------------------------------------------------------------------------
; Internal renderer functions (render.asm)
; Define RENDER_ASM before including proto.inc in render.asm
; ---------------------------------------------------------------------------
    IF :DEF: RENDER_ASM
    ; Locally defined in render.asm
    ELSE
    IMPORT InitRenderer
    IMPORT CleanupRenderer
    IMPORT CreateBackBuffer
    IMPORT ResizeRenderer
    IMPORT RenderGame
    IMPORT DrawBoard
    IMPORT DrawGhostPiece
    IMPORT DrawPiece
    IMPORT DrawNextPiece
    IMPORT DrawInfo
    ENDIF

; ---------------------------------------------------------------------------
; Internal registry functions (registry.asm)
; Define REGISTRY_ASM before including proto.inc in registry.asm
; ---------------------------------------------------------------------------
    IF :DEF: REGISTRY_ASM
    ; Locally defined in registry.asm
    ELSE
    IMPORT SavePlayerName
    IMPORT LoadPlayerName
    IMPORT SaveHighScore
    IMPORT LoadHighScore
    IMPORT ClearRegistry
    ENDIF

; ---------------------------------------------------------------------------
; Internal particle functions (particles.asm)
; Define PARTICLES_ASM before including proto.inc in particles.asm
; ---------------------------------------------------------------------------
    IF :DEF: PARTICLES_ASM
    ; Locally defined in particles.asm
    ELSE
    IMPORT InitParticles
    IMPORT SpawnLineExplosion
    IMPORT UpdateParticles
    IMPORT RenderParticles
    ENDIF

    END
