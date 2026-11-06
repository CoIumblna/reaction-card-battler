@echo off
setlocal
REM If Godot moved, change the next line only.
set "GODOT=C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "PROJ=%~dp0"
set "FAILED=0"

echo [import] importing project...
"%GODOT%" --headless --path "%PROJ%." --import >nul 2>&1

for %%t in (data_test unit_test damage_test battle_test) do (
    echo.
    echo ========== %%t ==========
    "%GODOT%" --headless --path "%PROJ%." --script "res://tests/%%t.gd"
    if errorlevel 1 set "FAILED=1"
)

echo.
if "%FAILED%"=="1" (
    echo ===== SOME TESTS FAILED - scroll up for [FAIL] =====
) else (
    echo ===== ALL GREEN =====
)
pause
