@echo off
rem ============================================================
rem git_commit.bat - one-click COMMIT with auto message (NO push).
rem Double-click this file: it stages, writes the message for
rem you (like GitHub Desktop), and commits. It does NOT upload.
rem When you want to upload, run git_push.bat.
rem ============================================================
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0git_commit.ps1"
echo.
pause
