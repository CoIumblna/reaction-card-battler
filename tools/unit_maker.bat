@echo off
REM Unit card maker (graphical).
REM   Double-click this file to open the window.
REM   Headless-ish self check (renders one frame, saves a PNG, quits):
REM       tools\unit_maker.bat --shot=G:\tmp\maker.png
REM   Engine path: uses env var GODOT if set, else a relative default.
REM NOTE: keep this file ASCII-only + CRLF (tools/preflight.ps1 checks it).
setlocal
chcp 65001 >nul

for %%I in ("%~dp0..") do set "PROJ=%%~fI"

if defined GODOT (
  set "EXE=%GODOT%"
) else (
  set "EXE=%~dp0..\..\..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
)

if not exist "%EXE%" (
  echo [ERROR] Godot engine not found: %EXE%
  echo         Set the GODOT environment variable to the engine executable.
  pause
  exit /b 1
)

"%EXE%" --path "%PROJ%" tools/unit_maker.tscn --resolution 1240x800 -- %*
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
  echo [ERROR] exit code %RC%
  pause
)
exit /b %RC%
