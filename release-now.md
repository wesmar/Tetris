## Tetris Assembly — ${TAG}

Pure MASM / armasm64 Tetris for Windows. Three binaries, three CPU architectures, zero CRT.

---

## 📦 Binaries (${DATE})

| File | Architecture | Size |
|------|-------------|------|
| `tetris.exe` | x86 (32-bit, Win32) | ${SIZE_X86} |
| `tetris64.exe` | x64 (AMD64) | ${SIZE_X64} |
| `tetris_arm64.exe` | ARM64 (AArch64) | ${SIZE_ARM64} |

Download all three from Assets below, or just the one you need.

---

## ⚙️ Requirements

- **x86:** Windows 7+ (32-bit or 64-bit)
- **x64:** Windows 10/11 x64
- **ARM64:** Windows 11 on ARM — Snapdragon X series, Surface Pro X / 9 / 10 / 11, etc.

No installer. No CRT. No third-party DLLs. Drop and run.

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| ← → | Move piece |
| ↑ | Rotate clockwise (wall kicks) |
| ↓ | Soft drop |
| Space | Hard drop |
| P | Pause / Resume / Restart |
| F2 | New game |
| ESC | Exit |
| Alt+C | Clear high score |

---

## 🔧 Technical

**x86** — MASM (`ml.exe`), `stdcall`, `invoke` macro, classic Win32 styling.

**x64** — MASM x64 (`ml64.exe`), Microsoft x64 ABI (manual register loading, 32-byte shadow space), Windows 11 Mica backdrop, gold line clear animation, DWM integration.

**ARM64** — `armasm64.exe` (different dialect from MASM: `AREA` sections, `DCB/DCD/DCQ`, `EXPORT`, manual EQU offset constants instead of `STRUCT`). AAPCS64 calling convention: 8 argument registers (X0–X7), no shadow space, link register (LR/X30) for return address.

All three: GDI double-buffered rendering, 7-bag randomizer, SRS rotation, registry persistence (`HKCU\Software\Tetris`).

---

## 📞 Contact

- **Email:** marek@wesolowski.eu.org
- **GitHub:** https://github.com/${REPO}

---

*Release: ${DATE} · © WESMAR 2026*
