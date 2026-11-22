@echo off
setlocal
REM Godot path: env GODOT first, else relative-to-repo default (portable).
if not defined GODOT set "GODOT=%~dp0..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
    echo [ERROR] Godot not found: %GODOT%
    exit /b 2
)
"%GODOT%" --headless --path "%~dp0." --script "res://tests/run_battle.gd"
pause
