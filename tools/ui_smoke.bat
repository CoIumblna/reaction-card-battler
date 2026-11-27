@echo off
REM ui_smoke.bat -- M4 UI smoke runner (pure ASCII; CRLF; no BOM).
REM Runs tests/ui_*_test.gd (main) and tests/pending/ui_*_test.gd (pending),
REM one by one, aggregates verdicts; any [FAIL]/[HUNG]/[SCRIPT ERROR] -> exit 1.
setlocal EnableDelayedExpansion
chcp 65001 >nul

set "PROJ=%~dp0.."
set "GODOT=%GODOT%"
if "%GODOT%"=="" (
  echo [ui_smoke] GODOT env not set. Set it first:
  echo   $env:GODOT="G:\constraction\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
  exit /b 2
)
if not exist "%PROJ%\logs" mkdir "%PROJ%\logs"
set "OUTDIR=%PROJ%\logs\ui_smoke"
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

set /a TOTAL=0
set /a FAILED=0
set /a REDLIST=0

echo ===== UI SMOKE =====

call :run_dir "%PROJ%\tests\ui_*_test.gd" "main"
call :run_dir "%PROJ%\tests\pending\ui_*_test.gd" "pending"

echo ===== SUMMARY =====
echo total=%TOTAL% failed=%FAILED%
if %FAILED% GTR 0 (
  echo ===== UI SMOKE RED =====
  exit /b 1
)
echo ===== UI SMOKE GREEN =====
exit /b 0

:run_dir
set "PATTERN=%~1"
set "TAG=%~2"
for %%F in (%PATTERN%) do (
  set /a TOTAL+=1
  call :run_one "%%~fF" "%%~nF" "%TAG%"
)
exit /b 0

:run_one
set "SCRIPT=%~1"
set "NAME=%~2"
set "TAG=%~3"
set "LOG=%OUTDIR%\%TAG%_%NAME%.log"
echo [RUN    ] %TAG% %NAME%
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Console]::OutputEncoding=[Text.Encoding]::UTF8;" ^
  "$sec=90;" ^
  "$p=Start-Process -FilePath '%GODOT%' -ArgumentList '--headless','--path','%PROJ%.','--script','%SCRIPT%' -RedirectStandardOutput '%LOG%' -RedirectStandardError '%LOG%.err' -PassThru -NoNewWindow;" ^
  "if(-not $p.WaitForExit($sec*1000)){ try{$p.Kill()}catch{}; $p.WaitForExit(); Start-Sleep -Milliseconds 300;" ^
  "[IO.File]::AppendAllText('%LOG%','`n[HUNG] ui_smoke killed after 90s',(New-Object Text.UTF8Encoding $false)); exit 3 }" ^
  "exit $p.ExitCode"
set "RC=%errorlevel%"
type "%LOG%" 2>nul | findstr /C:"[ok]" >nul
if "%RC%"=="0" if not exist "%LOG%.err.broken" (
  findstr /C:"[FAIL]" "%LOG%" >nul && set "RC=1"
  findstr /C:"SCRIPT ERROR" "%LOG%" >nul && set "RC=1"
  findstr /C:"SCRIPT ERROR" "%LOG%.err" >nul 2>nul && set "RC=1"
  findstr /C:"[HUNG]" "%LOG%" >nul && set "RC=1"
)
if "%RC%"=="0" (
  echo [PASS   ] %TAG% %NAME%
) else if "%RC%"=="3" (
  echo [HUNG   ] %TAG% %NAME%  killed on timeout -- no verdict
  set /a FAILED+=1
  set "RL_%REDLIST%=%NAME% [HUNG]" & set /a REDLIST+=1
) else (
  echo [FAIL   ] %TAG% %NAME%  see %LOG%
  set /a FAILED+=1
  set "RL_%REDLIST%=%NAME%" & set /a REDLIST+=1
)
exit /b 0
