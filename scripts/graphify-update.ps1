param()

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $workspaceRoot '.tools\graphify\.venv\Scripts\python.exe'
$helperScript = Join-Path $workspaceRoot 'scripts\graphify-rebuild.py'

Write-Host "INFO [graphify] Workspace root: $workspaceRoot"
Write-Host "INFO [graphify] Python executable: $pythonExe"
Write-Host "INFO [graphify] Helper script: $helperScript"

if (-not (Test-Path $pythonExe)) {
    Write-Error "WARN [graphify] Graphify runtime is missing. Expected: $pythonExe"
}

if (-not (Test-Path $helperScript)) {
    Write-Error "WARN [graphify] Helper script is missing. Expected: $helperScript"
}

Push-Location $workspaceRoot
try {
    Write-Host "DEBUG [graphify] Starting incremental graph refresh with HTML cap override"
    & $pythonExe $helperScript --workspace-root $workspaceRoot --mode update
    if ($LASTEXITCODE -ne 0) {
        throw "Graphify incremental update failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
