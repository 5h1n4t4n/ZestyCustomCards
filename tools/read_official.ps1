# Wrapper PowerShell cho tools/read_official.py
# Cho phép gọi tiện lợi: .\tools\read_official.ps1 <passcode|name> [options]

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptPath = Join-Path $PSScriptRoot "read_official.py"
python $scriptPath @args
exit $LASTEXITCODE
