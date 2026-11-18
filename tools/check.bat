@echo off
chcp 65001 >nul
REM Acceptance tool: runs the whole suite, prints a progress table and task checkpoints.
REM Actual logic lives in check.ps1 (UTF-8, Chinese output).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check.ps1" %*
echo.
pause
