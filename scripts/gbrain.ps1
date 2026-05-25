[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('Source')]
    [string] $SourceId,

    [int] $ReadCommandTimeoutSeconds = 10,

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

function Clear-StalePgliteLock {
    if (-not $env:GBRAIN_HOME) {
        return
    }

    $lockDir = Join-Path $env:GBRAIN_HOME '.gbrain\brain.pglite\.gbrain-lock'
    $lockFile = Join-Path $lockDir 'lock'
    if (-not (Test-Path -LiteralPath $lockFile)) {
        return
    }

    try {
        $lock = Get-Content -Raw -LiteralPath $lockFile | ConvertFrom-Json
        $lockPid = [int]$lock.pid
    } catch {
        Write-Err "WARN [gbrain] PGLite lock file is unreadable; leaving it in place: $lockFile"
        return
    }

    if ($lockPid -gt 0 -and (Get-Process -Id $lockPid -ErrorAction SilentlyContinue)) {
        return
    }

    try {
        $resolvedHome = (Resolve-Path -LiteralPath $env:GBRAIN_HOME).Path
        $resolvedLock = (Resolve-Path -LiteralPath $lockDir).Path
        if (-not $resolvedLock.StartsWith($resolvedHome, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Err "WARN [gbrain] Refusing to remove lock outside GBRAIN_HOME: $resolvedLock"
            return
        }

        Remove-Item -LiteralPath $resolvedLock -Recurse -Force
        Write-Err "WARN [gbrain] Removed stale PGLite lock for dead PID $lockPid."
    } catch {
        Write-Err "WARN [gbrain] Could not remove stale PGLite lock: $($_.Exception.Message)"
    }
}

function Invoke-BunCaptured {
    param(
        [Parameter(Mandatory = $true)]
        [string] $BunPath,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments,

        [Parameter(Mandatory = $true)]
        [int] $TimeoutSeconds
    )

    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ("diaverse-gbrain-stdout-{0}.txt" -f ([guid]::NewGuid()))
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ("diaverse-gbrain-stderr-{0}.txt" -f ([guid]::NewGuid()))

    try {
        $processArguments = @($Arguments | ForEach-Object {
            if ($_ -match '[\s"]') {
                '"' + ($_.Replace('\', '\\').Replace('"', '\"')) + '"'
            } else {
                $_
            }
        })

        $process = Start-Process -FilePath $BunPath -ArgumentList $processArguments -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
        $completed = Wait-Process -Id $process.Id -Timeout $TimeoutSeconds -ErrorAction SilentlyContinue

        $stdout = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -Raw -LiteralPath $stdoutPath -ErrorAction SilentlyContinue } else { '' }
        $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath -ErrorAction SilentlyContinue } else { '' }

        if (-not $completed -and -not $process.HasExited) {
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            if ($stdout) {
                [Console]::Out.Write($stdout)
                if ($stderr) {
                    [Console]::Error.Write($stderr)
                }
                Write-Err "WARN [gbrain] Native search produced output but did not exit; killed PID $($process.Id) after $TimeoutSeconds seconds."
                return 0
            }

            if ($stderr) {
                [Console]::Error.Write($stderr)
            }
            Write-Err "ERROR [gbrain] Native search timed out after $TimeoutSeconds seconds without output."
            return 124
        }

        if ($stdout) {
            [Console]::Out.Write($stdout)
        }
        if ($stderr) {
            [Console]::Error.Write($stderr)
        }
        return $process.ExitCode
    } finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
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

if ($SourceId) {
    $env:GBRAIN_SOURCE = $SourceId
} elseif ($env:DIAVERSE_GBRAIN_SOURCE) {
    $env:GBRAIN_SOURCE = $env:DIAVERSE_GBRAIN_SOURCE
}

Clear-StalePgliteLock

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
    if ($GBrainArgs.Count -gt 0 -and $GBrainArgs[0] -eq 'search') {
        $exitCode = Invoke-BunCaptured -BunPath $BunPath -Arguments (@('run', 'src/cli.ts') + $GBrainArgs) -TimeoutSeconds $ReadCommandTimeoutSeconds
        exit $exitCode
    }

    & $BunPath run src/cli.ts @GBrainArgs
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
