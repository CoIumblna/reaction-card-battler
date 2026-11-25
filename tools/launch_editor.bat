@echo off
chcp 65001 >nul
rem ============================================================
rem  Launch the Godot editor with redirected user-data dirs.
rem
rem  WHY: this machine's Godot process cannot write anywhere on
rem  C: (FileAccess.open -> ERR 12 / ERR_FILE_CANT_WRITE), but it
rem  CAN write on G:. On every editor start Godot wants to save
rem  editor data to %LOCALAPPDATA%\Godot and user:// logs to
rem  %APPDATA%\Godot\app_userdata, so it printed:
rem      ERROR: Can't save PNG at path: '...\resthumb-xxxx.png'.
rem      ERROR: Cannot create file '...\resthumb-xxxx.txt'.
rem      ERROR: Failed to open log file for writing: user://logs/godot.log
rem  Pointing LOCALAPPDATA / APPDATA at G: makes those writes land
rem  on a writable drive, so the errors disappear.
rem
rem  This is an ENVIRONMENT workaround, not a project bug. Game
rem  logic, tests and check.bat are unaffected either way.
rem ============================================================

for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
set "GODOT_USER_ROOT=G:\constraction\_gduser"

if not exist "%GODOT_USER_ROOT%\Local"  mkdir "%GODOT_USER_ROOT%\Local"
if not exist "%GODOT_USER_ROOT%\Roaming" mkdir "%GODOT_USER_ROOT%\Roaming"

set "LOCALAPPDATA=%GODOT_USER_ROOT%\Local"
set "APPDATA=%GODOT_USER_ROOT%\Roaming"

set "GODOT_BIN=%GODOT%"
if "%GODOT_BIN%"=="" set "GODOT_BIN=G:\constraction\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

if not exist "%GODOT_BIN%" (
    echo [ERROR] Godot executable not found: %GODOT_BIN%
    echo         Set the GODOT environment variable or edit this file.
    pause
    exit /b 1
)

echo Launching Godot editor
echo   project  : %PROJECT_ROOT%
echo   userdata : %GODOT_USER_ROOT%
echo.
start "" "%GODOT_BIN%" --path "%PROJECT_ROOT%" --editor
exit /b 0
