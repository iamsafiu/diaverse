param(
    [string]$Date = "",
    [string]$Author = "",
    [string]$File = "",
    [switch]$DryRun,
    [switch]$AllowUnsafePublicDigest
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "daily_work_publish.py"

$ArgsList = @("publish")
if ($Date) {
    $ArgsList += @("--date", $Date)
}
if ($Author) {
    $ArgsList += @("--author", $Author)
}
if ($File) {
    $ArgsList += @("--file", $File)
}
if ($DryRun) {
    $ArgsList += "--dry-run"
}
if ($AllowUnsafePublicDigest) {
    $ArgsList += "--allow-unsafe-public-digest"
}

python $PythonScript @ArgsList
