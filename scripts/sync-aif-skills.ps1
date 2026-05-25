param()

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $workspaceRoot 'diaweb\.agents\skills'
$targetRoot = Join-Path $workspaceRoot '.codex\skills'

Write-Host "INFO [skills] Workspace root: $workspaceRoot"
Write-Host "INFO [skills] Source skills: $sourceRoot"
Write-Host "INFO [skills] Target skills: $targetRoot"

if (-not (Test-Path $sourceRoot)) {
    Write-Error "WARN [skills] Source skills directory not found: $sourceRoot"
}

New-Item -ItemType Directory -Force $targetRoot | Out-Null

$existing = Get-ChildItem -Force $targetRoot -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "DEBUG [skills] Clearing old target skills before sync"
    $existing | Remove-Item -Recurse -Force
}

Copy-Item (Join-Path $sourceRoot '*') $targetRoot -Recurse -Force

$count = (Get-ChildItem -Directory $targetRoot | Measure-Object).Count
Write-Host "INFO [skills] Synced $count skill directories into $targetRoot"
