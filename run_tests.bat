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
set "PEND_RED=0"

REM ============================================================================
REM PART 1 -- main suite (tests\*_test.gd, auto-discovered)
REM tests\pending\ is NOT picked up here (only the tests\ top level is scanned).
REM It is reported by PART 1.5 below, right after this listing, and never fails.
REM
REM Exit code 0 is NOT enough: a swallowed SCRIPT ERROR still prints PASS,
REM so every file must also print PASS and must not contain [FAIL] / SCRIPT ERROR.
REM
REM QUIET MODE:
REM   PASS file -> one line only:       [PASS] board_test
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
goto :pending

REM ============================================================================
REM :run_godot  <res-script>  <logfile>  <timeout-seconds>
REM   Runs one test script with a hard wall-clock limit.
REM
REM   WHY: an infinite loop in a test (or in the code under test) does not
REM   crash Godot -- it prints nothing and never exits, so the whole .bat sits
REM   there forever and CI looks "still running" instead of "failed". A red
REM   baseline you cannot finish is worse than a red baseline.
REM
REM   On timeout the process is killed and the log gets a final line:
REM       [HUNG] godot did not finish within Ns and was killed
REM   so PART 1 / PART 1.5 can report it as a normal failure.
REM ============================================================================
:run_godot
if "%~1"=="" goto :eof
set "RG_SCRIPT=%~1"
set "RG_LOG=%~2"
set "RG_SEC=%~3"
if "%RG_SEC%"=="" set "RG_SEC=90"
del /q "%RG_LOG%" 2>nul
del /q "%RG_LOG%.err" 2>nul
REM On timeout: Kill(), then WAIT for the redirect handles to close before
REM appending the [HUNG] marker. Add-Content right after Kill() fails with
REM "Stream was not readable" because the child still owns the log handle --
REM that error used to be printed as noise above the [HUNG] report. Hence:
REM Dispose + a short settle, then AppendAllText (no handle reuse, UTF-8 no BOM).
powershell -NoProfile -ExecutionPolicy Bypass -Command "$sec=[int]'%RG_SEC%'; $p=Start-Process -FilePath '%GODOT%' -ArgumentList '--headless','--path','%PROJ%.','--script','%RG_SCRIPT%' -RedirectStandardOutput '%RG_LOG%' -RedirectStandardError '%RG_LOG%.err' -PassThru -NoNewWindow; if(-not $p.WaitForExit($sec*1000)){ try{$p.Kill()}catch{}; try{$p.WaitForExit()}catch{}; try{$p.Dispose()}catch{}; Start-Sleep -Milliseconds 300; try{ [IO.File]::AppendAllText('%RG_LOG%', [Environment]::NewLine + '[HUNG] godot did not finish within ' + $sec + 's and was killed' + [Environment]::NewLine, (New-Object Text.UTF8Encoding $false)) }catch{ exit 4 }; exit 3 }; exit $p.ExitCode"
set "RG_RC=%errorlevel%"
if exist "%RG_LOG%.err" (
    for %%s in ("%RG_LOG%.err") do if %%~zs GTR 0 type "%RG_LOG%.err" >> "%RG_LOG%"
)
exit /b %RG_RC%

:run_one
set "T=%~1"
set "LOG=%OUTDIR%\%T%.log"
call :run_godot "res://tests/%T%.gd" "%LOG%" 90
set "BAD=0"
if errorlevel 1 set "BAD=1"
findstr /C:"PASS" "%LOG%" >nul
if errorlevel 1 set "BAD=1"
findstr /C:"[FAIL]" "%LOG%" >nul
if not errorlevel 1 set "BAD=1"
findstr /C:"SCRIPT ERROR" "%LOG%" >nul
if not errorlevel 1 set "BAD=1"
findstr /C:"[HUNG]" "%LOG%" >nul
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
REM PART 1.5 -- pending baseline (tests\pending\*_test.gd)
REM   REPORT ONLY: this part never sets FAILED. A pending test joins the main
REM   suite when the coach moves it into tests\, and that only happens after it
REM   reaches 0 failed on the student's working tree.
REM
REM   [READY  ] = 0 failed + 0 SCRIPT ERROR  ->  move it:  git mv tests/pending/X.gd tests/
REM   [PENDING] = still red                  ->  keep implementing, nothing to move
REM ============================================================================

:pending
set "PEND_TOTAL=0"
for %%f in ("%PROJ%tests\pending\*_test.gd") do set /a PEND_TOTAL+=1
if "%PEND_TOTAL%"=="0" goto :preflight
echo.
echo ############ PART 1.5  pending baseline (tests\pending\*_test.gd) ############
for %%f in ("%PROJ%tests\pending\*_test.gd") do call :pending_one "%%~nf"
goto :preflight

:pending_one
set "T=%~1"
set "PLOG=%OUTDIR%\pending_%T%.log"
REM A pending test is the MOST likely place to hang (that is what the student
REM is mid-implementation on), so it gets a shorter leash than the main suite.
call :run_godot "res://tests/pending/%T%.gd" "%PLOG%" 90
REM Count lines by iterating the matches -- do NOT use "| find /c /v \"\"" here:
REM inside for /f that empty-string arg gets mangled and find hangs on stdin.
set "NCHK=0"
set "NFL=0"
set "NSERR=0"
for /f %%c in ('findstr /C:"[ok]" "%PLOG%"') do set /a NCHK+=1
for /f %%c in ('findstr /C:"[FAIL]" "%PLOG%"') do set /a NFL+=1
for /f %%c in ('findstr /C:"SCRIPT ERROR" "%PLOG%"') do set /a NSERR+=1
set /a NCHK+=NFL
findstr /C:"[HUNG]" "%PLOG%" >nul
if not errorlevel 1 goto :pending_hung
if not "%NFL%"=="0" goto :pending_red
if not "%NSERR%"=="0" goto :pending_red
echo   [READY  ] %T%  %NCHK% checks  --^> git mv tests/pending/%T%.gd tests/
goto :eof

:pending_hung
REM Distinct from a normal red: the run never finished, so "0 failed" means
REM nothing. Report the kill, not a failure count.
set /a PEND_RED+=1
echo   [HUNG   ] %T%  killed on timeout -- infinite loop, no verdict available
echo     ---- last lines before the kill ----
powershell -NoProfile -Command "[Console]::OutputEncoding=[Text.Encoding]::UTF8; Get-Content -LiteralPath '%PLOG%' -Tail 5 -Encoding UTF8"
echo     ---- full log: %PLOG%
goto :eof

:pending_red
set /a PEND_RED+=1
echo   [PENDING] %T%  %NCHK% checks / %NFL% failed / %NSERR% script errors
echo     ---- failed checks: %NFL% ----
findstr /C:"[FAIL]" "%PLOG%"
if not "%NSERR%"=="0" (
    echo     ---- script errors: %NSERR% ----
    findstr /C:"SCRIPT ERROR" "%PLOG%"
)
echo     ---- full log: %PLOG%
goto :eof

REM ============================================================================
REM PART 2 -- detailed preflight (everything PART 1 / 1.5 does not cover)
REM   validate_data / has_acted residue / EXPECTED_CHECKS / unit_class coverage /
REM   balance smoke / script encoding / workspace noise
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
if not "%PEND_RED%"=="0" echo ===== note: %PEND_RED% pending test^(s^) still red -- details above in PART 1.5 =====
if not "%NO_PAUSE%"=="1" pause
exit /b %FAILED%
