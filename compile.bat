@echo off
set PATH=C:\masm32\bin;%PATH%
set INCLUDE=C:\masm32\include
set LIB=C:\masm32\lib

if exist *.obj del *.obj
if exist *.exe del *.exe

echo [1/4] Compiling main.asm...
ml /c /coff /Cp /nologo main.asm
if errorlevel 1 goto error

echo [2/4] Compiling game.asm...
ml /c /coff /Cp /nologo game.asm
if errorlevel 1 goto error

echo [3/4] Compiling render.asm...
ml /c /coff /Cp /nologo render.asm
if errorlevel 1 goto error

echo [4/4] Compiling registry.asm...
ml /c /coff /Cp /nologo registry.asm
if errorlevel 1 goto error

echo.
echo Linking...
link /SUBSYSTEM:WINDOWS /ENTRY:start /NOLOGO /OUT:tetris.exe /MERGE:.rdata=.text /ALIGN:16 /OPT:REF /OPT:ICF main.obj game.obj render.obj registry.obj
if errorlevel 1 goto error

echo.
echo Cleaning up...
del *.obj

echo.
echo ========================================
echo SUCCESS! tetris.exe created.
echo ========================================
echo.
goto end

:error
echo.
echo ========================================
echo ERROR! Compilation failed.
echo ========================================
echo.
pause

:end