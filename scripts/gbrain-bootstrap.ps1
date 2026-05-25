[CmdletBinding()]
param(
    [switch] $ForceLocal,
    [switch] $Update
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

function Find-Bun {
    $cmd = Get-Command bun -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    $candidate = Join-Path $env:USERPROFILE '.bun\bin\bun.exe'
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    return $null
}

function Invoke-Checked {
    param(
        [string] $FilePath,
        [string[]] $Arguments,
        [string] $WorkingDirectory
    )

    if ($WorkingDirectory) {
        Push-Location $WorkingDirectory
    }

    try {
        & $FilePath @Arguments
        $code = $LASTEXITCODE
        if ($code -ne 0) {
            throw "Command failed with exit code $code`: $FilePath $($Arguments -join ' ')"
        }
    } finally {
        if ($WorkingDirectory) {
            Pop-Location
        }
    }
}

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$ToolsRoot = Join-Path $WorkspaceRoot '.tools\gbrain'
$LocalRepo = Join-Path $ToolsRoot 'repo'
$Wrapper = Join-Path $PSScriptRoot 'gbrain.ps1'

$resolvedWorkspace = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
if (Test-Path -LiteralPath $ToolsRoot) {
    $resolvedTools = (Resolve-Path -LiteralPath $ToolsRoot).Path
    if (-not $resolvedTools.StartsWith($resolvedWorkspace, [StringComparison]::OrdinalIgnoreCase)) {
        Log-ErrorLine "Resolved tools path is outside the workspace: $resolvedTools"
        exit 1
    }
}

$BunPath = Find-Bun
if (-not $BunPath) {
    Log-ErrorLine 'Bun is required for GBrain. Install Bun, then re-run this script.'
    exit 1
}
Log-Info "Bun detected at $BunPath"

if (-not $ForceLocal) {
    $GlobalCommand = Get-Command gbrain -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($GlobalCommand) {
        Log-Info "GBrain command detected at $($GlobalCommand.Source)"
        Invoke-Checked -FilePath 'powershell' -Arguments @('-ExecutionPolicy', 'Bypass', '-File', $Wrapper, '--version') -WorkingDirectory $WorkspaceRoot
        Log-Info 'Using existing GBrain command through the workspace wrapper.'
        exit 0
    }
}

Log-Warn 'GBrain command is unavailable globally; preparing local clone under .tools\gbrain\repo.'
New-Item -ItemType Directory -Path $ToolsRoot -Force | Out-Null

if (Test-Path -LiteralPath $LocalRepo) {
    if (-not (Test-Path -LiteralPath (Join-Path $LocalRepo '.git'))) {
        Log-ErrorLine "Local GBrain path exists but is not a git repository: $LocalRepo"
        exit 1
    }

    Log-Info "Local GBrain repository already exists at $LocalRepo"
    if ($Update) {
        Log-Info 'Updating local GBrain clone from origin.'
        Invoke-Checked -FilePath 'git' -Arguments @('-C', $LocalRepo, 'pull', '--ff-only') -WorkingDirectory $WorkspaceRoot
    }
} else {
    Log-Info 'Cloning garrytan/gbrain with depth 1.'
    Invoke-Checked -FilePath 'git' -Arguments @('clone', '--depth', '1', 'https://github.com/garrytan/gbrain.git', $LocalRepo) -WorkingDirectory $WorkspaceRoot
}

Log-Info 'Installing local GBrain dependencies with Bun scripts disabled.'
Invoke-Checked -FilePath $BunPath -Arguments @('install', '--ignore-scripts') -WorkingDirectory $LocalRepo

Log-Info 'Verifying GBrain wrapper.'
Invoke-Checked -FilePath 'powershell' -Arguments @('-ExecutionPolicy', 'Bypass', '-File', $Wrapper, '--version') -WorkingDirectory $WorkspaceRoot

Log-Info 'Bootstrap complete. No public HTTP service or background daemon was installed.'
