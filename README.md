# Tetris-x86-Assembly

A high-performance, lightweight Tetris implementation written in pure x86 Assembly (MASM) utilizing the Win32 API. The project focuses on minimal binary footprint, efficient memory management, and direct OS integration without C Runtime (CRT) dependency.

**Final Binary Size:** ~13 KB  
**Target Architecture:** x86 (32-bit)  
**Subsystem:** Windows (GUI)  

## 🔗 Quick Links
- **Download Latest Binary:** [Releases](https://github.com/wesmar/Tetris/releases/tag/latest)
- **Source Repository:** [GitHub](https://github.com/wesmar/Tetris)

## 🛠 Technical Specifications & Features

### 1. Core Engine
- **Zero-Dependency:** No external libraries beyond standard Windows system DLLs (`user32`, `gdi32`, `kernel32`, `advapi32`, `shell32`).
- **Memory Footprint:** Highly optimized data structures. The entire game state is encapsulated in a single `GAME_STATE` structure.
- **7-Bag Randomizer:** Implements the modern Tetris Guideline "Random Generator" (7-bag) algorithm using Fisher-Yates shuffle. This ensures a uniform distribution of pieces and prevents long droughts of specific shapes by shuffling a "bag" of all 7 tetrominoes.
- **Fixed Timestep:** Game logic is driven by a high-frequency loop tuned for 60 FPS (~16ms delta), ensuring smooth input response and movement.
- **SRS-inspired Rotation:** Super Rotation System with wall kick tables for both standard pieces and I-piece, allowing rotation near walls and floors.

### 2. Graphics & Rendering
- **GDI Double Buffering:** Implementation of a backbuffer system using `CreateCompatibleDC` and `CreateCompatibleBitmap` to eliminate flickering during high-frequency screen invalidation.
- **Ghost Piece Preview:** Toggleable semi-transparent hatch pattern overlay showing the landing position of the current piece, rendered using `CreateHatchBrush` with `HS_DIAGCROSS` pattern.
- **Animated UI Elements:** Pulsing "PAUSED" text with sine-wave brightness modulation (127-255 range) at 60 FPS for smooth visual feedback.
- **Vector-like Tetromino Definition:** Shapes are defined as coordinate offsets in `SHAPE_TEMPLATES`, allowing for efficient rotation and collision calculations via iterative offset addition.
- **Dynamic UI:** Integration of standard Win32 controls (Edit boxes, Buttons) with custom GDI-rendered game area.
- **Color-Coded Interface:** Next piece preview and record holder name displayed in matching piece colors for visual consistency.

### 3. Data Persistence (Registry-based)
Unlike traditional implementations using `.ini` or `.cfg` files, this project utilizes the Windows Registry for state persistence:
- **Path:** `HKEY_CURRENT_USER\Software\Tetris`
- **Stored Keys:**
  - `PlayerName` (REG_SZ / Unicode): Last active player identity.
  - `HighScore` (REG_DWORD): Maximum score achieved.
  - `HighScoreName` (REG_SZ / Unicode): Name of the record holder.
- **Encoding:** Full Unicode support for player names via `RegQueryValueExW` and `RegSetValueExW`.
- **Clear Record Feature:** One-click registry cleanup via Alt+C or dedicated button with confirmation dialog.

### 4. Collision & Logic
- **AABB-style Collision:** Piece-to-wall and piece-to-stack collision detection implemented through boundary checking and bitmask-like array lookups in the 10x20 board buffer.
- **Line Clearing:** Optimized scanline algorithm that identifies full rows and performs a memory-shift operation to drop the remaining blocks. Supports simultaneous multi-line clears.
- **Progressive Difficulty:** Gravity speed increases with level (every 10 lines cleared), calculated using fixed-point arithmetic with 1/10000 precision for smooth acceleration.
- **Scoring System:** Quadratic scaling (lines² × 100 × level) rewards multi-line clears and higher levels.

### 5. User Experience
- **Keyboard Shortcuts:** Full accelerator table support (P/Alt+P, P/Alt+R, Alt+C) for pause, resume, and clear operations.
- **Customizable Icon:** Dynamic icon loading from `shell32.dll` via `ExtractIcon` API (configurable index).
- **Real-time Name Persistence:** Player name auto-saves on text change via `EN_CHANGE` notification.
- **Anonymous Fallback:** Automatically assigns "Anonymous" to high scores when no player name is set.

## 📂 Project Structure

| File | Description |
| :--- | :--- |
| `main.asm` | Entry point, Window Procedure (`WndProc`), Message Loop, UI Control handling, and keyboard accelerators. |
| `game.asm` | Core logic: Tetromino movement, rotation with wall kicks, 7-bag generation using LCG RNG, collision detection, and line clearing. |
| `render.asm` | GDI rendering engine: Backbuffer management, block drawing, ghost piece rendering, pulsing text animation, and info panel output. |
| `registry.asm` | Low-level wrapper for `advapi32` functions to handle persistent data storage (High Score, Player Name). |
| `data.inc` | Structure definitions (`GAME_STATE`, `PIECE`, `RENDERER_STATE`) and constant declarations. |
| `proto.inc` | Procedure prototypes for inter-modular communication. |
| `compile.bat`| Build script for MASM32 toolchain. |

## 🔧 Build Instructions

### Prerequisites
- **MASM32 SDK** installed at `C:\masm32`.

### Compilation Process
The build process uses the Microsoft Macro Assembler (`ml.exe`) and Linker (`link.exe`).
```batch
:: Assemble all modules
ml /c /coff /Cp /nologo main.asm
ml /c /coff /Cp /nologo game.asm
ml /c /coff /Cp /nologo render.asm
ml /c /coff /Cp /nologo registry.asm

:: Link objects into a standalone GUI executable
link /SUBSYSTEM:WINDOWS /ENTRY:start /NOLOGO /OUT:tetris.exe main.obj game.obj render.obj registry.obj
```

Execution of `compile.bat` will automate this process and produce `tetris.exe` (~13 KB).

## 🎮 Controls

| Key | Action |
| :--- | :--- |
| **Left / Right** | Move Tetromino horizontally |
| **Up** | Rotate clockwise (with wall kicks) |
| **Down** | Soft Drop (faster fall) |
| **Space** | Hard Drop (instant placement) |
| **P** | Pause / Resume / Restart (on Game Over) |
| **F2** | Start New Game |
| **ESC** | Exit Application |
| **Alt+P** | Pause Game |
| **Alt+R** | Resume Game |
| **Alt+C** | Clear High Score Record |

### UI Controls
- **Player Name Field:** Auto-saves on change, supports Unicode input (max 127 characters).
- **Pause/Resume Button:** Context-sensitive label (changes based on game state).
- **Clear Record Button:** Resets high score to 0 with confirmation dialog.
- **Ghost Toggle Button:** Enable/disable landing position preview (ON/OFF).

## 🎨 Customization

### Changing Application Icon
Edit `main.asm` around line 83-84:
```asm
invoke ExtractIcon, g_hInstance, offset szShell32, 19  ; Change icon index here
```

**Recommended DLL files for icons (Windows 11):**
- `shell32.dll` - Classic system icons
- `imageres.dll` - Modern icon collection (300+ icons)
- `ddores.dll` - Hardware/device icons

Use **Resource Hacker** to browse available icons and their indices in these files.

## 📊 Technical Highlights

### Random Number Generation
- **Algorithm:** Linear Congruential Generator (LCG)
- **Formula:** `seed = seed × 1103515245 + 12345`
- **Seed Source:** System tick count at initialization
- **Distribution:** Fisher-Yates shuffle ensures perfect fairness

### Gravity System
- **Fixed-Point Math:** Accumulator with 1/10000 precision (`yFloat`)
- **Speed Formula:** `base_speed(300) + level × 50`
- **Drop Trigger:** Piece moves down when accumulator reaches 10000

### Rendering Pipeline
1. Clear backbuffer (dark gray 0x141414)
2. Draw grid lines (0x323232)
3. Draw locked blocks from board array
4. Draw ghost piece (hatch pattern, conditional)
5. Draw current falling piece
6. Draw next piece preview (color-matched)
7. Draw statistics and controls guide
8. Draw overlays (PAUSED pulsing text / GAME OVER)
9. BitBlt backbuffer to screen (single operation, no flicker)

---

**Author:** Marek Wesołowski  
**Email:** marek@wesolowski.eu.org  
**Website:** https://kvc.pl  
**License:** MIT