[CmdletBinding()]
param(
    [string] $HostAlias,
    [string] $SshTarget,
    [string] $OutputName,
    [string] $IdentityFile,
    [string] $OutputRoot = ".tmp\server-inventory",
    [int] $ConnectTimeoutSeconds = 10,
    [switch] $DryRun,
    [switch] $Help
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Log-Info {
    param([string] $Message)
    Write-Host "INFO [inventory] $Message"
}

function Log-Warn {
    param([string] $Message)
    Write-Warning "WARN [inventory] $Message"
}

function Log-ErrorLine {
    param([string] $Message)
    [Console]::Error.WriteLine("ERROR [inventory] $Message")
}

function Show-Usage {
    @"
Usage:
  powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev
  powershell -ExecutionPolicy Bypass -File .\scripts\server-inventory.ps1 -HostAlias diaverse-dev -DryRun

Optional parameters:
  -SshTarget <target>       Use this SSH target while writing output under -HostAlias.
  -OutputName <name>        Override output folder name.
  -IdentityFile <path>      Optional SSH identity file. The path is never written to output.
  -OutputRoot <path>        Default: .tmp\server-inventory

Safety:
  The script only runs read-only commands.
  Raw snapshots are written under .tmp/server-inventory and must not be committed.
  Env-like values are redacted before output is saved.
"@ | Write-Host
}

function ConvertTo-SafeName {
    param([string] $Value)
    $safe = $Value -replace '[^a-zA-Z0-9_.-]', '-'
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "host"
    }
    return $safe
}

function Redact-SensitiveText {
    param([string] $Text)

    $redacted = $Text
    $redacted = $redacted -replace '(?im)^(\s*[A-Z0-9_]*(TOKEN|SECRET|PASSWORD|PASS|KEY|DSN|DATABASE_URL|REDIS_URL|API_HASH|API_ID|BOT_TOKEN|OPENAI|GROQ|JWT|SESSION|COOKIE)[A-Z0-9_]*\s*=\s*).+$', '$1<redacted>'
    $redacted = $redacted -replace '(?i)(Bearer\s+)[A-Za-z0-9._~+/=-]+', '$1<redacted>'
    $redacted = $redacted -replace '(?i)(://)[^/\s:@]+:[^@\s/]+@', '$1<redacted>@'
    $redacted = $redacted -replace '(?i)(telegram[_-]?(bot)?[_-]?token["'':=\s]+)[A-Za-z0-9:_-]+', '$1<redacted>'
    $redacted = $redacted -replace '(?i)(api[_-]?(key|hash|secret)["'':=\s]+)[A-Za-z0-9._~+/=-]+', '$1<redacted>'
    $sshPathPattern = '(?i)(/root/\.' + 'ssh/|~?/\.' + 'ssh/|C:\\Users\\[^\\]+\\\.' + 'ssh\\)[^\s''"]+'
    $redacted = $redacted -replace $sshPathPattern, '<ssh-path-redacted>'
    $privateKeyPattern = '(?is)-----BEGIN [A-Z ]*PRIVATE ' + 'KEY-----.*?-----END [A-Z ]*PRIVATE ' + 'KEY-----'
    $redacted = $redacted -replace $privateKeyPattern, '<private-key-redacted>'
    return $redacted
}

function Get-InventoryCommands {
    @(
        [pscustomobject]@{
            Name = "os"
            Command = @'
printf '## hostname\n'
hostname 2>/dev/null || true
printf '\n## hostnamectl\n'
hostnamectl 2>/dev/null || true
printf '\n## uname\n'
uname -a 2>/dev/null || true
printf '\n## uptime\n'
uptime 2>/dev/null || true
'@
        },
        [pscustomobject]@{
            Name = "versions"
            Command = @'
printf '## versions\n'
docker --version 2>/dev/null || true
docker compose version 2>/dev/null || true
nginx -v 2>&1 || true
traefik version 2>/dev/null || true
node --version 2>/dev/null || true
python3 --version 2>/dev/null || true
psql --version 2>/dev/null || true
'@
        },
        [pscustomobject]@{
            Name = "docker-ps"
            Command = @'
printf '## docker ps\n'
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
printf '\n## docker health states\n'
ids=$(docker ps -q 2>/dev/null || true)
if [ -n "$ids" ]; then
  docker inspect --format '{{.Name}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} failing_streak={{if .State.Health}}{{.State.Health.FailingStreak}}{{else}}0{{end}}' $ids 2>/dev/null || true
fi
'@
        },
        [pscustomobject]@{
            Name = "docker-compose"
            Command = @'
printf '## docker compose ls\n'
docker compose ls 2>/dev/null || true
printf '\n## compose files\n'
find /srv /opt /home /root -maxdepth 5 -type f \( -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'compose*.yml' -o -name 'compose*.yaml' \) -print 2>/dev/null | sort || true
'@
        },
        [pscustomobject]@{
            Name = "docker-networks"
            Command = @'
printf '## docker networks\n'
docker network ls 2>/dev/null || true
printf '\n## docker network containers\n'
for n in $(docker network ls --format '{{.Name}}' 2>/dev/null); do
  printf '\n### %s\n' "$n"
  docker network inspect "$n" --format '{{range $id,$c := .Containers}}{{println $c.Name $c.IPv4Address}}{{end}}' 2>/dev/null || true
done
'@
        },
        [pscustomobject]@{
            Name = "systemd"
            Command = @'
printf '## selected running services\n'
systemctl list-units --type=service --state=running --no-pager --plain 2>/dev/null \
  | grep -Ei 'docker|nginx|traefik|diaverse|diaweb|aibot|copywriting|club|bot|postgres|redis' || true
'@
        },
        [pscustomobject]@{
            Name = "reverse-proxy"
            Command = @'
printf '## nginx config files\n'
find /etc/nginx /home/config /srv /opt -maxdepth 5 -type f \( -name '*.conf' -o -name 'nginx.conf' \) -print 2>/dev/null | sort || true
printf '\n## traefik config files\n'
find /etc/traefik /home/config /srv /opt -maxdepth 5 -type f \( -name 'traefik.*' -o -name '*traefik*.yml' -o -name '*traefik*.yaml' -o -name '*traefik*.toml' \) -print 2>/dev/null | sort || true
printf '\n## caddy config files\n'
find /etc/caddy /home /srv /opt -maxdepth 5 -type f \( -name 'Caddyfile' -o -name '*.caddy' \) -print 2>/dev/null | sort || true
printf '\n## proxy containers and labels\n'
for id in $(docker ps -q 2>/dev/null); do
  name=$(docker inspect --format '{{.Name}}' "$id" 2>/dev/null || true)
  case "$name" in
    *traefik*|*nginx*|*caddy*) docker inspect --format '{{.Name}} {{json .Config.Labels}}' "$id" 2>/dev/null || true ;;
  esac
done
printf '\n## route labels\n'
for id in $(docker ps -q 2>/dev/null); do
  docker inspect --format '{{.Name}} {{json .Config.Labels}}' "$id" 2>/dev/null || true
done | grep -Ei 'traefik\.|caddy|nginx|router|rule|host|loadbalancer|entrypoints|tls|certresolver' || true
'@
        },
        [pscustomobject]@{
            Name = "ports"
            Command = @'
printf '## listening tcp/udp ports\n'
ss -tulpen 2>/dev/null || netstat -tulpen 2>/dev/null || true
'@
        },
        [pscustomobject]@{
            Name = "disk"
            Command = @'
printf '## filesystems\n'
df -hT 2>/dev/null || true
printf '\n## docker disk usage\n'
docker system df 2>/dev/null || true
'@
        },
        [pscustomobject]@{
            Name = "repos"
            Command = @'
printf '## git checkouts\n'
find /srv /opt /home /root -maxdepth 4 -type d -name .git -print 2>/dev/null | sort | while read gitdir; do
  repo="${gitdir%/.git}"
  printf '\n### %s\n' "$repo"
  git -C "$repo" branch --show-current 2>/dev/null || true
  git -C "$repo" rev-parse --short HEAD 2>/dev/null || true
  git -C "$repo" remote -v 2>/dev/null || true
done
'@
        },
        [pscustomobject]@{
            Name = "env-paths"
            Command = @'
printf '## env-like file paths only\n'
find /srv /opt /home /root -maxdepth 5 -type f \( -name '.env' -o -name '.env.*' -o -name '*env*.production' -o -name '*env*.local' \) -print 2>/dev/null | sort || true
'@
        }
    )
}

function Invoke-RemoteCommand {
    param(
        [string] $Target,
        [string] $Command,
        [string] $Identity,
        [int] $TimeoutSeconds
    )

    $sshArgs = @(
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=$TimeoutSeconds"
    )
    if (-not [string]::IsNullOrWhiteSpace($Identity)) {
        $sshArgs += @("-i", $Identity)
    }

    $commandBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Command))
    $remoteCommand = "printf %s $commandBase64 | base64 -d | bash"
    $output = & ssh @sshArgs $Target $remoteCommand 2>&1
    $code = $LASTEXITCODE
    return [pscustomobject]@{
        ExitCode = $code
        Output = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($HostAlias)) {
    Show-Usage
    Log-ErrorLine "Missing required -HostAlias."
    exit 1
}

$target = if ([string]::IsNullOrWhiteSpace($SshTarget)) { $HostAlias } else { $SshTarget }
$folderName = if ([string]::IsNullOrWhiteSpace($OutputName)) { ConvertTo-SafeName -Value $HostAlias } else { ConvertTo-SafeName -Value $OutputName }
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$workspaceRoot = (Resolve-Path -LiteralPath ".").Path
$outputBase = Join-Path $workspaceRoot $OutputRoot
$outputDir = Join-Path (Join-Path $outputBase $dateStamp) $folderName
$commands = @(Get-InventoryCommands)

if ($DryRun) {
    Log-Info "Dry run for host alias '$HostAlias'."
    Log-Info "Output directory would be: $outputDir"
    foreach ($item in $commands) {
        Log-Info "Would collect: $($item.Name)"
    }
    exit 0
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Log-Info "Collecting host alias '$HostAlias' into $outputDir"
if (-not [string]::IsNullOrWhiteSpace($IdentityFile)) {
    Log-Info "SSH identity file configured; path is not written to inventory output."
}

$probe = Invoke-RemoteCommand -Target $target -Command "printf 'inventory-ok\n'" -Identity $IdentityFile -TimeoutSeconds $ConnectTimeoutSeconds
if ($probe.ExitCode -ne 0 -or ($probe.Output -notmatch "inventory-ok")) {
    $safeProbe = Redact-SensitiveText -Text $probe.Output
    Set-Content -LiteralPath (Join-Path $outputDir "ssh-probe.error.txt") -Value $safeProbe -Encoding utf8
    Log-ErrorLine "SSH probe failed for host alias '$HostAlias'. See ssh-probe.error.txt."
    exit 1
}

$metadata = @(
    "host_alias=$HostAlias",
    "generated_at=$(Get-Date -Format o)",
    "output_name=$folderName",
    "dry_run=false",
    "identity_file_configured=$([bool](-not [string]::IsNullOrWhiteSpace($IdentityFile)))"
) -join "`n"
Set-Content -LiteralPath (Join-Path $outputDir "metadata.txt") -Value $metadata -Encoding utf8

foreach ($item in $commands) {
    Log-Info "Collecting $($item.Name)"
    $result = Invoke-RemoteCommand -Target $target -Command $item.Command -Identity $IdentityFile -TimeoutSeconds $ConnectTimeoutSeconds
    $safeOutput = Redact-SensitiveText -Text $result.Output
    $filePath = Join-Path $outputDir "$($item.Name).txt"
    Set-Content -LiteralPath $filePath -Value $safeOutput -Encoding utf8
    if ($result.ExitCode -ne 0) {
        Log-Warn "$($item.Name) returned exit code $($result.ExitCode); sanitized output saved."
    }
}

Log-Info "Inventory completed for host alias '$HostAlias'."
Log-Info "Review sanitized snapshots before copying any facts into docs."
