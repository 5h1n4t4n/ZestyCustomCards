param (
    [Parameter(Mandatory=$false)]
    [string]$GameDir = "F:\Game\ProjectIgnis",

    [Parameter(Mandatory=$false)]
    [string]$CardId = ""
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Write-Host "=== Dong bo du lieu sang EDOPro Game ===" -ForegroundColor Cyan
Write-Host "Repo Root: $root"
Write-Host "Game Dir : $GameDir"

if (-not (Test-Path $GameDir)) {
    Write-Error "Khong tim thay thu muc game tai '$GameDir'!"
    exit 1
}

$repoDest = Join-Path $GameDir "repositories\custom_cards_zesty"
if (-not (Test-Path $repoDest)) {
    Write-Host "[INFO] Tao thu muc repo custom trong game: $repoDest" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $repoDest -Force | Out-Null
}

# 1. Sync Scripts
Write-Host "`n[1/4] Dong bo scripts..." -ForegroundColor Yellow
$scriptDest = Join-Path $repoDest "script"
if (-not (Test-Path $scriptDest)) { New-Item -ItemType Directory -Path $scriptDest -Force | Out-Null }

if ($CardId -ne "") {
    $srcFile = Join-Path $root "script\c$CardId.lua"
    if (Test-Path $srcFile) {
        Copy-Item $srcFile $scriptDest -Force
        Write-Host "  -> Da copy c$CardId.lua" -ForegroundColor Green
    } else {
        Write-Warning "Khong tim thay script/c$CardId.lua!"
    }
} else {
    Copy-Item (Join-Path $root "script\*.lua") $scriptDest -Force
    Write-Host "  -> Da dong bo toan bo scripts sang game." -ForegroundColor Green
}

# 2. Sync CDBs
Write-Host "`n[2/4] Dong bo database CDB..." -ForegroundColor Yellow
$cdbFiles = @("card-data.cdb", "mycard.cdb", "custom_cards_zesty.cdb", "Chrysos Heirs.cdb", "FlowerSpirit.cdb", "Madoka.cdb", "Mecha Three Kingdom.cdb", "Nightbloom.cdb", "Rising Heroes.cdb")
foreach ($cdb in $cdbFiles) {
    $srcCdb = Join-Path $root $cdb
    if (Test-Path $srcCdb) {
        Copy-Item $srcCdb $repoDest -Force
        Write-Host "  -> Da copy $cdb" -ForegroundColor Green
    }
}

# Dong bo strings.conf neu co
$srcStrings = Join-Path $root "strings.conf"
if (Test-Path $srcStrings) {
    Copy-Item $srcStrings $repoDest -Force
    Write-Host "  -> Da copy strings.conf" -ForegroundColor Green
}

# 3. Sync Pics
Write-Host "`n[3/4] Dong bo hinh anh (Pics)..." -ForegroundColor Yellow
$picsDest = Join-Path $repoDest "pics"
if (-not (Test-Path $picsDest)) { New-Item -ItemType Directory -Path $picsDest -Force | Out-Null }

if ($CardId -ne "") {
    $picJpg = Join-Path $root "pics\$CardId.jpg"
    $picPng = Join-Path $root "pics\$CardId.png"
    if (Test-Path $picJpg) {
        Copy-Item $picJpg $picsDest -Force
        $oldPng = Join-Path $picsDest "$CardId.png"
        if (Test-Path $oldPng) { Remove-Item $oldPng -Force }
        Write-Host "  -> Da copy $CardId.jpg (da don .png cu neu co)" -ForegroundColor Green
    } elseif (Test-Path $picPng) {
        Copy-Item $picPng $picsDest -Force
        Write-Host "  -> Da copy $CardId.png" -ForegroundColor Green
    }
} else {
    Copy-Item (Join-Path $root "pics\*.*") $picsDest -Force
    Write-Host "  -> Da dong bo toan bo hinh anh sang game." -ForegroundColor Green
}

# 4. Tao deck test neu co CardId
if ($CardId -ne "") {
    Write-Host "`n[4/4] Tao test deck cho card $CardId..." -ForegroundColor Yellow
    $deckDir = Join-Path $GameDir "deck"
    if (Test-Path $deckDir) {
        $deckPath = Join-Path $deckDir "test_$CardId.ydk"
        $deckLines = @(
            "#created by TTF Test Tool",
            "#main",
            $CardId,
            $CardId,
            $CardId,
            "76812113",
            "76812113",
            "76812113",
            "12206212",
            "39392286",
            "39392286",
            "90953320",
            "19337371",
            "19337371",
            "52040212",
            "81136679",
            "14558127",
            "#extra",
            "63261835",
            "90238142",
            "!side"
        )
        [System.IO.File]::WriteAllLines($deckPath, $deckLines)
        Write-Host "  -> Da tao deck test: test_$CardId.ydk" -ForegroundColor Green
    }
}

Write-Host "`n=== Hoan tat dong bo! Khoi dong lai EDOPro de test card. ===" -ForegroundColor Cyan
