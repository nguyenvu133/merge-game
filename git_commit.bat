@echo off
rem ============================================================
rem git_commit.bat - one-click commit + push with auto message.
rem Double-click this file: it stages, writes the message for
rem you (like GitHub Desktop), commits and pushes. No typing.
rem ============================================================
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0git_commit.ps1"
echo.
pause
