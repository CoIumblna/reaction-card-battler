@echo off
chcp 65001 >nul
setlocal
REM If Godot moved, change the next line only.
set "GODOT=C:\Users\LD\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
set "PROJ=%~dp0"
set "OUTDIR=%TEMP%\whk_tests"
set "FAILED=0"

REM Auto-discovers tests\*_test.gd -- adding a new test file needs no edit here.
REM tests\pending\ is NOT picked up (only the tests\ top level is scanned).
REM Exit code 0 is NOT enough: a swallowed SCRIPT ERROR still prints PASS,
REM so every file must also print PASS and must not contain [FAIL] / SCRIPT ERROR.
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo [import] importing project...
"%GODOT%" --headless --path "%PROJ%." --import > "%OUTDIR%\import.log" 2>&1
findstr /C:"SCRIPT ERROR" "%OUTDIR%\import.log" >nul
if not errorlevel 1 set "FAILED=1"

for %%f in ("%PROJ%tests\*_test.gd") do call :run_one "%%~nf"
goto :summary

:run_one
set "T=%~1"
echo.
echo ========== %T% ==========
"%GODOT%" --headless --path "%PROJ%." --script "res://tests/%T%.gd" > "%OUTDIR%\%T%.log" 2>&1
if errorlevel 1 set "FAILED=1"
type "%OUTDIR%\%T%.log"
findstr /C:"PASS" "%OUTDIR%\%T%.log" >nul
if errorlevel 1 set "FAILED=1"
findstr /C:"[FAIL]" "%OUTDIR%\%T%.log" >nul
if not errorlevel 1 set "FAILED=1"
findstr /C:"SCRIPT ERROR" "%OUTDIR%\%T%.log" >nul
if not errorlevel 1 set "FAILED=1"
goto :eof

:summary
echo.
if "%FAILED%"=="1" (
    echo ===== SOME TESTS FAILED =====  see the [FAIL] lines above; full logs in "%OUTDIR%"
) else (
    echo ===== ALL GREEN =====
)
pause
exit /b %FAILED%
