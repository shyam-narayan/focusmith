# Builds everything: release + installer + portable ZIP + MSIX (when configured).
# Usage: .\scripts\build-all.ps1

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

Write-Host "=== FOCUSMITH full Windows packaging ===" -ForegroundColor Cyan

& (Join-Path $PSScriptRoot "build-installer.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n=== MSIX (optional) ===" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "build-msix.ps1")
exit $LASTEXITCODE
