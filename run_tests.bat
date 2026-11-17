@echo off
chcp 65001 >nul
setlocal
REM If Godot moved, change the next line only.
set "GODOT=C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "PROJ=%~dp0"
set "OUTDIR=%TEMP%\whk_tests"
set "FAILED=0"

REM Exit code 0 is NOT enough: a swallowed SCRIPT ERROR still prints PASS.
REM Require: (1) "PASS" printed (2) no "[FAIL]" (3) no "SCRIPT ERROR".
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [import] importing project...
"%GODOT%" --headless --path "%PROJ%." --import > "%OUTDIR%\import.log" 2>&1
findstr /C:"SCRIPT ERROR" "%OUTDIR%\import.log" >nul
if not errorlevel 1 set "FAILED=1"

for %%t in (data_test unit_test damage_test board_test battle_m1_smoke_test battle_m2_test combat_test) do (
    echo.
    echo ========== %%t ==========
    "%GODOT%" --headless --path "%PROJ%." --script "res://tests/%%t.gd" > "%OUTDIR%\%%t.log" 2>&1
    if errorlevel 1 set "FAILED=1"
    type "%OUTDIR%\%%t.log"
    findstr /C:"PASS" "%OUTDIR%\%%t.log" >nul
    if errorlevel 1 set "FAILED=1"
    findstr /C:"[FAIL]" "%OUTDIR%\%%t.log" >nul
    if not errorlevel 1 set "FAILED=1"
    findstr /C:"SCRIPT ERROR" "%OUTDIR%\%%t.log" >nul
    if not errorlevel 1 set "FAILED=1"
)

echo.
if "%FAILED%"=="1" (
    echo ===== SOME TESTS FAILED =====  see the [FAIL] lines above; full logs in "%OUTDIR%"
) else (
    echo ===== ALL GREEN =====
)
pause
exit /b %FAILED%
