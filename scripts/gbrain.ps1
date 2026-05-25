[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $GBrainArgs
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Err {
    param([string] $Message)
    [Console]::Error.WriteLine($Message)
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

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$DefaultGBrainHomeParent = Join-Path $WorkspaceRoot '.tools\gbrain\home'

if ($env:DIAVERSE_GBRAIN_HOME) {
    $env:GBRAIN_HOME = $env:DIAVERSE_GBRAIN_HOME
} elseif (-not $env:GBRAIN_HOME) {
    $env:GBRAIN_HOME = $DefaultGBrainHomeParent
}

if (-not (Test-Path -LiteralPath $env:GBRAIN_HOME)) {
    New-Item -ItemType Directory -Path $env:GBRAIN_HOME -Force | Out-Null
}

if (-not $env:GBRAIN_NO_BANNER) {
    $env:GBRAIN_NO_BANNER = '1'
}

$GlobalCommand = Get-Command gbrain -ErrorAction SilentlyContinue | Select-Object -First 1
if ($GlobalCommand) {
    $globalPath = $GlobalCommand.Source
    if ($globalPath -and (Test-Path -LiteralPath $globalPath)) {
        try {
            $resolvedGlobal = (Resolve-Path -LiteralPath $globalPath).Path
            $resolvedSelf = (Resolve-Path -LiteralPath $PSCommandPath).Path
            if ($resolvedGlobal -ne $resolvedSelf) {
                & $globalPath @GBrainArgs
                exit $LASTEXITCODE
            }
        } catch {
            & $globalPath @GBrainArgs
            exit $LASTEXITCODE
        }
    }
}

$LocalRepo = Join-Path $WorkspaceRoot '.tools\gbrain\repo'
$LocalCli = Join-Path $LocalRepo 'src\cli.ts'
if (-not (Test-Path -LiteralPath $LocalCli)) {
    Write-Err "ERROR [gbrain] GBrain CLI is not installed. Run scripts\gbrain-bootstrap.ps1 first."
    exit 127
}

$BunPath = Find-Bun
if (-not $BunPath) {
    Write-Err "ERROR [gbrain] Bun is not installed or not on PATH."
    exit 127
}

Push-Location $LocalRepo
try {
    & $BunPath run src/cli.ts @GBrainArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
