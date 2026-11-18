# =====================================================================
# git_commit.ps1 — one-click commit + push with an auto message.
# Double-click git_commit.bat (this script runs automatically):
#   1. stages every change (build/ and *.exe are already git-ignored)
#   2. builds an automatic message like GitHub Desktop's
#      ("Update battle.v; Create assets/back/Layer.png")
#   3. commits and pushes to the current branch — no typing needed.
# Usage:  powershell -ExecutionPolicy Bypass -File git_commit.ps1 [-DryRun]
# =====================================================================
param([switch]$DryRun)
Set-Location $PSScriptRoot

# ---- 1. read changes BEFORE staging (porcelain codes: ' M' modified, '??' new) ----
$before = git status --porcelain
if (-not $before) {
    Write-Host 'Nothing to commit - working tree clean.'
    exit 0
}
$mods = @($before | Where-Object { $_ -match '^\sM ' } | ForEach-Object { $_.Substring(3) })
$news = @($before | Where-Object { $_ -match '^\?\?' } | ForEach-Object { $_.Substring(3) })
$parts = @()
if ($mods.Count -gt 0) {
    $names = $mods | ForEach-Object { [System.IO.Path]::GetFileName($_) }
    $parts += 'Update ' + ($names -join ', ')
}
if ($news.Count -gt 0) {
    $names = $news | ForEach-Object { [System.IO.Path]::GetFileName($_) }
    $parts += 'Create ' + ($names -join ', ')
}
$msg = $parts -join '; '
if ($msg.Length -gt 180) { $msg = $msg.Substring(0, 180) }

Write-Host "Auto message: $msg"
if ($DryRun) {
    Write-Host 'DRY RUN - nothing committed.'
    exit 0
}

# ---- 2. stage everything ----
git add -A 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host 'git add FAILED.'; exit $LASTEXITCODE }

# ---- 3. commit ----
git commit -m $msg
if ($LASTEXITCODE -ne 0) { Write-Host 'Commit FAILED.'; exit $LASTEXITCODE }
Write-Host "Committed: $msg"

# ---- 4. push (uses the saved Windows credential, no prompt) ----
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'auto'
git -c credential.helper=manager push origin HEAD
if ($LASTEXITCODE -ne 0) { Write-Host 'Push FAILED.'; exit $LASTEXITCODE }
Write-Host 'Pushed to origin.'
