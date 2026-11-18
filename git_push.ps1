# =====================================================================
# git_push.ps1 — push the current branch to GitHub (uses the saved
# Windows credential, no prompt). Run ONLY when you want to upload.
# =====================================================================
Set-Location $PSScriptRoot

# nothing to push if there is no commit ahead
$ahead = git rev-list --count "@{u}..HEAD" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'This branch has no upstream yet - pushing with -u origin HEAD.'
}

$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'auto'
git -c credential.helper=manager push origin HEAD
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Push FAILED.'
    exit $LASTEXITCODE
}
Write-Host 'Pushed to origin.'
