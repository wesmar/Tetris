# PowerShell build script for Tetris x86 and x64
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Building Tetris x86 and x64" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$ML = "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x86\ml.exe"
$ML64 = "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\ml64.exe"
$LINK32 = "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x86\link.exe"
$LINK64 = "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64\link.exe"
$LIBPATH32_UM = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x86"
$LIBPATH32_UCRT = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\ucrt\x86"
$LIBPATH64_UM = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x64"
$LIBPATH64_UCRT = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\ucrt\x64"

# Build x86 version
Write-Host "[1/2] Building x86 version..." -ForegroundColor Yellow
Push-Location x86

& $ML /c /Cp /Cx /Zd /Zf /Zi main.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x86 build failed!" -ForegroundColor Red; exit 1 }

& $ML /c /Cp /Cx /Zd /Zf /Zi game.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x86 build failed!" -ForegroundColor Red; exit 1 }

& $ML /c /Cp /Cx /Zd /Zf /Zi render.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x86 build failed!" -ForegroundColor Red; exit 1 }

& $ML /c /Cp /Cx /Zd /Zf /Zi registry.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x86 build failed!" -ForegroundColor Red; exit 1 }

& $LINK32 main.obj game.obj render.obj registry.obj /subsystem:windows /entry:start /out:tetris.exe "/LIBPATH:$LIBPATH32_UM" "/LIBPATH:$LIBPATH32_UCRT" kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x86 linking failed!" -ForegroundColor Red; exit 1 }

Write-Host "[x86] Build successful!" -ForegroundColor Green
Pop-Location

# Build x64 version
Write-Host ""
Write-Host "[2/2] Building x64 version..." -ForegroundColor Yellow
Push-Location x64

& $ML64 /c /Cp /Cx /Zd /Zf /Zi main.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x64 build failed!" -ForegroundColor Red; exit 1 }

& $ML64 /c /Cp /Cx /Zd /Zf /Zi game.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x64 build failed!" -ForegroundColor Red; exit 1 }

& $ML64 /c /Cp /Cx /Zd /Zf /Zi render.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x64 build failed!" -ForegroundColor Red; exit 1 }

& $ML64 /c /Cp /Cx /Zd /Zf /Zi registry.asm
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x64 build failed!" -ForegroundColor Red; exit 1 }

& $LINK64 main.obj game.obj render.obj registry.obj /subsystem:windows /entry:start /out:tetris64.exe "/LIBPATH:$LIBPATH64_UM" "/LIBPATH:$LIBPATH64_UCRT" kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Host "ERROR: x64 linking failed!" -ForegroundColor Red; exit 1 }

Write-Host "[x64] Build successful!" -ForegroundColor Green
Pop-Location

# Move binaries to bin folder
Write-Host ""
Write-Host "Moving binaries to bin folder..." -ForegroundColor Yellow
if (!(Test-Path "bin")) { New-Item -ItemType Directory -Path "bin" | Out-Null }
Move-Item -Path "x86\tetris.exe" -Destination "bin\tetris.exe" -Force
Move-Item -Path "x64\tetris64.exe" -Destination "bin\tetris64.exe" -Force

# Clean up object files
Write-Host "Cleaning up object files..." -ForegroundColor Yellow
Remove-Item -Path "x86\*.obj" -ErrorAction SilentlyContinue
Remove-Item -Path "x64\*.obj" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host "Binaries location:"
Write-Host "  - bin\tetris.exe (x86)"
Write-Host "  - bin\tetris64.exe (x64)"
Write-Host "============================================" -ForegroundColor Green
