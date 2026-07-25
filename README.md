# Tetris Assembly (x86, x64 & ARM64)

![Tetris Gameplay](images/tetris.gif)

Pure MASM / armasm64 Tetris for Windows. Three binaries, three architectures, no CRT dependency, no third-party libraries.

| Binary | Arch | Assembler | Size |
| :--- | :--- | :--- | :--- |
| `tetris.exe` | x86 (Win32) | `ml.exe` (MASM) | ~16 KB |
| `tetris64.exe` | x64 (AMD64) | `ml64.exe` (MASM x64) | ~19 KB |
| `tetris_arm64.exe` | ARM64 (AArch64) | `armasm64.exe` | ~22 KB |

**Subsystem:** Windows (GUI) · **Dependencies:** `kernel32 user32 gdi32 advapi32 shell32` (+ `dwmapi msimg32` for x64/ARM64)

## 🔗 Quick Links
- **Download:** [Releases](https://github.com/wesmar/Tetris/releases/latest)
- **Source:** [GitHub](https://github.com/wesmar/Tetris)

---

## 📅 Update 25.01.2026 — x64 Visual Enhancements

x64 version received significant visual and UX improvements, leveraging modern Windows 11 APIs:

| Feature | Description |
| :--- | :--- |
| **Mica Backdrop Effect** | Dark mode title bar with Windows 11 Mica material (`DWMWA_USE_IMMERSIVE_DARK_MODE` + `DWMWA_SYSTEMBACKDROP_TYPE`) |
| **Segoe UI Typography** | All UI elements use Segoe UI with proper weight variations |
| **Green Player Field** | Name input field turns light green (`#E0FFE0`) when text is entered |
| **Gold Line Clear Animation** | Clearing lines triggers a 300ms fade-out animation from gold (`RGB 255,215,0`) to black |
| **Modern Button Styling** | Buttons use smaller, cleaner font styling consistent with Windows 11 design language |
| **Resource Files** | Added `tetris.rc` (resource script) and `tetris.manifest` (DPI awareness + visual styles) |

These enhancements carry over to the ARM64 port.

---

## 🏗️ Architecture Comparison

### Binary & Source Metrics

| Metric | x86 (32-bit) | x64 (64-bit) | ARM64 (AArch64) |
| :--- | :--- | :--- | :--- |
| **Binary Size** | ~16 KB | ~19 KB | ~22 KB |
| **Assembler** | `ml.exe` (MASM) | `ml64.exe` (MASM x64) | `armasm64.exe` |
| **Calling Convention** | `stdcall` | Microsoft x64 (fastcall) | AAPCS64 |
| **Argument Registers** | stack (right-to-left) | RCX, RDX, R8, R9 | X0–X7 |
| **Shadow Space** | No | 32 bytes mandatory | No |
| **`invoke` Macro** | Yes (MASM) | No | No |
| **Struct Definition** | `STRUCT/ENDS` | `STRUCT/ENDS` | Manual `EQU` offsets |
| **Section Syntax** | `.DATA` / `.CODE` | `.DATA` / `.CODE` | `AREA \|.data\|, DATA` |
| **Data Directives** | `db dd dq dup` | `db dd dq dup` | `DCB DCD DCQ SPACE` |

### x86 — stdcall and the `invoke` Macro

x86 benefits from MASM's `invoke` macro which abstracts argument passing entirely:

```asm
; x86: one line, MASM handles push sequence and stack cleanup
invoke MessageBoxA, hWnd, addr szMsg, addr szTitle, MB_OK
```

### x64 — Manual Calling Convention

x64 requires manual implementation of Microsoft's x64 ABI (fastcall variant):

```asm
; x64: every API call is 5-7 lines
mov  rcx, hWnd          ; 1st arg → RCX
lea  rdx, szMsg         ; 2nd arg → RDX
lea  r8,  szTitle       ; 3rd arg → R8
mov  r9d, MB_OK         ; 4th arg → R9
sub  rsp, 32            ; mandatory shadow space (4 × 8 bytes)
call MessageBoxA
add  rsp, 32            ; restore shadow space
```

Shadow space (32 bytes) is mandatory before every `call`, even if the callee takes zero arguments. Forgetting it corrupts the stack silently.

Stack alignment to 16 bytes is required before `call`. A single misalignment deep in a GDI/DWM call chain causes crashes that are far from the actual fault:

```asm
and rsp, -16   ; align to 16-byte boundary
```

---

## 🦾 ARM64 — A Third Assembler, A Third Dialect

The ARM64 port introduces a fundamentally different toolchain: `armasm64.exe`. Unlike `ml64.exe` (MASM), armasm64 has its own directive set with no compatibility with MASM syntax. Every layer of the source had to be rewritten for ARM64.

### The STRUCT Problem

MASM's `STRUCT` directive auto-generates field offset symbols and a `SIZEOF` constant:

```asm
; x86/x64 data.inc — MASM computes offsets automatically
GAME_STATE STRUCT
    boardWidth  DWORD ?     ; offset 0
    boardHeight DWORD ?     ; offset 4
    board       BYTE 400 DUP(?)  ; offset 8
    score       DWORD ?     ; offset 408
    paused      BYTE ?      ; offset 424
    ...
GAME_STATE ENDS
; MASM generates: SIZEOF GAME_STATE, field access via [reg].GAME_STATE.paused
```

armasm64 does not understand `STRUCT`, `ENDS`, `DWORD ?`, or `DUP`. The entire structure definition had to be rewritten as manual `EQU` offset constants:

```asm
; arm64/data.inc — every offset computed by hand
GAME_STATE_boardWidth   EQU 0
GAME_STATE_boardHeight  EQU 4
GAME_STATE_board        EQU 8
GAME_STATE_score        EQU GAME_STATE_board + 400   ; = 408
GAME_STATE_paused       EQU GAME_STATE_gameOver + 1  ; = 425
...
GAME_STATE_SIZE         EQU GAME_STATE_particleCount + 4
```

Any change to the structure (add a field, change alignment) requires manually cascading all downstream `EQU` values. ~80 constants must stay in sync. This is the most maintenance-intensive aspect of the ARM64 port.

### Sections and Data Definitions

| Purpose | MASM (x86/x64) | armasm64 |
| :--- | :--- | :--- |
| Data section | `.DATA` | `AREA \|.data\|, DATA, READWRITE, ALIGN=4` |
| Code section | `.CODE` | `AREA \|.text\|, CODE, READONLY, ALIGN=4` |
| Entry export | `PUBLIC start` | `EXPORT start` |
| Byte data | `db "string", 0` | `DCB "string", 0` |
| DWORD (32-bit) | `dd value` | `DCD value` |
| QWORD (64-bit) | `dq value` | `DCQ value` |
| Zero-fill block | `N DUP(?)` | `SPACE N` |
| External proc | `EXTERN label:PROC` | `EXTERN label:PROC` |

### ARM64 Calling Convention (AAPCS64)

ARM64 passes the first **8** integer/pointer arguments in registers X0–X7. No shadow space. The same `MessageBoxA` call:

```asm
; ARM64: 4 args fit in X0-X3, no shadow space needed
MOV  X0, X19           ; hWnd (saved in callee-preserved X19)
ADR  X1, szMsg         ; 2nd arg
ADR  X2, szTitle       ; 3rd arg
MOV  W3, #MB_OK        ; 4th arg (32-bit value in W3)
BL   MessageBoxA
```

The return address is not pushed on the stack by `BL` — it is stored in the link register **LR (X30)**. This means LR must be explicitly saved before calling any further function:

```asm
; ARM64 function prologue — save frame pointer (X29) and link register (X30)
STP  X29, X30, [SP, #-48]!   ; push pair atomically, pre-decrement SP
MOV  X29, SP                  ; frame pointer = current SP

; ... function body ...

; ARM64 function epilogue — restore and return
LDP  X29, X30, [SP], #48      ; pop pair atomically, post-increment SP
RET                            ; branches to LR (X30)
```

`STP` (Store Pair) and `LDP` (Load Pair) operate on 128-bit aligned pairs. They are the standard frame setup pattern across all ARM64 Windows code.

### Width-Qualified Registers

ARM64 exposes each general-purpose register in two widths: `X0`–`X30` (64-bit) and `W0`–`W30` (32-bit, low half of the X register). The assembler enforces correct width per instruction:

```asm
LDRB W8, [X19, #GAME_STATE_paused]   ; load byte → 32-bit W8 (zero-extended)
LDR  X0, [X19, #GAME_STATE_hWnd]     ; load pointer → 64-bit X0
STR  WZR, [X8, #GAME_STATE_score]    ; store 32-bit zero (WZR = zero register)
```

Using the wrong width (e.g., `X8` where `W8` is required) is an assembler error, not a silent runtime bug.

### Branch Without Flags

ARM64 adds `CBZ` / `CBNZ` (Compare and Branch if Zero / Nonzero) which test a register and branch in a single instruction, without touching the condition flags:

```asm
CBZ  W0, .no_score       ; if W0 == 0, jump — no CMP needed
CBNZ X8, .has_pointer    ; if X8 != 0, jump
```

x64 equivalent always requires two instructions (`test rax, rax` + `jz`).

### Immediate Values

All ARM64 immediates are prefixed with `#`:

```asm
SUB  SP, SP, #64          ; allocate 64 bytes on stack
ADD  X1, X1, #GAME_STATE_playerName   ; add struct offset constant
MOV  W0, #0x0F            ; load immediate into W0
```

The `#` is mandatory — omitting it causes an assembler error.

---

## 🛠 Technical Specifications

### Core Engine
- **Zero-Dependency:** No CRT. Only standard Windows system DLLs.
- **7-Bag Randomizer:** Modern Tetris Guideline "Random Generator" — Fisher-Yates shuffle of all 7 tetrominoes. Prevents piece droughts.
- **Fixed Timestep:** 60 FPS loop (~16ms delta) via `WM_TIMER`. Smooth input and gravity.
- **SRS-Inspired Rotation:** Super Rotation System with wall kick tables for all pieces and I-piece.

### Graphics & Rendering
- **GDI Double Buffering:** `CreateCompatibleDC` + `CreateCompatibleBitmap` backbuffer — zero flicker at 60 FPS.
- **Ghost Piece Preview:** Toggleable landing position preview using `CreateHatchBrush` with `HS_DIAGCROSS`.
- **Animated UI Elements:** Pulsing "PAUSED" text with sine-wave brightness modulation (127–255 range).
- **Gold Line Clear Animation** (x64/ARM64): 300ms fade from `RGB(255,215,0)` to black on line clear.
- **Mica Backdrop** (x64/ARM64): Windows 11 `DWMWA_USE_IMMERSIVE_DARK_MODE` + `DWMWA_SYSTEMBACKDROP_TYPE`.

### Data Persistence (Registry)
- **Path:** `HKEY_CURRENT_USER\Software\Tetris`
- **Keys:** `PlayerName` (REG_SZ Unicode), `HighScore` (REG_DWORD), `HighScoreName` (REG_SZ Unicode)
- **Encoding:** Full Unicode via `RegQueryValueExW` / `RegSetValueExW`

### Collision & Logic
- **AABB Collision:** Boundary checking and array lookup in the 10×20 board buffer.
- **Line Clearing:** Scanline scan + memory-shift drop. Supports simultaneous multi-line clears.
- **Progressive Difficulty:** Speed increases every 10 lines. Fixed-point arithmetic with 1/10000 precision.
- **Scoring:** `lines² × 100 × level`

### RNG & Gravity
- **LCG:** `seed = seed × 1103515245 + 12345`, seeded from `GetTickCount`
- **Gravity:** `base_speed(300) + level × 50`, accumulator with 1/10000 precision

### Rendering Pipeline
1. Clear backbuffer (`0x141414`)
2. Draw grid lines (`0x323232`)
3. Draw locked blocks
4. Draw line clear animation overlay (x64/ARM64)
5. Draw ghost piece (hatch pattern, optional)
6. Draw current falling piece
7. Draw next piece preview (color-matched)
8. Draw statistics panel
9. Draw overlays (PAUSED pulse / GAME OVER)
10. `BitBlt` backbuffer → screen (single operation, no flicker)

---

## 📂 Project Structure

```
Tetris/
├── x86/                    32-bit implementation (MASM, stdcall)
│   ├── main.asm            Entry point, WndProc, message loop
│   ├── game.asm            Game logic, rotation, line clearing
│   ├── render.asm          GDI rendering engine
│   ├── registry.asm        Registry persistence
│   ├── data.inc            STRUCT definitions (GAME_STATE, PIECE, RENDERER_STATE)
│   └── proto.inc           Procedure prototypes (PROTO + invoke)
├── x64/                    64-bit implementation (MASM x64, Microsoft ABI)
│   ├── main.asm            Entry point (manual x64 calling convention)
│   ├── game.asm            Game logic (64-bit registers, shadow space)
│   ├── render.asm          GDI rendering + DWM/Mica integration
│   ├── registry.asm        Registry ops (64-bit pointers)
│   ├── particles.asm       Line clear particle animation (x64/ARM64 only)
│   ├── data.inc            STRUCT definitions (8-byte QWORD alignment)
│   ├── proto.inc           Procedure prototypes (fastcall)
│   ├── tetris.rc           Resource script (icon, manifest)
│   └── tetris.manifest     DPI awareness, visual styles, Win11 activation
├── arm64/                  ARM64 implementation (armasm64, AAPCS64)
│   ├── main.asm            Entry point (AREA sections, EXPORT, ARM64 ABI)
│   ├── game.asm            Game logic (ARM64 instructions)
│   ├── render.asm          GDI rendering (STP/LDP frame management)
│   ├── registry.asm        Registry ops
│   ├── particles.asm       Particle system (ARM64)
│   ├── data.inc            Manual EQU offset constants (no STRUCT — armasm64 limitation)
│   └── proto.inc           EXTERN declarations (no PROTO keyword in armasm64)
├── bin/                    Output directory
│   ├── tetris.exe          x86 binary (~16 KB)
│   ├── tetris64.exe        x64 binary (~19 KB)
│   └── tetris_arm64.exe    ARM64 binary (~22 KB)
├── images/
│   └── tetris.gif          Gameplay screenshot
├── tetris.rc               Shared resource script
├── tetris.manifest         Shared application manifest
├── build.ps1               Unified PowerShell build script (all 3 architectures)
├── release-now.sh          Release automation (build → gh release create)
└── release-now.md          Release notes template (envsubst variables)
```

### Key Files

| File | Description |
| :--- | :--- |
| `main.asm` | Entry point, WndProc, message loop, UI controls, keyboard accelerators |
| `game.asm` | Tetromino movement, SRS rotation with wall kicks, 7-bag RNG, collision, line clearing |
| `render.asm` | GDI backbuffer, block drawing, ghost piece, animations, info panel |
| `registry.asm` | `advapi32` wrappers for high score and player name persistence |
| `particles.asm` | Line clear explosion particles (x64/ARM64 only) |
| `data.inc` | Structure definitions (MASM: `STRUCT/ENDS`; ARM64: manual `EQU` offsets) |
| `proto.inc` | Procedure declarations (MASM: `PROTO`; ARM64: `EXTERN label:PROC`) |
| `build.ps1` | Auto-detects VS toolchain, builds all 3 architectures sequentially |
| `release-now.sh` | Builds, measures binary sizes, creates/replaces GitHub release with assets |

---

## 🔧 Build Instructions

### Prerequisites

- **Visual Studio 2022 or newer** with "Desktop development with C++" workload
  - Provides: `ml.exe` (x86), `ml64.exe` (x64), `armasm64.exe` (ARM64), linker, Windows SDK

### Recommended: PowerShell (all 3 architectures)

```powershell
.\build.ps1
```

The script auto-detects the VS toolchain, builds all three targets, and cleans intermediate files.

**Output:**
```
bin/tetris.exe          x86  (~16 KB)
bin/tetris64.exe        x64  (~19 KB)
bin/tetris_arm64.exe    ARM64 (~22 KB)
```

### Manual Build — x86

Open "x86 Native Tools Command Prompt for VS 2022":

```batch
cd x86
ml /c /Cp /Cx /Zd /Zf /Zi main.asm game.asm render.asm registry.asm
rc /c65001 /fo tetris.res ..\tetris.rc
link main.obj game.obj render.obj registry.obj tetris.res ^
    /subsystem:windows /entry:start /out:..\bin\tetris.exe ^
    /MANIFEST:EMBED /MANIFESTINPUT:..\tetris.manifest ^
    kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib
```

### Manual Build — x64

Open "x64 Native Tools Command Prompt for VS 2022":

```batch
cd x64
ml64 /c /Cp /Cx /Zd /Zf /Zi main.asm game.asm render.asm registry.asm particles.asm
rc /c65001 /fo tetris.res ..\tetris.rc
link main.obj game.obj render.obj registry.obj particles.obj tetris.res ^
    /subsystem:windows /entry:start /out:..\bin\tetris64.exe ^
    /MANIFEST:EMBED /MANIFESTINPUT:..\tetris.manifest ^
    kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib dwmapi.lib msimg32.lib
```

### Manual Build — ARM64

Open "x64 Native Tools Command Prompt for VS 2022" (uses the x64-hosted ARM64 cross-toolchain):

```batch
cd arm64
armasm64 -g -i . main.asm main.obj
armasm64 -g -i . game.asm game.obj
armasm64 -g -i . render.asm render.obj
armasm64 -g -i . registry.asm registry.obj
armasm64 -g -i . particles.asm particles.obj
rc /c65001 /fo tetris.res ..\tetris.rc
link main.obj game.obj render.obj registry.obj particles.obj tetris.res ^
    /MACHINE:ARM64 /subsystem:windows /entry:start /out:..\bin\tetris_arm64.exe ^
    /MANIFEST:EMBED /MANIFESTINPUT:..\tetris.manifest ^
    kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib dwmapi.lib msimg32.lib
```

> **Note for ARM64:** `armasm64.exe` syntax is incompatible with MASM. The `arm64/data.inc` and `arm64/proto.inc` are written specifically for armasm64 (EQU offsets, `EXTERN label:PROC`). Never replace them with the MASM-style equivalents from `x64/`.

---

## 🎮 Controls

| Key | Action |
| :--- | :--- |
| **Left / Right** | Move piece horizontally |
| **Up** | Rotate clockwise (with wall kicks) |
| **Down** | Soft drop |
| **Space** | Hard drop (instant placement) |
| **P** | Pause / Resume / Restart (on Game Over) |
| **F2** | Start new game |
| **ESC** | Exit |
| **Alt+P** | Pause |
| **Alt+R** | Resume |
| **Alt+C** | Clear high score record |

### UI Controls
- **Player Name Field:** Auto-saves on change, Unicode input (max 127 characters).
- **Pause/Resume Button:** Context-sensitive label.
- **Clear Record Button:** Resets high score with confirmation dialog.
- **Ghost Toggle Button:** Enable/disable ghost piece preview.

---

## 💡 Which Version to Use

| Version | When |
| :--- | :--- |
| **x86** | Maximum compatibility (runs on both 32-bit and 64-bit Windows). Classic styling. ~16 KB. |
| **x64** | Native 64-bit on AMD64/Intel CPUs. Windows 11 Mica backdrop, gold line clear animation. ~19 KB. |
| **ARM64** | Windows 11 on ARM hardware (Snapdragon X series, Surface Pro X/9/10/11, etc.). Native, not emulated. ~22 KB. |

---

## 🎨 Customization

### Application Icon

**x86** — edit `x86/main.asm`:
```asm
invoke ExtractIcon, g_hInstance, offset szShell32, 19  ; change index
```

**x64/ARM64** — edit the respective `main.asm`:
```asm
; x64 example
mov  rcx, [g_hInstance]
lea  rdx, szShell32
mov  r8d, 19                ; change index
sub  rsp, 32
call ExtractIcon
add  rsp, 32
```

**Recommended icon DLLs on Windows 11:**
- `shell32.dll` — classic system icons
- `imageres.dll` — modern icon collection (300+ icons)
- `ddores.dll` — hardware/device icons

Use **Resource Hacker** to browse available indices.

---

## 🗺️ Platform Coverage

Three Windows targets are complete. The table below maps remaining pure-assembly ports and what each one technically requires.

### Completed

| Platform | Binary | Assembler | ABI | Rendering |
| :--- | :--- | :--- | :--- | :--- |
| Windows x86 | PE (Win32) | `ml.exe` (MASM) | `stdcall` | GDI |
| Windows x64 | PE (AMD64) | `ml64.exe` (MASM x64) | Microsoft x64 | GDI + DWM/Mica |
| Windows ARM64 | PE (AArch64) | `armasm64.exe` | AAPCS64 | GDI + DWM/Mica |

### Remaining

| Platform | Binary | Assembler | ABI | Rendering | Key Delta vs Windows |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Linux x64** | ELF (AMD64) | `nasm` / `as` | SysV AMD64 | Xlib (X11) | Args in RDI/RSI/RDX/RCX/R8/R9, no shadow space, no `invoke`, Xlib instead of Win32 |
| **Linux ARM64** | ELF (AArch64) | `as` (GNU) / `clang` | AAPCS64 | Xlib / Wayland | Same ABI as Windows ARM64, but ELF format, Linux syscalls, X11 or Wayland display stack |
| **macOS ARM64** | Mach-O | `clang` / `as` (Apple) | Apple AAPCS64† | Cocoa / Metal | Obj-C runtime calls via `objc_msgSend` for windowing, Mach-O format, `ld` (Apple linker) |
| **Android ARM64** | ELF `.so` | `clang` (NDK) | AAPCS64 | OpenGL ES / Vulkan | No standalone binary — shared library loaded via JNI or `ANativeActivity`; packaged into APK |

†Apple's AAPCS64 variant includes pointer authentication (PAC) on hardware that supports it, and differs from the standard in varargs stack layout.

The fundamental cost of each new target is not the instruction set — ARM64 AAPCS64 is AAPCS64 everywhere. The cost is the **OS interface layer**: binary format, linker, window system, and how the process gets its first stack frame and arguments.

---

**Author:** Marek Wesołowski  
**Email:** marek@wesolowski.eu.org  
**Website:** https://kvc.pl  
**License:** MIT
