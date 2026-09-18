<#
.SYNOPSIS
    EDOPro Card Script Validator — Kiểm tra Lua script tự động
.DESCRIPTION
    Quét tất cả file .lua trong thư mục script/ và kiểm tra:
    - Cú pháp Lua hợp lệ (gọi Lua parser)
    - Có function initial_effect
    - Có gọi GetID()
    - Có RegisterEffect
    - Mỗi Effect.CreateEffect có SetType và SetCode
    - SetTarget có check chk==0
.PARAMETER Path
    Đường dẫn file .lua cụ thể để kiểm tra. Nếu không chỉ định, quét toàn bộ script/
.PARAMETER Quiet
    Chỉ hiển thị file bị lỗi, không hiển thị file OK
.EXAMPLE
    .\script-test\validate_scripts.ps1
    .\script-test\validate_scripts.ps1 -Path script\c12345678.lua
    .\script-test\validate_scripts.ps1 -Quiet
#>

param(
    [string]$Path = "",
    [switch]$Quiet = $false
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Resolve-Path "script"
$ExitCode = 0
$TotalOk = 0
$TotalWarn = 0
$TotalFail = 0

$ErrorActionPreference = "Continue"

function Test-LuaSyntax {
    param([string]$FilePath)
    try {
        $escaped = $FilePath -replace '\\', '/'
        $cmd = "local f,e=loadfile('$escaped'); if f ~= nil then return 'OK' else return e end"
        $result = & lua -e $cmd 2>&1
        if ($LASTEXITCODE -eq 0) {
            return @{ Ok = $true; Message = "" }
        } else {
            $errMsg = if ($result -is [array]) { $result -join '; ' } else { "$result" }
            return @{ Ok = $false; Message = $errMsg }
        }
    } catch {
        return @{ Ok = $false; Message = $_.Exception.Message }
    }
}

function Test-LuaSyntaxFallback {
    param([string]$FilePath)
    $content = Get-Content $FilePath -Raw -ErrorAction Stop
    $warnings = @()

    $lines = $content -split "`r`n|`n"
    $depth = 0
    $lineNum = 0
    $inString = $false
    $stringChar = ""
    $inComment = $false
    $inBlockComment = $false

    foreach ($line in $lines) {
        $lineNum++
        $chars = $line.ToCharArray()
        for ($i = 0; $i -lt $chars.Length; $i++) {
            $c = $chars[$i]
            $prev = if ($i -gt 0) { $chars[$i-1] } else { "" }
            $next = if ($i -lt $chars.Length - 1) { $chars[$i+1] } else { "" }

            if ($inBlockComment) {
                if ($c -eq ']' -and $next -eq ']') { $inBlockComment = $false }
                continue
            }
            if ($inComment) {
                if ($c -eq "`n") { $inComment = $false }
                continue
            }
            if ($c -eq '-' -and $next -eq '-') {
                if ($i + 3 -lt $chars.Length -and $chars[$i+2] -eq '[' -and $chars[$i+3] -eq '[') {
                    $inBlockComment = $true
                } else {
                    $inComment = $true
                }
                continue
            }
            if ($inString) {
                if ($c -eq $stringChar -and $prev -ne '\') { $inString = $false }
                continue
            }
            if ($c -eq '"' -or $c -eq "'") { $inString = $true; $stringChar = $c; continue }
            if ($c -eq '(' -or $c -eq '{' -or $c -eq '[') { $depth++ }
            if ($c -eq ')' -or $c -eq '}' -or $c -eq ']') { $depth--; if ($depth -lt 0) { $depth = 0 } }
        }
    }

    if ($inString) { $warnings += "Unclosed string" }
    if ($depth -ne 0) { $warnings += "Unbalanced brackets (depth=$depth)" }

    return @{ Ok = ($warnings.Count -eq 0); Message = ($warnings -join "; ") }
}

function Test-ScriptStructure {
    param([string]$FilePath, [string]$Content)
    $warnings = @()
    $errors = @()

    if ($Content -notmatch 'function\s+s\.initial_effect') {
        $errors += "Missing: initial_effect function"
    }

    if ($Content -notmatch 'GetID\s*\(\s*\)') {
        $errors += "Missing: GetID() call"
    }

    if ($Content -notmatch 'RegisterEffect') {
        $errors += "Missing: RegisterEffect call"
    }

    $effectMatches = [regex]::Matches($Content, 'Effect\.CreateEffect')
    $setCodeMatches = [regex]::Matches($Content, 'SetCode')
    $setTypeMatches = [regex]::Matches($Content, 'SetType')

    if ($effectMatches.Count -gt 0) {
        if ($setTypeMatches.Count -lt $effectMatches.Count) {
            $warnings += "Some Effect.CreateEffect may be missing SetType"
        }
        if ($setCodeMatches.Count -lt $effectMatches.Count) {
            $warnings += "Some Effect.CreateEffect may be missing SetCode"
        }
    }

    # Check SetTarget has chk==0 pattern
    $targetFuncs = [regex]::Matches($Content, 'SetTarget\s*\(\s*s\.(\w+)')
    foreach ($match in $targetFuncs) {
        $funcName = "s.$($match.Groups[1].Value)"
        $funcPattern = "function\s+$funcName\s*\([^)]*\)[^}]*end"
        $funcMatch = [regex]::Match($Content, $funcPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($funcMatch.Success) {
            $funcBody = $funcMatch.Value
            if ($funcBody -notmatch 'chk\s*==\s*0') {
                $funcNameClean = $match.Groups[1].Value
                $warnings += "SetTarget $funcNameClean may be missing 'if chk==0' check"
            }
        }
    }

    # Check operation functions have IsRelateToEffect
    $opFuncs = [regex]::Matches($Content, 'SetOperation\s*\(\s*s\.(\w+)')
    foreach ($match in $opFuncs) {
        $funcName = "s.$($match.Groups[1].Value)"
        $funcNameClean = $match.Groups[1].Value
        if ($funcNameClean -ne 'initial_effect') {
            $funcPattern = "function\s+$funcName\s*\([^)]*\).*?end\s*$"
            $funcMatch = [regex]::Match($Content, $funcPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
            if ($funcMatch.Success) {
                $funcBody = $funcMatch.Value
                if ($funcBody -match 'e:GetHandler\s*\(\s*\)' -and $funcBody -notmatch 'IsRelateToEffect') {
                    $warnings += "Operation $funcNameClean uses GetHandler() but may be missing IsRelateToEffect check"
                }
            }
        }
    }

    # Check for Event+Phase without explicit PHASE constant
    if ($Content -match 'EVENT_PHASE\s*\+') {
        if ($Content -notmatch 'PHASE_DRAW|PHASE_STANDBY|PHASE_MAIN1|PHASE_MAIN2|PHASE_BATTLE|PHASE_END') {
            $warnings += "EVENT_PHASE used without specific PHASE constant"
        }
    }

    return @{ Errors = $errors; Warnings = $warnings }
}

function Test-LuaConstants {
    param([string]$Content)
    
    # 2. Clean comments and strings
    $clean = $Content
    $clean = [regex]::Replace($clean, '(?s)--\[\[.*?\]\]', '') # block comments
    $clean = [regex]::Replace($clean, '--.*', '')              # line comments
    $clean = [regex]::Replace($clean, '"(?:[^"\\]|\\.)*"', '')  # double quotes
    $clean = [regex]::Replace($clean, "'(?:[^'\\]|\\.)*'", '')  # single quotes

    # 3. Find all uppercase words starting with common prefixes or containing underscores
    $matches = [regex]::Matches($clean, '\b[A-Z_][A-Z0-9_]{3,}\b')
    $warnings = @()
    foreach ($m in $matches) {
        $val = $m.Value
        # Filter out common false positives
        if ($val -eq "TRUE" -or $val -eq "FALSE" -or $val -eq "NULL" -or $val -eq "CARD" -or $val -eq "DUEL") { continue }
        
        # Check if it starts with one of the standard EDOPro prefixes
        $hasPrefix = $val -match '^(LOCATION_|TYPE_|ATTRIBUTE_|RACE_|CATEGORY_|EVENT_|PHASE_|EFFECT_|POS_|REASON_|SUMMON_|TIMING|HINT)'
        if ($hasPrefix -and -not $Global:ValidConstants.Contains($val)) {
            $warnings += "Undefined or non-standard constant used: '$val'"
        }
    }
    return $warnings | Select-Object -Unique
}

function Test-ConstantsDependency {
    param([string]$Content, [string]$FileName)
    $errors = @()
    if ($FileName -eq "constants.lua") { return $errors }

    # Clean comments and strings to avoid false positives
    $clean = $Content
    $clean = [regex]::Replace($clean, '(?s)--\[\[.*?\]\]', '')
    $clean = [regex]::Replace($clean, '--.*', '')
    $clean = [regex]::Replace($clean, '"(?:[^"\\]|\\.)*"', '""')
    $clean = [regex]::Replace($clean, "'(?:[^'\\]|\\.)*'", "''")

    # EDOPro KHONG tu load script/constants.lua — script nao dung dinh danh
    # tu file do bat buoc phai co Duel.LoadScript("constants.lua") o dau file,
    # neu khong se crash runtime: attempt to call/index a nil value.
    $hasLoad = $Content -match 'Duel\.LoadScript\(\s*"constants\.lua"\s*\)'
    foreach ($ident in $Global:CustomIdentifiers) {
        if (-not $hasLoad -and $clean -match "\b$([regex]::Escape($ident))\b") {
            $errors += "Uses '$ident' (defined in script/constants.lua) without Duel.LoadScript(`"constants.lua`") - crashes at runtime with 'attempt to call a nil value'"
        }
    }

    # Cac "API ma" (ham khong ton tai trong EDOPro) tung gay crash truoc day
    foreach ($api in $Global:PhantomApis) {
        if ($clean -match [regex]::Escape($api)) {
            $errors += "Phantom API '$api' does not exist in EDOPro - crashes at runtime (see script-test/phantom_apis.txt)"
        }
    }
    return $errors
}

function Test-ScriptFile {
    param([string]$FilePath)
    $fileName = Split-Path $FilePath -Leaf
    $fileWarnings = @()
    $fileErrors = @()

    # Check filename convention
    if ($fileName -notmatch '^c\d+\.lua$') {
        $fileWarnings += "Filename does not match cXXXXXXXXX.lua convention"
    }

    # Check file encoding (must be UTF-8 or ASCII)
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $FilePath))
    if ($bytes.Length -ge 3) {
        if ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            # UTF-8 BOM - ok
        } elseif ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            $fileWarnings += "UTF-16 LE encoding detected, should be UTF-8"
        }
    }

    return @{ Warnings = $fileWarnings; Errors = $fileErrors }
}

# ============================================================
# MAIN
# ============================================================

# Load standard constants once at startup
$ConstantsFile = Join-Path $PSScriptRoot "edopro_constants.txt"
if (Test-Path $ConstantsFile) {
    $Global:ValidConstants = [System.Collections.Generic.HashSet[string]]::new([string[]](Get-Content $ConstantsFile), [System.StringComparer]::Ordinal)
} else {
    $Global:ValidConstants = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
}

# Add custom constants from constants.lua if exists
$RootPath = Split-Path $PSScriptRoot
$CustomPath = Join-Path $RootPath "script\constants.lua"
$Global:CustomIdentifiers = [System.Collections.Generic.List[string]]::new()
if (Test-Path $CustomPath) {
    $constContent = Get-Content $CustomPath -Raw
    $customMatches = [regex]::Matches($constContent, '\b[A-Z_][A-Z0-9_]+\b')
    foreach ($m in $customMatches) {
        [void]$Global:ValidConstants.Add($m.Value)
    }
    # Thu thap dinh danh ma constants.lua dinh nghia: hang so (SET_X = ...)
    # va helper function (function Card.X / Duel.X ...) — dung cho dependency check
    foreach ($m in [regex]::Matches($constContent, '(?m)^\s*([A-Z][A-Z0-9_]+)\s*=')) {
        [void]$Global:CustomIdentifiers.Add($m.Groups[1].Value)
    }
    foreach ($m in [regex]::Matches($constContent, 'function\s+\w+\.(\w+)\s*\(')) {
        [void]$Global:CustomIdentifiers.Add($m.Groups[1].Value)
    }
}

# Load known phantom APIs blacklist (cac ham khong ton tai tung gay crash)
$PhantomFile = Join-Path $PSScriptRoot "phantom_apis.txt"
$Global:PhantomApis = @()
if (Test-Path $PhantomFile) {
    $Global:PhantomApis = @(Get-Content $PhantomFile | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() })
}

Write-Host ""
Write-Host "=== TTF Card Script Validator ===" -ForegroundColor Cyan
Write-Host ""

$luaAvailable = Get-Command lua -ErrorAction SilentlyContinue
if (-not $luaAvailable) {
    Write-Host "WARNING: Lua not found in PATH. Syntax checks will use fallback method." -ForegroundColor Yellow
    Write-Host "Install Lua 5.3+ from https://luabinaries.sourceforge.net/ for full validation."
    Write-Host ""
}

if ($Path -ne "") {
    if (-not (Test-Path $Path)) {
        Write-Host "ERROR: File not found: $Path" -ForegroundColor Red
        exit 1
    }
    $files = @(Get-Item $Path)
} else {
    $files = @(Get-ChildItem -Path $ScriptDir -Filter "*.lua" | Where-Object { $_.Name -ne "constants.lua" })
}

if ($files.Count -eq 0) {
    Write-Host "No .lua files found in script/" -ForegroundColor Yellow
    exit 0
}

Write-Host "Scanning: script/" -ForegroundColor Gray
Write-Host "Found $($files.Count) script(s)`n" -ForegroundColor Gray

foreach ($file in $files) {
    $fileName = $file.Name
    $filePath = $file.FullName
    $hasError = $false
    $hasWarning = $false
    $allMessages = @()

    # 1. Filename check
    $fileCheck = Test-ScriptFile -FilePath $filePath
    foreach ($e in $fileCheck.Errors) { $allMessages += "FILE: $e"; $hasError = $true }
    foreach ($w in $fileCheck.Warnings) { $allMessages += "FILE: $w"; $hasWarning = $true }

    # 2. Read content
    try {
        $content = Get-Content $filePath -Raw -ErrorAction Stop
    } catch {
        $allMessages += "FILE: Cannot read file"
        $hasError = $true
    }

    if (-not $hasError) {
        # 3. Syntax check
        if ($luaAvailable) {
            $syntax = Test-LuaSyntax -FilePath $filePath
        } else {
            $syntax = Test-LuaSyntaxFallback -FilePath $filePath
        }
        if (-not $syntax.Ok) {
            $allMessages += "SYNTAX: $($syntax.Message)"
            $hasError = $true
        }

        # 4. Structure check
        $struct = Test-ScriptStructure -FilePath $filePath -Content $content
        foreach ($e in $struct.Errors) { $allMessages += "STRUCT: $e"; $hasError = $true }
        foreach ($w in $struct.Warnings) { $allMessages += "STRUCT: $w"; $hasWarning = $true }

        # 5. Constants check
        $constWarnings = Test-LuaConstants -Content $content
        foreach ($w in $constWarnings) { $allMessages += "CONST: $w"; $hasWarning = $true }

        # 6. constants.lua dependency + phantom API check (FAIL — gay crash runtime)
        $depErrors = Test-ConstantsDependency -Content $content -FileName $fileName
        foreach ($e in $depErrors) { $allMessages += "DEPEND: $e"; $hasError = $true }
    }

    if ($hasError) {
        Write-Host ("[*] FAIL $fileName") -ForegroundColor Red
        foreach ($msg in $allMessages) { Write-Host "     $msg" -ForegroundColor Red }
        $TotalFail++
    } elseif ($hasWarning -and -not $Quiet) {
        Write-Host ("[!] WARN $fileName") -ForegroundColor Yellow
        foreach ($msg in $allMessages) { Write-Host "     $msg" -ForegroundColor Yellow }
        $TotalWarn++
    } else {
        if (-not $Quiet) { Write-Host ("[ ] OK   $fileName") -ForegroundColor Green }
        $TotalOk++
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "Results: " -NoNewline
Write-Host "$TotalOk OK, " -NoNewline -ForegroundColor Green
Write-Host "$TotalWarn WARN, " -NoNewline -ForegroundColor Yellow
Write-Host "$TotalFail FAIL" -ForegroundColor Red
Write-Host "=======================================" -ForegroundColor Cyan

if ($TotalFail -gt 0) { exit 1 } else { exit 0 }
