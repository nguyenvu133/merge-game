# ============================================================
# commit_auto.ps1 — stage everything + commit with an AUTO message,
# ready to push from GitHub Desktop (or `git push`).
# Usage:  powershell -ExecutionPolicy Bypass -File commit_auto.ps1
# The message is built from what changed, so you never have to
# type one. It falls back to a timestamped message.
# ============================================================
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

# ---- stage everything ----
git add -A
if ($LASTEXITCODE -ne 0) { Write-Host 'git add failed' -ForegroundColor Red; exit 1 }

# ---- build an automatic message from the changed files ----
$changed = git diff --cached --name-only
$count = @($changed).Count
if ($count -eq 0) { Write-Host 'Nothing to commit.' -ForegroundColor Yellow; exit 0 }

$parts = @()
foreach ($f in $changed) {
    $leaf = Split-Path $f -Leaf
    if ($leaf -match '^game\.v') { $parts += 'web build' }
    elseif ($leaf -eq 'merge-game.exe') { $parts += 'desktop build' }
    elseif ($f -match '^assets/monsters/') { $parts += 'monster art' }
    elseif ($f -match '^assets/data/') { $parts += 'game data' }
    elseif ($f -match '\.v$') { $parts += ($f -replace '\.v$','') }
    elseif ($f -match '\.kine$') { $parts += 'kine rig' }
    elseif ($f -match '^web/plugins') { $parts += 'web plugin' }
    elseif ($f -match '\.ps1$') { $parts += 'build script' }
    elseif ($f -match '\.py$') { $parts += 'tool' }
}
$topic = ($parts | Select-Object -Unique) -join ', '
if ($topic -eq '') { $topic = 'update' }

$stamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$msg = "auto: $topic ($count files) - $stamp"

# ---- commit ----
git commit -m $msg
if ($LASTEXITCODE -ne 0) { Write-Host 'commit failed' -ForegroundColor Red; exit 1 }

Write-Host ''
Write-Host "Committed: $msg" -ForegroundColor Green
Write-Host 'Now push:'
Write-Host '  - GitHub Desktop: click "Push origin" at the top'
Write-Host '  - or command line: git push' -ForegroundColor Cyan
