# ============================================================
# build_desktop.ps1 - desktop build (game data is a const — no
# the game's global vars): sync to clean path, `velo build
# desktop --debug -enable-globals`, copy build/desktop back.
# ============================================================
$ErrorActionPreference = 'Stop'
# velo toolchain: use it from PATH when available, else the default install dir
if (-not (Get-Command velo -ErrorAction SilentlyContinue)) {
    if (Test-Path 'C:\v') { $env:Path = 'C:\v;C:\mingw64\bin;' + $env:Path }
}
$env:VFLAGS = '-cc gcc'
$proj = Split-Path -Parent $MyInvocation.MyCommand.Path
# clean build dir: prefer the default C:\velo (fast local disk); any machine without
# it (e.g. a fresh GitHub clone) falls back to a per-user temp dir
$veloRoot = if (Test-Path 'C:\velo') { 'C:\velo' } else { Join-Path $env:TEMP 'velo' }
$clean = Join-Path $veloRoot 'mergeweb'

Write-Host '== sync project to clean path =='
if (Test-Path $clean) { Remove-Item $clean -Recurse -Force }
Copy-Item $proj $clean -Recurse -Exclude build

Write-Host '== build desktop =='
Push-Location $clean
velo build desktop --debug
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) { Write-Host 'BUILD FAILED'; exit $code }

Write-Host '== copy result back =='
$dst = Join-Path $proj 'build\desktop'
if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item (Join-Path $clean 'build\desktop\*') $dst -Recurse -Force

$exe = Get-ChildItem $dst -Recurse -Filter '*.exe' | Select-Object -First 1
if ($exe) {
    # the output folder/exe take the CLEAN DIR name (mergeweb) — rename to the app name
    $srcDir = $exe.DirectoryName
    $appDir = Join-Path $dst 'merge-game'
    if (Test-Path $appDir) { Remove-Item $appDir -Recurse -Force }
    if ((Split-Path $srcDir -Leaf) -ne 'merge-game') {
        Rename-Item -Path $srcDir -NewName 'merge-game' -ErrorAction SilentlyContinue
    }
    # re-resolve after the folder rename
    if (Test-Path $appDir) {
        $exe = Get-ChildItem $appDir -Filter '*.exe' | Select-Object -First 1
        if ($exe -and (Split-Path $exe.FullName -Leaf) -ne 'merge-game.exe') {
            Rename-Item -Path $exe.FullName -NewName 'merge-game.exe' -ErrorAction SilentlyContinue
        }
        Write-Host "OK - desktop build at $appDir\merge-game.exe"
    } else {
        Write-Host 'WARN - folder rename failed; exe still at:' $exe.FullName
    }
}
else { Write-Host 'WARN - no exe found in desktop build output' }
