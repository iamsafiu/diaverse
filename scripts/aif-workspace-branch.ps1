param(
    [Parameter(Mandatory = $true)]
    [string]$Branch,

    [string[]]$Repos = @('diaweb', 'diaverse-mobile', 'diaverseapi', 'aibot', 'diaverse-content', 'club10000-bot', 'diaverse-auth-bot'),

    [switch]$Create
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$hadError = $false

Write-Host "INFO [aif-workspace] Workspace root: $workspaceRoot"
Write-Host "INFO [aif-workspace] Target branch: $Branch"
Write-Host "INFO [aif-workspace] Target repositories: $($Repos -join ', ')"
Write-Host "INFO [aif-workspace] Create mode: $Create"

foreach ($repo in $Repos) {
    $repoPath = Join-Path $workspaceRoot $repo
    Write-Host ""
    Write-Host "INFO [aif-workspace] Repository: $repo"
    Write-Host "DEBUG [aif-workspace] Path: $repoPath"

    if (-not (Test-Path $repoPath)) {
        Write-Host "WARN [aif-workspace] Missing repository path: $repoPath"
        $hadError = $true
        continue
    }

    $gitDir = Join-Path $repoPath '.git'
    if (-not (Test-Path $gitDir)) {
        Write-Host "WARN [aif-workspace] Not a git repository: $repoPath"
        $hadError = $true
        continue
    }

    $status = git -c "safe.directory=$repoPath" -C $repoPath status --short
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN [aif-workspace] Failed to read status for $repo"
        $hadError = $true
        continue
    }

    if (@($status).Count -gt 0) {
        Write-Host "WARN [aif-workspace] Refusing to switch branches with uncommitted changes in $repo"
        $status | ForEach-Object { Write-Host "  $_" }
        $hadError = $true
        continue
    }

    $existingBranch = git -c "safe.directory=$repoPath" -C $repoPath branch --list $Branch
    if (@($existingBranch).Count -gt 0) {
        Write-Host "INFO [aif-workspace] Branch exists, switching: $Branch"
        git -c "safe.directory=$repoPath" -C $repoPath switch $Branch
    } elseif ($Create) {
        Write-Host "INFO [aif-workspace] Creating branch: $Branch"
        git -c "safe.directory=$repoPath" -C $repoPath switch -c $Branch
    } else {
        Write-Host "WARN [aif-workspace] Branch does not exist and -Create was not provided: $Branch"
        $hadError = $true
        continue
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN [aif-workspace] Branch operation failed for $repo"
        $hadError = $true
        continue
    }

    $current = git -c "safe.directory=$repoPath" -C $repoPath branch --show-current
    Write-Host "INFO [aif-workspace] Current branch: $current"
}

if ($hadError) {
    exit 1
}
