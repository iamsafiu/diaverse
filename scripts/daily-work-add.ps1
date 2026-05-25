param(
    [string]$Date = "",
    [string]$Author = "",
    [string]$Public = "",
    [string]$Internal = "",
    [switch]$SkipEmpty
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PythonScript = Join-Path $ScriptDir "daily_work_publish.py"

$ArgsList = @("add")
if ($Date) {
    $ArgsList += @("--date", $Date)
}
if ($Author) {
    $ArgsList += @("--author", $Author)
}
if ($Public) {
    $ArgsList += @("--public", $Public)
}
if ($Internal) {
    $ArgsList += @("--internal", $Internal)
}
if ($SkipEmpty) {
    $ArgsList += "--skip-empty"
}

python $PythonScript @ArgsList
