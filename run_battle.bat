@echo off
setlocal
REM If Godot moved, change the next line only.
set "GODOT=C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
"%GODOT%" --headless --path "%~dp0." --script "res://tests/run_battle.gd"
pause
