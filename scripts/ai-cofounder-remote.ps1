[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Position = 0)]
    [ValidateSet(
        'status',
        'ps',
        'health',
        'diagnostics',
        'metrics',
        'activity',
        'routines',
        'logs',
        'up',
        'stop',
        'restart',
        'run',
        'deploy-info',
        'tunnel',
        'help'
    )]
    [string] $Command = 'health',

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $CommandArgs,

    [string] $HostName = $env:AI_COFUNDER_SSH_HOST,
    [string] $User = $(if ($env:AI_COFUNDER_SSH_USER) { $env:AI_COFUNDER_SSH_USER } else { 'cofounder-ops' }),
    [string] $IdentityFile = $env:AI_COFUNDER_SSH_KEY,
    [int] $LocalPort = 3737,
    [int] $RemotePort = 3737,
    [switch] $NoBatchMode
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RemoteWrapper = '/usr/local/sbin/diaverse-ai-cofounder-ops'

function Write-Err {
    param([string] $Message)
    [Console]::Error.WriteLine($Message)
}

function Show-Usage {
    @"
Usage:
  scripts\ai-cofounder-remote.ps1 -HostName <host> health
  scripts\ai-cofounder-remote.ps1 -HostName <host> status
  scripts\ai-cofounder-remote.ps1 -HostName <host> logs bridge 200
  scripts\ai-cofounder-remote.ps1 -HostName <host> run <routine-id>
  scripts\ai-cofounder-remote.ps1 -HostName <host> tunnel

Environment alternatives:
  AI_COFUNDER_SSH_HOST=<host>
  AI_COFUNDER_SSH_USER=cofounder-ops
  AI_COFUNDER_SSH_KEY=<path-to-private-key>

Remote commands:
  status|ps, health, diagnostics, metrics, activity [limit], routines,
  logs [bridge|bot|routine|migrate|all] [tail],
  up|stop|restart bridge|bot|all,
  run <routine-id>, deploy-info.
"@
}

function Resolve-IdentityFile {
    param([string] $ConfiguredPath)

    if ($ConfiguredPath) {
        return $ConfiguredPath
    }

    return $null
}

function Quote-BashArg {
    param([Parameter(Mandatory = $true)][string] $Value)

    if ($Value -eq '') {
        return "''"
    }

    return "'" + ($Value -replace "'", "'\''") + "'"
}

if ($Command -eq 'help') {
    Show-Usage
    exit 0
}

if (-not $HostName) {
    Write-Err 'ERROR [ai-cofounder-remote] Pass -HostName or set AI_COFUNDER_SSH_HOST.'
    Show-Usage
    exit 2
}

$IdentityFile = Resolve-IdentityFile -ConfiguredPath $IdentityFile
if (-not $IdentityFile) {
    Write-Err 'ERROR [ai-cofounder-remote] Pass -IdentityFile or set AI_COFUNDER_SSH_KEY.'
    Show-Usage
    exit 2
}

if (-not (Test-Path -LiteralPath $IdentityFile)) {
    Write-Err "ERROR [ai-cofounder-remote] SSH identity file not found: $IdentityFile"
    exit 2
}

$sshTarget = "$User@$HostName"
$sshArgs = @('-i', $IdentityFile)
if (-not $NoBatchMode) {
    $sshArgs += @('-o', 'BatchMode=yes')
}
$sshArgs += @('-o', 'ConnectTimeout=10')

if ($Command -eq 'tunnel') {
    Write-Host "INFO [ai-cofounder-remote] Opening tunnel http://127.0.0.1:$LocalPort -> $sshTarget:127.0.0.1:$RemotePort"
    & ssh @sshArgs -N -L "$LocalPort`:127.0.0.1`:$RemotePort" $sshTarget
    exit $LASTEXITCODE
}

$allRemoteArgs = @($Command)
if ($CommandArgs) {
    $allRemoteArgs += @($CommandArgs | Where-Object { $null -ne $_ -and $_ -ne '' })
}
$quotedArgs = $allRemoteArgs | ForEach-Object { Quote-BashArg -Value $_ }
$remoteCommand = "sudo -n $RemoteWrapper $($quotedArgs -join ' ')"

Write-Host "INFO [ai-cofounder-remote] $sshTarget :: $Command $($CommandArgs -join ' ')"
& ssh @sshArgs $sshTarget $remoteCommand
exit $LASTEXITCODE
