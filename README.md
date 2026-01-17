# Tetris-x86-Assembly

A high-performance, lightweight Tetris implementation written in pure x86 Assembly (MASM) utilizing the Win32 API. The project focuses on minimal binary footprint, efficient memory management, and direct OS integration without C Runtime (CRT) dependency.

**Final Binary Size:** ~12 KB  
**Target Architecture:** x86 (32-bit)  
**Subsystem:** Windows (GUI)  

## 🔗 Quick Links
- **Download Latest Binary:** [Releases](https://github.com/wesmar/Tetris/releases/tag/latest)
- **Source Repository:** [GitHub](https://github.com/wesmar/Tetris)

## 🛠 Technical Specifications & Features

### 1. Core Engine
- **Zero-Dependency:** No external libraries beyond standard Windows system DLLs (`user32`, `gdi32`, `kernel32`, `advapi32`, `shell32`).
- **Memory Footprint:** Highly optimized data structures. The entire game state is encapsulated in a single `GAME_STATE` structure.
- **7-Bag Randomizer:** Implements the modern Tetris Guideline "Random Generator" (7-bag) algorithm. This ensures a uniform distribution of pieces and prevents long droughts of specific shapes by shuffling a "bag" of all 7 tetrominoes.
- **Fixed Timestep:** Game logic is driven by a high-frequency `WM_TIMER` loop tuned for 60 FPS (~16ms delta), ensuring smooth input response and movement.

### 2. Graphics & Rendering
- **GDI Double Buffering:** Implementation of a backbuffer system using `CreateCompatibleDC` and `CreateCompatibleBitmap` to eliminate flickering during high-frequency screen invalidation.
- **Vector-like Tetromino Definition:** Shapes are defined as coordinate offsets in `SHAPE_TEMPLATES`, allowing for efficient rotation and collision calculations via iterative offset addition.
- **Dynamic UI:** Integration of standard Win32 controls (Edit boxes, Buttons) with custom GDI-rendered game area.

### 3. Data Persistence (Registry-based)
Unlike traditional implementations using `.ini` or `.cfg` files, this project utilizes the Windows Registry for state persistence:
- **Path:** `HKEY_CURRENT_USER\Software\Tetris`
- **Stored Keys:**
  - `PlayerName` (REG_SZ / Unicode): Last active player.
  - `HighScore` (REG_DWORD): Maximum score achieved.
  - `HighScoreName` (REG_SZ / Unicode): Name of the record holder.
- **Encoding:** Full Unicode support for player names via `RegQueryValueExW` and `RegSetValueExW`.

### 4. Collision & Logic
- **AABB-style Collision:** Piece-to-wall and piece-to-stack collision detection implemented through boundary checking and bitmask-like array lookups in the 10x20 board buffer.
- **Line Clearing:** Optimized scanline algorithm that identifies full rows and performs a memory-shift operation to drop the remaining blocks.

## 📂 Project Structure

| File | Description |
| :--- | :--- |
| `main.asm` | Entry point, Window Procedure (`WndProc`), Message Loop, and UI Control handling. |
| `game.asm` | Core logic: Tetromino movement, rotation, 7-bag generation, and collision detection. |
| `render.asm` | GDI rendering engine: Backbuffer management, block drawing, and info panel text output. |
| `registry.asm` | Low-level wrapper for `advapi32` functions to handle High Score persistence. |
| `data.inc` | Structure definitions (`GAME_STATE`, `PIECE`, `RENDERER_STATE`) and constant declarations. |
| `proto.inc` | Procedure prototypes for inter-modular communication. |
| `compile.bat`| Build script for MASM32 toolchain. |

## 🏗 Build Instructions

### Prerequisites
- **MASM32 SDK** installed at `C:\masm32`.

### Compilation Process
The build process uses the Microsoft Macro Assembler (`ml.exe`) and Linker (`link.exe`).

```batch
:: Assemble modules
ml /c /coff /Cp /nologo main.asm game.asm render.asm registry.asm

:: Link objects into a standalone GUI executable
link /SUBSYSTEM:WINDOWS /ENTRY:start /NOLOGO /OUT:tetris.exe *.obj
Execution of compile.bat will automate this process and produce tetris.exe.🎮 ControlsKeyActionLeft / RightMove TetrominoUpRotateDownSoft DropSpaceHard Drop (Instant)PPause / ResumeF2New GameESCExitAuthor: Marek WesołowskiWebsite: https://kvc.pl
License: MIT