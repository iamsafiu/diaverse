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
        $_.FullName -notmatch "\\docs\\daily\\d{4}-\d{2}-\d{2}-" -and
        $_.FullName -notmatch "\\node_modules\\" -and
        $_.FullName -notmatch "\\\.npm-cache\\"
    }

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$checkedLinks = 0

function Get-RelativePath([string]$BasePath, [string]$TargetPath) {
    $baseUri = [System.Uri]::new((Resolve-Path -LiteralPath $BasePath).Path + [System.IO.Path]::DirectorySeparatorChar)
    $targetUri = [System.Uri]::new($TargetPath)
    return [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace("/", [System.IO.Path]::DirectorySeparatorChar)
}

function Remove-CodeFences([string]$Text) {
    return [regex]::Replace($Text, '(?s)```.*?```', "")
}

function Test-InvalidPathChars([string]$PathValue) {
    return $PathValue.IndexOfAny([System.IO.Path]::GetInvalidPathChars()) -ge 0
}

foreach ($file in $markdownFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $linkText = Remove-CodeFences -Text $text
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

    $linkMatches = [regex]::Matches($linkText, '(?<!\!)\[[^\]]+\]\(([^)]+)\)')
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

        try {
            $decodedTarget = [System.Uri]::UnescapeDataString($targetWithoutAnchor)
        } catch {
            $warnings.Add("Malformed local link in $relativeFile -> $target (invalid URI escape)")
            continue
        }

        if (Test-InvalidPathChars -PathValue $decodedTarget) {
            $warnings.Add("Malformed local link in $relativeFile -> $target (invalid path characters)")
            continue
        }

        try {
            $candidate = Join-Path $file.DirectoryName $decodedTarget
        } catch {
            $warnings.Add("Malformed local link in $relativeFile -> $target (cannot resolve path)")
            continue
        }

        $checkedLinks += 1
        if (-not (Test-Path -LiteralPath $candidate -ErrorAction SilentlyContinue)) {
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
