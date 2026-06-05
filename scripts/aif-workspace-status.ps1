param(
    [string[]]$Repos = @('diaweb', 'diaverseapi', 'aibot', 'club10000-bot', 'diaverse-auth-bot')
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot

Write-Host "INFO [aif-workspace] Workspace root: $workspaceRoot"
Write-Host "INFO [aif-workspace] Checking repositories: $($Repos -join ', ')"

foreach ($repo in $Repos) {
    $repoPath = Join-Path $workspaceRoot $repo
    Write-Host ""
    Write-Host "INFO [aif-workspace] Repository: $repo"
    Write-Host "DEBUG [aif-workspace] Path: $repoPath"

    if (-not (Test-Path $repoPath)) {
        Write-Host "WARN [aif-workspace] Missing repository path: $repoPath"
        continue
    }

    $gitDir = Join-Path $repoPath '.git'
    if (-not (Test-Path $gitDir)) {
        Write-Host "WARN [aif-workspace] Not a git repository: $repoPath"
        continue
    }

    $branch = git -c "safe.directory=$repoPath" -C $repoPath branch --show-current
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN [aif-workspace] Failed to read branch for $repo"
        continue
    }

    $status = git -c "safe.directory=$repoPath" -C $repoPath status --short
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN [aif-workspace] Failed to read status for $repo"
        continue
    }

    $changeCount = @($status).Count
    Write-Host "INFO [aif-workspace] Branch: $branch"
    Write-Host "INFO [aif-workspace] Changes: $changeCount"

    if ($changeCount -gt 0) {
        Write-Host "WARN [aif-workspace] Uncommitted changes:"
        $status | ForEach-Object { Write-Host "  $_" }
    } else {
        Write-Host "INFO [aif-workspace] Working tree clean"
    }
}
