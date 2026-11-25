@echo off
chcp 65001 >nul
REM Detailed preflight checks (everything check.bat / run_tests.bat does NOT do).
REM Logic lives in preflight.ps1 (UTF-8 with BOM, Chinese output).
REM Normally you do not call this directly: run_tests.bat calls it at the end.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0preflight.ps1" %*
exit /b %ERRORLEVEL%
