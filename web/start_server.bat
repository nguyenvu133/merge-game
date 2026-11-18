@echo off
chcp 65001 >nul
rem ============================================================
rem start_server.bat - run the web game LOCALLY (no internet).
rem Double-click this file: it starts the server first, waits a
rem moment, then opens the browser. Works with python / py / python3.
rem NOTE: do NOT open index.html directly (browsers block file://
rem asset loading). Always use this server.
rem ============================================================
cd /d "%~dp0\.."

rem ---- find a Python that can run http.server ----
set "PY="
py -3 -c "import http.server" >nul 2>&1 && set "PY=py -3"
if not defined PY python -c "import http.server" >nul 2>&1 && set "PY=python"
if not defined PY python3 -c "import http.server" >nul 2>&1 && set "PY=python3"
if not defined PY (
    echo.
    echo  ERROR: Python not found. Install Python 3 from python.org
    echo  and tick "Add Python to PATH", then run this again.
    echo.
    pause
    exit /b 1
)

echo.
echo  Starting local server on http://localhost:8090/build/webgl/
echo  (press Ctrl+C in this window to stop)
echo.
start "" cmd /c "timeout /t 1 >nul & start "" http://localhost:8090/build/webgl/"
%PY% -m http.server 8090
pause
