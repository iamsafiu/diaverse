param(
    [string]$DocsRoot = "docs",
    [switch]$StrictMetadata
)

$ErrorActionPreference = "Stop"

$workspace = (Resolve-Path ".").Path
$docsPath = Join-Path $workspace $DocsRoot

if (-not (Test-Path -LiteralPath $docsPath)) {
    Write-Error "Docs root not found: $docsPath"
}

$markdownFiles = Get-ChildItem -LiteralPath $docsPath -Recurse -File -Filter "*.md" |
    Where-Object {
        $_.FullName -notmatch "\\graphify-out\\" -and
        $_.FullName -notmatch "\\docs\\daily\\\d{4}-\d{2}-\d{2}-"
    }

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$checkedLinks = 0

function Get-RelativePath([string]$BasePath, [string]$TargetPath) {
    $baseUri = [System.Uri]::new((Resolve-Path -LiteralPath $BasePath).Path + [System.IO.Path]::DirectorySeparatorChar)
    $targetUri = [System.Uri]::new($TargetPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
}

foreach ($file in $markdownFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $relativeFile = Get-RelativePath $workspace $file.FullName

    if ($text -notmatch "(?m)^#\s+\S") {
        $warnings.Add("Missing H1: $relativeFile")
    }

    if ($StrictMetadata -and $relativeFile -notmatch "^docs\\(daily|tasks|research|logs|archive)\\") {
        if ($text -notmatch "(?s)^---\s+.*?status:\s+\S+.*?---") {
            $warnings.Add("Missing metadata block: $relativeFile")
        }
    }

    foreach ($marker in @(
        "C:\Users\Indigo\Desktop\Saf",
        "C:\Users\Indigo\Desktop\diaweb",
        "/C:/Users/Indigo/Desktop/Saf",
        "/C:/Users/Indigo/Desktop/diaweb"
    )) {
        if ($text.Contains($marker)) {
            $errors.Add("Stale local path '$marker' in $relativeFile")
        }
    }

    $linkMatches = [regex]::Matches($text, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')
    foreach ($match in $linkMatches) {
        $target = $match.Groups[1].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($target)) {
            continue
        }
        if ($target -match "^(https?:|mailto:|tg:|#)") {
            continue
        }
        if ($target.StartsWith("C:\") -or $target.StartsWith("/C:/")) {
            continue
        }

        $targetWithoutAnchor = $target.Split("#")[0]
        if ([string]::IsNullOrWhiteSpace($targetWithoutAnchor)) {
            continue
        }
        if ($targetWithoutAnchor -match "^[a-zA-Z]+:") {
            continue
        }

        $candidate = Join-Path $file.DirectoryName ([System.Uri]::UnescapeDataString($targetWithoutAnchor))
        $checkedLinks += 1
        if (-not (Test-Path -LiteralPath $candidate)) {
            $errors.Add("Broken local link in $relativeFile -> $target")
        }
    }
}

Write-Host "Docs health check"
Write-Host "Workspace: $workspace"
Write-Host "Markdown files checked: $($markdownFiles.Count)"
Write-Host "Local markdown links checked: $checkedLinks"
Write-Host "Warnings: $($warnings.Count)"
Write-Host "Errors: $($errors.Count)"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    $warnings | ForEach-Object { Write-Host "WARN $_" }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    $errors | ForEach-Object { Write-Host "ERROR $_" }
    exit 1
}

Write-Host "OK"
