[CmdletBinding()]
param(
    [switch] $DryRunOnly,
    [switch] $SkipDryRun,
    [string[]] $SourceId
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Log-Info {
    param([string] $Message)
    Write-Host "INFO [gbrain] $Message"
}

function Log-Warn {
    param([string] $Message)
    Write-Warning "WARN [gbrain] $Message"
}

function Invoke-GBrain {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    & powershell -ExecutionPolicy Bypass -File $GBrainWrapper @Arguments
    $code = $LASTEXITCODE
    if ($code -ne 0 -and -not $AllowFailure) {
        throw "gbrain $($Arguments -join ' ') failed with exit code $code"
    }
}

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$GBrainWrapper = Join-Path $PSScriptRoot 'gbrain.ps1'
$env:GBRAIN_HOME = Join-Path $WorkspaceRoot '.tools\gbrain\home'
$env:GBRAIN_NO_BANNER = '1'

$Sources = @(
    [pscustomobject]@{ Id = 'diaverse-docs'; Path = (Join-Path $WorkspaceRoot 'docs'); Strategy = 'markdown'; Mode = 'import' },
    [pscustomobject]@{ Id = 'diaverse-aif'; Path = (Join-Path $WorkspaceRoot '.ai-factory'); Strategy = 'markdown'; Mode = 'import' },
    [pscustomobject]@{ Id = 'diaweb-code'; Path = (Join-Path $WorkspaceRoot 'diaweb'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'diaverseapi-code'; Path = (Join-Path $WorkspaceRoot 'diaverseapi'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'aibot-code'; Path = (Join-Path $WorkspaceRoot 'aibot'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'club10000-bot-code'; Path = (Join-Path $WorkspaceRoot 'club10000-bot'); Strategy = 'code'; Mode = 'sync' }
)

if ($SourceId -and $SourceId.Count -gt 0) {
    $wanted = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $SourceId) {
        [void]$wanted.Add($id)
    }
    $Sources = @($Sources | Where-Object { $wanted.Contains($_.Id) })
}

if ($Sources.Count -eq 0) {
    Log-Warn 'No matching GBrain sources selected.'
    exit 0
}

$sourceScript = Join-Path $PSScriptRoot 'gbrain-sources.ps1'
powershell -ExecutionPolicy Bypass -File $sourceScript
if ($LASTEXITCODE -ne 0) {
    throw "gbrain-sources.ps1 failed with exit code $LASTEXITCODE"
}

foreach ($source in $Sources) {
    if ($source.Mode -eq 'import') {
        if (-not $SkipDryRun) {
            Log-Info "Dry-run audit for $($source.Id) (strategy=$($source.Strategy), no writes)."
            Invoke-GBrain -Arguments @('sources', 'audit', $source.Id, '--json')
        }

        if (-not $DryRunOnly) {
            Log-Info "Importing $($source.Id) from $($source.Path) (no embeddings)."
            Invoke-GBrain -Arguments @('import', $source.Path, '--source-id', $source.Id, '--no-embed', '--workers', '1', '--fresh', '--json')
        }

        continue
    }

    if (-not $SkipDryRun) {
        Log-Info "Dry-run sync for $($source.Id) (strategy=$($source.Strategy), no embeddings)."
        Invoke-GBrain -Arguments @('sync', '--source', $source.Id, '--strategy', $source.Strategy, '--no-embed', '--dry-run', '--no-pull', '--yes')
    }

    if (-not $DryRunOnly) {
        Log-Info "Syncing $($source.Id) (strategy=$($source.Strategy), no embeddings)."
        Invoke-GBrain -Arguments @('sync', '--source', $source.Id, '--strategy', $source.Strategy, '--no-embed', '--no-pull', '--yes')
    }
}

Log-Info 'GBrain sync completed.'
