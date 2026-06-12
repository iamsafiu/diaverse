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

function New-ImportMirror {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $Source,

        [string[]] $ExcludeDirs = @()
    )

    if (-not $ExcludeDirs -or $ExcludeDirs.Count -eq 0) {
        return $Source.Path
    }

    $mirrorRoot = Join-Path $WorkspaceRoot '.tools\gbrain\tmp\imports'
    $mirrorPath = Join-Path $mirrorRoot $Source.Id
    New-Item -ItemType Directory -Path $mirrorRoot -Force | Out-Null

    $resolvedMirrorRoot = (Resolve-Path -LiteralPath $mirrorRoot).Path
    if (Test-Path -LiteralPath $mirrorPath) {
        $resolvedMirrorPath = (Resolve-Path -LiteralPath $mirrorPath).Path
        if (-not $resolvedMirrorPath.StartsWith($resolvedMirrorRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to remove import mirror outside mirror root: $resolvedMirrorPath"
        }
        Remove-Item -LiteralPath $resolvedMirrorPath -Recurse -Force
    }

    New-Item -ItemType Directory -Path $mirrorPath -Force | Out-Null
    $sourceRoot = (Resolve-Path -LiteralPath $Source.Path).Path.TrimEnd('\', '/')
    $excluded = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($dir in $ExcludeDirs) {
        [void]$excluded.Add($dir)
    }

    Get-ChildItem -LiteralPath $Source.Path -Recurse -File -Force | ForEach-Object {
        $relative = $_.FullName.Substring($sourceRoot.Length).TrimStart('\', '/')
        $segments = @($relative -split '[\\/]')
        $isExcluded = [bool]($segments | Where-Object { $excluded.Contains($_) } | Select-Object -First 1)
        if (-not $isExcluded) {
            $target = Join-Path $mirrorPath $relative
            $targetDir = Split-Path -Parent $target
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }

    return $mirrorPath
}

function Remove-ExcludedPages {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject] $Source
    )

    $prefixes = @()
    if ($Source.PSObject.Properties.Name -contains 'ExcludeSlugPrefixes') {
        $prefixes = @($Source.ExcludeSlugPrefixes)
    }

    if (-not $prefixes -or $prefixes.Count -eq 0) {
        return
    }

    $listOutput = & powershell -ExecutionPolicy Bypass -File $GBrainWrapper list --source $Source.Id --limit 1000 2>$null
    if ($LASTEXITCODE -ne 0) {
        Log-Warn "Could not list pages for excluded slug cleanup in $($Source.Id)."
        return
    }

    $slugs = @()
    foreach ($line in @($listOutput)) {
        $trimmed = $line.ToString().Trim()
        if (-not $trimmed) {
            continue
        }
        $slug = ($trimmed -split '\s+', 2)[0]
        foreach ($prefix in $prefixes) {
            if ($slug.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                $slugs += $slug
                break
            }
        }
    }

    foreach ($slug in ($slugs | Sort-Object -Unique)) {
        Log-Info "Removing excluded GBrain page from $($Source.Id): $slug"
        Invoke-GBrain -Arguments @('delete', $slug, '--source', $Source.Id) -AllowFailure
    }
}

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$GBrainWrapper = Join-Path $PSScriptRoot 'gbrain.ps1'
$env:GBRAIN_HOME = Join-Path $WorkspaceRoot '.tools\gbrain\home'
$env:GBRAIN_NO_BANNER = '1'

$Sources = @(
    [pscustomobject]@{ Id = 'diaverse-docs'; Path = (Join-Path $WorkspaceRoot 'docs'); Strategy = 'markdown'; Mode = 'import'; ExcludeDirs = @('daily'); ExcludeSlugPrefixes = @('daily/') },
    [pscustomobject]@{ Id = 'diaverse-aif'; Path = (Join-Path $WorkspaceRoot '.ai-factory'); Strategy = 'markdown'; Mode = 'import' },
    [pscustomobject]@{ Id = 'diaweb-code'; Path = (Join-Path $WorkspaceRoot 'diaweb'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'diaverse-mobile-code'; Path = (Join-Path $WorkspaceRoot 'diaverse-mobile'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'diaverseapi-code'; Path = (Join-Path $WorkspaceRoot 'diaverseapi'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'aibot-code'; Path = (Join-Path $WorkspaceRoot 'aibot'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'club10000-bot-code'; Path = (Join-Path $WorkspaceRoot 'club10000-bot'); Strategy = 'code'; Mode = 'sync' },
    [pscustomobject]@{ Id = 'diaverse-auth-bot-code'; Path = (Join-Path $WorkspaceRoot 'diaverse-auth-bot'); Strategy = 'code'; Mode = 'sync' }
)

if ($SourceId -and $SourceId.Count -gt 0) {
    $wanted = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $SourceId) {
        foreach ($part in ($id -split ',')) {
            $normalized = $part.Trim()
            if ($normalized) {
                [void]$wanted.Add($normalized)
            }
        }
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
        $excludeDirs = @()
        if ($source.PSObject.Properties.Name -contains 'ExcludeDirs') {
            $excludeDirs = @($source.ExcludeDirs)
        }
        $importPath = New-ImportMirror -Source $source -ExcludeDirs $excludeDirs

        if (-not $SkipDryRun) {
            Log-Info "Dry-run audit for $($source.Id) (strategy=$($source.Strategy), no writes)."
            Invoke-GBrain -Arguments @('sources', 'audit', $source.Id, '--json')
        }

        if (-not $DryRunOnly) {
            Log-Info "Importing $($source.Id) from $importPath (no embeddings)."
            Invoke-GBrain -Arguments @('import', $importPath, '--source-id', $source.Id, '--no-embed', '--workers', '1', '--fresh', '--json')
            Remove-ExcludedPages -Source $source
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
