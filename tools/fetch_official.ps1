param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Passcodes,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$destDir = Join-Path $PSScriptRoot "..\docs\official-reference"
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

# Resolve and flatten passcodes (handles spaces, commas, and remaining arguments)
$cleanCodes = @()
foreach ($code in $Passcodes) {
    # Split by comma or whitespace to handle strings like "123, 456" or "123 456"
    $splitCodes = $code -split '[\s,]+'
    foreach ($sc in $splitCodes) {
        $trimmed = $sc.Trim()
        if ($trimmed -ne "") {
            $cleanCodes += $trimmed
        }
    }
}

$successCount = 0
$skipCount = 0
$failCount = 0

foreach ($cleanPasscode in $cleanCodes) {
    if ($cleanPasscode -notmatch '^\d+$') {
        Write-Warning "Invalid passcode format: '$cleanPasscode'. Skipping."
        $failCount++
        continue
    }

    $codeInt = [int]$cleanPasscode
    $filename = "c$codeInt.lua"
    $destPath = Join-Path $destDir $filename

    # Query YGOPRODeck API for card name to print a friendly output
    $cardName = $null
    try {
        $apiUri = "https://db.ygoprodeck.com/api/v7/cardinfo.php?id=$codeInt"
        $apiRes = Invoke-RestMethod -Uri $apiUri -UseBasicParsing -ErrorAction SilentlyContinue
        if ($apiRes -and $apiRes.data) {
            $cardName = $apiRes.data[0].name
        }
    } catch {
        # Fallback to no name
    }

    $displayName = if ($cardName) { "$cardName ($codeInt)" } else { "Passcode $codeInt" }

    # Check if already exists
    if ((Test-Path $destPath) -and -not $Force) {
        Write-Host "[SKIP] $displayName already exists locally." -ForegroundColor Yellow
        $skipCount++
        continue
    }

    Write-Host "[FETCH] $displayName from ProjectIgnis CardScripts..." -ForegroundColor Cyan

    $urls = @(
        "https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/official/$filename",
        "https://raw.githubusercontent.com/ProjectIgnis/CardScripts/master/$filename"
    )

    $downloaded = $false
    foreach ($url in $urls) {
        try {
            # UseBasicParsing is critical: avoids MSHTML/IE dependency, making requests much faster
            Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing -ErrorAction Stop
            $downloaded = $true
            break
        } catch {
            # Try next fallback URL
        }
    }

    if ($downloaded) {
        Write-Host "[OK] Saved $filename successfully." -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "[FAIL] Failed to download script for $displayName." -ForegroundColor Red
        if (Test-Path $destPath) {
            Remove-Item $destPath -Force
        }
        $failCount++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor White
Write-Host "Downloaded : $successCount" -ForegroundColor Green
Write-Host "Skipped    : $skipCount" -ForegroundColor Yellow
Write-Host "Failed     : $failCount" -ForegroundColor Red
