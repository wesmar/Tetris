# ===========================================================================
# Master Build Script for Tetris Assembly (x86, x64, ARM64)
# Auto-detects the latest MSVC Toolset and Windows SDK environment.
# ===========================================================================
$ErrorActionPreference = "Stop"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       TETRIS ASSEMBLY MASTER BUILD SYSTEM (x86, x64, ARM64)" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
# 1. Environment Auto-Detection
# ---------------------------------------------------------------------------
Write-Host "[*] Detecting MSVC Toolset & Windows SDK environment..." -ForegroundColor Yellow

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsPath = $null

if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -property installationPath
}

if (-not $vsPath) {
    $vsDir = Get-ChildItem "C:\Program Files\Microsoft Visual Studio" -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($vsDir) {
        $edition = Get-ChildItem $vsDir.FullName -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
        $vsPath = $edition.FullName
    }
}

if (-not $vsPath -or -not (Test-Path "$vsPath\VC\Tools\MSVC")) {
    Write-Host "ERROR: Could not locate Visual Studio installation!" -ForegroundColor Red
    exit 1
}

$msvcDir = Get-ChildItem "$vsPath\VC\Tools\MSVC" -Directory | Sort-Object Name -Descending | Select-Object -First 1
$msvcPath = $msvcDir.FullName
$msvcVer = $msvcDir.Name

# Windows SDK Detection
$sdkLibBase = "C:\Program Files (x86)\Windows Kits\10\Lib"
$sdkVerDir = Get-ChildItem $sdkLibBase -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "10.*" } | Sort-Object Name -Descending | Select-Object -First 1

if (-not $sdkVerDir) {
    Write-Host "ERROR: Could not locate Windows SDK installation!" -ForegroundColor Red
    exit 1
}

$sdkVer = $sdkVerDir.Name
$sdkIncPath = "C:\Program Files (x86)\Windows Kits\10\Include\$sdkVer"

# Binaries & Tool Paths
$hostBin = "$msvcPath\bin\Hostx64"
$ML32     = "$hostBin\x86\ml.exe"
$LINK32   = "$hostBin\x86\link.exe"
$ML64     = "$hostBin\x64\ml64.exe"
$LINK64   = "$hostBin\x64\link.exe"
$ARMASM64 = "$hostBin\arm64\armasm64.exe"
$LINKARM  = "$hostBin\arm64\link.exe"

# RC.exe path
$rcExe = "C:\Program Files (x86)\Windows Kits\10\bin\$sdkVer\x64\rc.exe"
if (-not (Test-Path $rcExe)) {
    $rcExe = "C:\Program Files (x86)\Windows Kits\10\bin\$sdkVer\x86\rc.exe"
}

# Library Paths
$msvcLib32    = "$msvcPath\lib\x86"
$msvcLib64    = "$msvcPath\lib\x64"
$msvcLibARM64 = "$msvcPath\lib\arm64"

$sdkLib32_UM   = "$sdkLibBase\$sdkVer\um\x86"
$sdkLib32_UCRT = "$sdkLibBase\$sdkVer\ucrt\x86"
$sdkLib64_UM   = "$sdkLibBase\$sdkVer\um\x64"
$sdkLib64_UCRT = "$sdkLibBase\$sdkVer\ucrt\x64"
$sdkLibARM_UM  = "$sdkLibBase\$sdkVer\um\arm64"
$sdkLibARM_UCRT= "$sdkLibBase\$sdkVer\ucrt\arm64"

Write-Host "    [+] Visual Studio: $vsPath" -ForegroundColor DarkGray
Write-Host "    [+] MSVC Toolset : $msvcVer" -ForegroundColor DarkGray
Write-Host "    [+] Windows SDK  : $sdkVer" -ForegroundColor DarkGray
Write-Host ""

# Environment variables for RC
$env:INCLUDE = "$sdkIncPath\um;$sdkIncPath\shared;$sdkIncPath\ucrt"
$env:PATH = "$hostBin\x64;C:\Program Files (x86)\Windows Kits\10\bin\$sdkVer\x64;" + $env:PATH

# Ensure bin directory exists
if (-not (Test-Path "bin")) {
    New-Item -ItemType Directory -Path "bin" | Out-Null
}

# ---------------------------------------------------------------------------
# 2. Build x86 (Win32)
# ---------------------------------------------------------------------------
Write-Host "[1/3] Building x86 (Win32) executable..." -ForegroundColor Yellow
Push-Location x86
try {
    # Assemble x86 source files
    $x86Files = @("main.asm", "game.asm", "render.asm", "registry.asm")
    foreach ($f in $x86Files) {
        Write-Host "    Assembling $f..." -ForegroundColor DarkGray
        & $ML32 /c /Cp /Cx /Zd /Zf /Zi $f
        if ($LASTEXITCODE -ne 0) { throw "Assembling $f failed" }
    }

    # Compile resource
    Write-Host "    Compiling resources..." -ForegroundColor DarkGray
    & $rcExe /c65001 /fo tetris.res ..\tetris.rc
    if ($LASTEXITCODE -ne 0) { throw "Resource compilation failed" }

    # Link x86
    Write-Host "    Linking bin\tetris.exe..." -ForegroundColor DarkGray
    & $LINK32 main.obj game.obj render.obj registry.obj tetris.res `
        /subsystem:windows `
        /entry:start `
        /out:..\bin\tetris.exe `
        /MANIFEST:EMBED `
        /MANIFESTINPUT:..\tetris.manifest `
        "/LIBPATH:$msvcLib32" `
        "/LIBPATH:$sdkLib32_UM" `
        "/LIBPATH:$sdkLib32_UCRT" `
        kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib

    if ($LASTEXITCODE -ne 0) { throw "x86 linking failed" }
    Write-Host "    [SUCCESS] x86 build complete -> bin\tetris.exe" -ForegroundColor Green
}
finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# 3. Build x64 (AMD64)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Building x64 (AMD64) executable..." -ForegroundColor Yellow
Push-Location x64
try {
    $x64Files = @("main.asm", "game.asm", "render.asm", "registry.asm", "particles.asm")
    foreach ($f in $x64Files) {
        Write-Host "    Assembling $f..." -ForegroundColor DarkGray
        & $ML64 /c /Cp /Cx /Zd /Zf /Zi $f
        if ($LASTEXITCODE -ne 0) { throw "Assembling $f failed" }
    }

    # Compile resource
    Write-Host "    Compiling resources..." -ForegroundColor DarkGray
    & $rcExe /c65001 /fo tetris.res ..\tetris.rc
    if ($LASTEXITCODE -ne 0) { throw "Resource compilation failed" }

    # Link x64
    Write-Host "    Linking bin\tetris64.exe..." -ForegroundColor DarkGray
    & $LINK64 main.obj game.obj render.obj registry.obj particles.obj tetris.res `
        /subsystem:windows `
        /entry:start `
        /out:..\bin\tetris64.exe `
        /MANIFEST:EMBED `
        /MANIFESTINPUT:..\tetris.manifest `
        "/LIBPATH:$msvcLib64" `
        "/LIBPATH:$sdkLib64_UM" `
        "/LIBPATH:$sdkLib64_UCRT" `
        kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib dwmapi.lib msimg32.lib

    if ($LASTEXITCODE -ne 0) { throw "x64 linking failed" }
    Write-Host "    [SUCCESS] x64 build complete -> bin\tetris64.exe" -ForegroundColor Green
}
finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# 4. Build ARM64 (AArch64)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Building ARM64 (AArch64) executable..." -ForegroundColor Yellow
Push-Location arm64
try {
    $armFiles = @("main.asm", "game.asm", "render.asm", "registry.asm", "particles.asm")
    $armObjs = @()
    foreach ($f in $armFiles) {
        $obj = [System.IO.Path]::ChangeExtension($f, ".obj")
        Write-Host "    Assembling $f..." -ForegroundColor DarkGray
        & $ARMASM64 -g -i . $f $obj
        if ($LASTEXITCODE -ne 0) { throw "Assembling $f failed" }
        $armObjs += $obj
    }

    # Compile resource
    Write-Host "    Compiling resources..." -ForegroundColor DarkGray
    & $rcExe /c65001 /fo tetris.res ..\tetris.rc
    if ($LASTEXITCODE -ne 0) { throw "Resource compilation failed" }

    # Link ARM64
    Write-Host "    Linking bin\tetris_arm64.exe..." -ForegroundColor DarkGray
    & $LINKARM $armObjs tetris.res `
        /MACHINE:ARM64 `
        /subsystem:windows `
        /entry:start `
        /out:..\bin\tetris_arm64.exe `
        /MANIFEST:EMBED `
        /MANIFESTINPUT:..\tetris.manifest `
        "/LIBPATH:$msvcLibARM64" `
        "/LIBPATH:$sdkLibARM_UM" `
        "/LIBPATH:$sdkLibARM_UCRT" `
        kernel32.lib user32.lib gdi32.lib advapi32.lib shell32.lib dwmapi.lib msimg32.lib

    if ($LASTEXITCODE -ne 0) { throw "ARM64 linking failed" }
    Write-Host "    [SUCCESS] ARM64 build complete -> bin\tetris_arm64.exe" -ForegroundColor Green
}
finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
# 5. Cleanup Intermediate Files
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "[*] Cleaning up intermediate objects and resources..." -ForegroundColor DarkGray
Remove-Item -Path "x86\*.obj", "x86\*.res" -ErrorAction SilentlyContinue
Remove-Item -Path "x64\*.obj", "x64\*.res" -ErrorAction SilentlyContinue
Remove-Item -Path "arm64\*.obj", "arm64\*.res" -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------------
# 6. Summary Report
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Green
Write-Host "                 BUILD SUCCEEDED - ALL TARGETS READY" -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Green

$targets = @(
    @{ Name = "x86 (Win32)";   Path = "bin\tetris.exe" },
    @{ Name = "x64 (AMD64)";   Path = "bin\tetris64.exe" },
    @{ Name = "ARM64 (AArch64)"; Path = "bin\tetris_arm64.exe" }
)

foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        $size = (Get-Item $t.Path).Length
        $sizeFormatted = "{0:N0} bytes" -f $size
        Write-Host ("  [+] {0,-15} : {1,-22} ({2})" -f $t.Name, $t.Path, $sizeFormatted) -ForegroundColor Cyan
    }
}
Write-Host "==========================================================================" -ForegroundColor Green