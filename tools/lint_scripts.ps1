<#
.SYNOPSIS
    Lua Script Linter Runner — Chạy luacheck + format check cho card scripts
.DESCRIPTION
    Kiểm tra style và best practices cho Lua card scripts.
    Cần cài luacheck: luarocks install luacheck
.PARAMETER Path
    File hoặc thư mục để check
.PARAMETER Fix
    Tự động fix một số vấn đề đơn giản (unused locals, whitespace)
.EXAMPLE
    .\tools\lint_scripts.ps1
    .\tools\lint_scripts.ps1 -Path script\c12345678.lua
#>

param(
    [string]$Path = "script\*.lua",
    [switch]$Fix = $false
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=== TTF Card Script Linter ===" -ForegroundColor Cyan
Write-Host ""

$luacheckPath = Get-Command luacheck -ErrorAction SilentlyContinue

if (-not $luacheckPath) {
    Write-Host "luacheck not found. Install with: luarocks install luacheck" -ForegroundColor Red
    Write-Host ""
    Write-Host "Running basic checks instead..." -ForegroundColor Yellow
    Write-Host ""

    $files = Get-ChildItem $Path

    $issues = @{}
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        $lines = $content -split "`r`n|`n"
        $name = $file.Name
        $fileIssues = @()

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $ln = $i + 1

            # Trailing whitespace
            if ($line -match '\s+$' -and $line.Trim().Length -gt 0) {
                $fileIssues += @{ Line = $ln; Col = $line.Length; Msg = "Trailing whitespace" }
            }



            # Long lines (> 120)
            if ($line.Length -gt 120 -and $line -notmatch "^--") {
                $fileIssues += @{ Line = $ln; Col = 1; Msg = "Line too long ($($line.Length) > 120 characters)" }
            }
        }

        if ($fileIssues.Count -gt 0) {
            $issues[$name] = $fileIssues
        }
    }

    if ($issues.Count -eq 0) {
        Write-Host "All clean!" -ForegroundColor Green
    } else {
        foreach ($file in $issues.Keys) {
            Write-Host "$file :" -ForegroundColor Yellow
            foreach ($issue in $issues[$file]) {
                Write-Host "  L$($issue.Line): $($issue.Msg)" -ForegroundColor Gray
            }
        }
        Write-Host ""
        Write-Host "Total files with issues: $($issues.Count)" -ForegroundColor Yellow
    }
    exit 0
}

# Run luacheck
$configPath = Join-Path $PSScriptRoot ".." ".luacheckrc"
if (Test-Path $configPath) {
    & luacheck $Path --config $configPath
} else {
    Write-Host "No .luacheckrc found, running without config..." -ForegroundColor Yellow
    & luacheck $Path --std lua53
}

exit $LASTEXITCODE
