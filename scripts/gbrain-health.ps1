[CmdletBinding()]
param(
    [switch] $SkipSmokeQueries,
    [switch] $SkipLegacyAudit,
    [switch] $RunSearchSmoke
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Log-Info {
    param([string] $Message)
    Write-Host "INFO [gbrain-health] $Message"
}

function Log-Warn {
    param([string] $Message)
    Write-Warning "WARN [gbrain-health] $Message"
}

function Log-ErrorLine {
    param([string] $Message)
    [Console]::Error.WriteLine("ERROR [gbrain-health] $Message")
}

function Invoke-GBrainCapture {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,
        [switch] $AllowFailure,
        [int] $TimeoutSeconds = 60
    )

    $job = Start-Job -ScriptBlock {
        param(
            [string] $WrapperPath,
            [string[]] $InnerArguments
        )

        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $commandOutput = & powershell -NoProfile -ExecutionPolicy Bypass -File $WrapperPath @InnerArguments 2>&1
            $exitCode = $LASTEXITCODE
        } catch {
            $commandOutput = @($_)
            $exitCode = 1
        } finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        [pscustomobject]@{
            ExitCode = $exitCode
            Output = @($commandOutput | ForEach-Object { $_.ToString() })
        }
    } -ArgumentList $GBrainWrapper, $Arguments

    $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
    if (-not $completed) {
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        $message = "gbrain $($Arguments -join ' ') timed out after $TimeoutSeconds seconds"
        if (-not $AllowFailure) {
            throw $message
        }
        return [pscustomobject]@{
            ExitCode = 124
            Output = @($message)
        }
    }

    $result = Receive-Job -Job $job
    Remove-Job -Job $job -Force
    $code = $result.ExitCode
    $output = @($result.Output)

    if ($code -ne 0 -and -not $AllowFailure) {
        $output | ForEach-Object { [Console]::Error.WriteLine($_) }
        throw "gbrain $($Arguments -join ' ') failed with exit code $code"
    }
    return [pscustomobject]@{
        ExitCode = $code
        Output = @($output)
    }
}

function Assert-TextOutput {
    param(
        [string] $Name,
        [string[]] $Arguments
    )

    $result = Invoke-GBrainCapture -Arguments $Arguments -AllowFailure
    $text = ($result.Output -join "`n").Trim()
    if ($result.ExitCode -ne 0) {
        Log-Warn "$Name failed with exit code $($result.ExitCode)."
        return $false
    }
    if (-not $text -or $text -match 'No .*found|\"count\": 0|count.*0') {
        Log-Warn "$Name returned no useful hits."
        return $false
    }

    Log-Info "$Name returned results."
    return $true
}

$WorkspaceRoot = Split-Path -Parent $PSScriptRoot
$GBrainWrapper = Join-Path $PSScriptRoot 'gbrain.ps1'
$env:GBRAIN_HOME = Join-Path $WorkspaceRoot '.tools\gbrain\home'
$env:GBRAIN_NO_BANNER = '1'

if (-not (Test-Path -LiteralPath $GBrainWrapper)) {
    Log-ErrorLine "Missing wrapper: $GBrainWrapper"
    exit 1
}

$version = Invoke-GBrainCapture -Arguments @('--version')
Log-Info (($version.Output -join ' ').Trim())

$doctor = Invoke-GBrainCapture -Arguments @('doctor', '--fast') -AllowFailure
if ($doctor.ExitCode -eq 0) {
    Log-Info 'doctor --fast passed.'
} else {
    Log-Warn 'doctor --fast reported issues; continuing with required source/smoke checks.'
}

$list = Invoke-GBrainCapture -Arguments @('sources', 'list', '--json')
$json = ($list.Output -join "`n") | ConvertFrom-Json
$sourceIds = @($json.sources | ForEach-Object { $_.id })
$required = @('diaverse-docs', 'diaverse-aif', 'diaweb-code', 'diaverseapi-code', 'aibot-code', 'club10000-bot-code')

foreach ($id in $required) {
    if ($sourceIds -notcontains $id) {
        Log-ErrorLine "Missing required source: $id"
        exit 1
    }
    Log-Info "Source present: $id"
}

if (-not $SkipLegacyAudit) {
    $legacyName = 'gra' + 'phify'
    $mcpPath = Join-Path $WorkspaceRoot '.mcp.json'
    if (Test-Path -LiteralPath $mcpPath) {
        $mcpText = Get-Content -Raw -Path $mcpPath
        if ($mcpText -match ('"' + [regex]::Escape($legacyName) + '"')) {
            Log-ErrorLine 'Legacy knowledge MCP entry is still present in .mcp.json.'
            exit 1
        }
        Log-Info 'No legacy knowledge MCP entry found.'
    } else {
        Log-Info '.mcp.json is absent.'
    }

    $activeLegacyScripts = @(
        "scripts\$legacyName-build.ps1",
        "scripts\$legacyName-update.ps1",
        "scripts\$legacyName-rebuild.py"
    )

    foreach ($path in $activeLegacyScripts) {
        $full = Join-Path $WorkspaceRoot $path
        if (Test-Path -LiteralPath $full) {
            Log-Warn "Legacy knowledge script still present: $path"
        }
    }
}

if (-not $SkipSmokeQueries) {
    $checks = @()
    $checks += Assert-TextOutput -Name 'list diaverse-docs pages' -Arguments @('list', '--source', 'diaverse-docs', '--limit', '5')
    $checks += Assert-TextOutput -Name 'list diaverse-aif pages' -Arguments @('list', '--source', 'diaverse-aif', '--limit', '5')
    $checks += Assert-TextOutput -Name 'code-def CopywritingDailyView' -Arguments @('code-def', 'CopywritingDailyView', '--json')
    $checks += Assert-TextOutput -Name 'code-def TelegramService' -Arguments @('code-def', 'TelegramService', '--json')
    $checks += Assert-TextOutput -Name 'code-refs TelegramService' -Arguments @('code-refs', 'TelegramService', '--json')

    if ($checks -contains $false) {
        Log-ErrorLine 'One or more required GBrain smoke checks failed.'
        exit 1
    }

    if ($RunSearchSmoke) {
        $optionalSearches = @(
            @{ Name = 'search cabinet auth in docs'; Arguments = @('search', 'cabinet auth', '--source', 'diaverse-docs', '--limit', '5') },
            @{ Name = 'search club payment in docs'; Arguments = @('search', 'club payment', '--source', 'diaverse-docs', '--limit', '5') }
        )

        foreach ($check in $optionalSearches) {
            $result = Invoke-GBrainCapture -Arguments $check.Arguments -AllowFailure -TimeoutSeconds 20
            $text = ($result.Output -join "`n").Trim()
            if ($result.ExitCode -eq 0 -and $text -and $text -notmatch 'No .*found|"count": 0|count.*0') {
                Log-Info "$($check.Name) returned results."
            } else {
                Log-Warn "$($check.Name) is optional and did not return usable results."
            }
        }
    } else {
        Log-Warn 'Keyword search smoke is skipped by default because no-embedding GBrain search can hang on this workspace; use -RunSearchSmoke to test it explicitly.'
    }
}

Log-Info 'GBrain health checks completed.'
