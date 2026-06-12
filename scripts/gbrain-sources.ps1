[CmdletBinding()]
param(
    [ValidateSet('conservative', 'balanced', 'tokenmax')]
    [string] $SearchMode = 'conservative'
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

function Log-ErrorLine {
    param([string] $Message)
    [Console]::Error.WriteLine("ERROR [gbrain] $Message")
}

function Invoke-GBrain {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = & powershell -ExecutionPolicy Bypass -File $GBrainWrapper @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($code -ne 0 -and -not $AllowFailure) {
        $output | ForEach-Object { [Console]::Error.WriteLine($_) }
        throw "gbrain $($Arguments -join ' ') failed with exit code $code"
    }

    return [pscustomobject]@{
        ExitCode = $code
        Output = @($output)
    }
}

function Get-SourceRegistry {
    $list = Invoke-GBrain -Arguments @('sources', 'list', '--json')
    $text = ($list.Output -join "`n").Trim()
    if (-not $text) {
        return @{}
    }

    $parsed = $text | ConvertFrom-Json
    $map = @{}
    foreach ($source in @($parsed.sources)) {
        $map[$source.id] = $source
    }
    return $map
}

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$GBrainWrapper = Join-Path $PSScriptRoot 'gbrain.ps1'
$GBrainHomeParent = Join-Path $WorkspaceRoot '.tools\gbrain\home'
$GBrainConfig = Join-Path $GBrainHomeParent '.gbrain\config.json'

$env:GBRAIN_HOME = $GBrainHomeParent
$env:GBRAIN_NO_BANNER = '1'
$env:GBRAIN_NO_MODE_SWITCH_UX = '1'

if (-not (Test-Path -LiteralPath $GBrainWrapper)) {
    Log-ErrorLine "Missing wrapper: $GBrainWrapper"
    exit 1
}

if (-not (Test-Path -LiteralPath $GBrainConfig)) {
    Log-Info 'Initializing local PGLite GBrain with embeddings deferred.'
    $init = Invoke-GBrain -Arguments @('init', '--pglite', '--no-embedding', '--json') -AllowFailure
    $initText = $init.Output -join "`n"

    if ($initText -match '\[AGENT\]') {
        $init.Output | ForEach-Object { Write-Host $_ }
        Log-ErrorLine 'GBrain init printed an operator cost matrix. Stop here and choose a search mode before continuing.'
        exit 2
    }

    if ($init.ExitCode -ne 0) {
        $init.Output | ForEach-Object { [Console]::Error.WriteLine($_) }
        Log-ErrorLine "GBrain init failed with exit code $($init.ExitCode)"
        exit $init.ExitCode
    }
} else {
    Log-Info "Existing project-local GBrain config found: $GBrainConfig"
}

Log-Info "Setting search.mode to $SearchMode for cost-safe local defaults."
Invoke-GBrain -Arguments @('config', 'set', 'search.mode', $SearchMode) | Out-Null

$Sources = @(
    [pscustomobject]@{ Id = 'diaverse-docs'; Path = (Join-Path $WorkspaceRoot 'docs'); Name = 'Diaverse Docs'; Federated = $true; Strategy = 'markdown' },
    [pscustomobject]@{ Id = 'diaverse-aif'; Path = (Join-Path $WorkspaceRoot '.ai-factory'); Name = 'Diaverse AI Factory'; Federated = $true; Strategy = 'markdown' },
    [pscustomobject]@{ Id = 'diaweb-code'; Path = (Join-Path $WorkspaceRoot 'diaweb'); Name = 'Diaweb Code'; Federated = $false; Strategy = 'code' },
    [pscustomobject]@{ Id = 'diaverse-mobile-code'; Path = (Join-Path $WorkspaceRoot 'diaverse-mobile'); Name = 'Diaverse Mobile Code'; Federated = $false; Strategy = 'code' },
    [pscustomobject]@{ Id = 'diaverseapi-code'; Path = (Join-Path $WorkspaceRoot 'diaverseapi'); Name = 'Diaverse API Code'; Federated = $false; Strategy = 'code' },
    [pscustomobject]@{ Id = 'aibot-code'; Path = (Join-Path $WorkspaceRoot 'aibot'); Name = 'Aibot Code'; Federated = $false; Strategy = 'code' },
    [pscustomobject]@{ Id = 'club10000-bot-code'; Path = (Join-Path $WorkspaceRoot 'club10000-bot'); Name = 'Club10000 Bot Code'; Federated = $false; Strategy = 'code' },
    [pscustomobject]@{ Id = 'diaverse-auth-bot-code'; Path = (Join-Path $WorkspaceRoot 'diaverse-auth-bot'); Name = 'Diaverse Auth Bot Code'; Federated = $false; Strategy = 'code' }
)

$registry = Get-SourceRegistry

foreach ($source in $Sources) {
    if (-not (Test-Path -LiteralPath $source.Path)) {
        Log-Warn "Source path is missing; skipping $($source.Id): $($source.Path)"
        continue
    }

    $resolvedPath = (Resolve-Path -LiteralPath $source.Path).Path
    if ($registry.ContainsKey($source.Id)) {
        $existing = $registry[$source.Id]
        $existingPath = [string]$existing.local_path
        if ($existingPath -and ((Resolve-Path -LiteralPath $existingPath -ErrorAction SilentlyContinue).Path -ne $resolvedPath)) {
            Log-Warn "Source $($source.Id) already exists with a different path: $existingPath"
        } elseif ([bool]$existing.federated -ne [bool]$source.Federated) {
            Log-Warn "Source $($source.Id) already exists with federated=$($existing.federated), expected $($source.Federated). Leaving it unchanged to avoid GBrain embed-backfill side effects."
        } else {
            Log-Info "Source already registered: $($source.Id) -> $resolvedPath"
        }
    } else {
        $federationFlag = if ($source.Federated) { '--federated' } else { '--no-federated' }
        Log-Info "Registering source $($source.Id) -> $resolvedPath (strategy=$($source.Strategy), federated=$($source.Federated))"
        Invoke-GBrain -Arguments @('sources', 'add', $source.Id, '--path', $resolvedPath, '--name', $source.Name, $federationFlag) | Out-Null
    }
}

Log-Info 'Registered GBrain sources:'
Invoke-GBrain -Arguments @('sources', 'list') | ForEach-Object {
    $_.Output | ForEach-Object { Write-Host $_ }
}
