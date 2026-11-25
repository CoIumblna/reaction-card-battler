@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
REM Godot path: env GODOT first, else relative-to-repo default (portable).
if not defined GODOT set "GODOT=%~dp0..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
if not exist "%GODOT%" (
    echo [ERROR] Godot not found: %GODOT%
    echo         set env GODOT to Godot console exe, or edit this file line 4.
    exit /b 2
)
set "PROJ=%~dp0"
set "OUTDIR=%TEMP%\whk_tests"
if not exist "%OUTDIR%" mkdir "%OUTDIR%" 2>nul
if not exist "%OUTDIR%" set "OUTDIR=%PROJ%_test_logs"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"
set "FAILED=0"
set "PASSED_FILES=0"
set "FAILED_FILES=0"

REM ============================================================================
REM PART 1 -- main suite (tests\*_test.gd, auto-discovered)
REM tests\pending\ is NOT picked up here (only the tests\ top level is scanned).
REM
REM Exit code 0 is NOT enough: a swallowed SCRIPT ERROR still prints PASS,
REM so every file must also print PASS and must not contain [FAIL] / SCRIPT ERROR.
REM
REM QUIET MODE:
REM   PASS file -> one line only:       [PASS] board_test  38 checks
REM   FAIL file -> whole log dumped:    every [ok]/[FAIL]/SCRIPT ERROR line
REM So a green run is ~11 lines and you can see the whole thing at a glance;
REM when something breaks you get the complete output of the broken file.
REM Full logs of every file always stay in %OUTDIR% for later digging.
REM ============================================================================

echo.
echo ################ PART 1  main suite (tests\*_test.gd) ################
echo [import] importing project...
"%GODOT%" --headless --path "%PROJ%." --import > "%OUTDIR%\import.log" 2>&1
findstr /C:"SCRIPT ERROR" "%OUTDIR%\import.log" >nul
if not errorlevel 1 (
    set "FAILED=1"
    echo.
    echo   [FAIL] import -- SCRIPT ERROR while importing, full log:
    type "%OUTDIR%\import.log"
)

for %%f in ("%PROJ%tests\*_test.gd") do call :run_one "%%~nf"
goto :preflight

:run_one
set "T=%~1"
set "LOG=%OUTDIR%\%T%.log"
"%GODOT%" --headless --path "%PROJ%." --script "res://tests/%T%.gd" > "%LOG%" 2>&1
set "BAD=0"
if errorlevel 1 set "BAD=1"
findstr /C:"PASS" "%LOG%" >nul
if errorlevel 1 set "BAD=1"
findstr /C:"[FAIL]" "%LOG%" >nul
if not errorlevel 1 set "BAD=1"
findstr /C:"SCRIPT ERROR" "%LOG%" >nul
if not errorlevel 1 set "BAD=1"
if "%BAD%"=="1" (
    set /a FAILED_FILES+=1
    set "FAILED=1"
    echo.
    echo ========== %T%  ^<^< FAILED  ==========
    type "%LOG%"
    echo ---------- end of %T% ----------
) else (
    set /a PASSED_FILES+=1
    echo   [PASS] %T%
)
goto :eof

REM ============================================================================
REM PART 2 -- detailed preflight (everything PART 1 does not cover)
REM   tests\pending baseline / validate_data / has_acted residue /
REM   EXPECTED_CHECKS / unit_class coverage / balance smoke /
REM   script encoding / workspace noise
REM Logic lives in tools\preflight.ps1 so both humans and agents run the same thing.
REM It uses the same quiet rule: green checks are silent, only failures explain.
REM ============================================================================

:preflight
echo.
echo ################ PART 2  detailed preflight (tools\preflight) ################
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJ%tools\preflight.ps1" -Godot "%GODOT%" -ProjectRoot "%PROJ%."
if errorlevel 1 set "FAILED=1"

:summary
echo.
if "%FAILED%"=="1" (
    echo ===== SOME TESTS FAILED =====  %FAILED_FILES% file^(s^) failed, %PASSED_FILES% passed. Logs: "%OUTDIR%"
) else (
    echo ===== ALL GREEN =====  %PASSED_FILES% file^(s^) passed. Logs: "%OUTDIR%"
)
pause
exit /b %FAILED%
