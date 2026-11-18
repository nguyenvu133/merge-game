@echo off
rem ============================================================
rem git_push.bat - push your commits to GitHub (run ONLY when
rem you want to upload). Uses the saved Windows credential,
rem no password prompt.
rem ============================================================
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0git_push.ps1"
echo.
pause
