@echo off
rem ============================================================
rem start_server.bat - run the web game LOCALLY (fully offline).
rem Needs NO Python: it prefers Python if present, otherwise it
rem falls back to a tiny PowerShell/.NET server (always there on
rem Windows). Server starts first, browser opens after 1 second.
rem NOTE: do NOT open index.html directly (browsers block file://
rem asset loading). Always use this server.
rem ============================================================
cd /d "%~dp0\.."

rem ---- 1) prefer Python if it can run http.server ----
set "PY="
py -3 -c "import http.server" >nul 2>&1 && set "PY=py -3"
if not defined PY python -c "import http.server" >nul 2>&1 && set "PY=python"
if not defined PY python3 -c "import http.server" >nul 2>&1 && set "PY=python3"

rem ---- open the browser after the server is up ----
start "" cmd /c "timeout /t 1 >nul & start "" http://localhost:8090/build/webgl/"

if defined PY (
    echo  Server: Python (%PY%)
    %PY% -m http.server 8090
) else (
    rem ---- 2) fallback: PowerShell/.NET server - NO Python needed ----
    echo  Server: PowerShell (no Python found - using built-in .NET server)
    powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Port 8090
)
pause
