# Builds an MSIX package for sideload / Microsoft Store submission.
# Prerequisites: Flutter release build, dart pub get (msix dev dependency)
#
# Usage:
#   .\scripts\build-msix.ps1
#   .\scripts\build-msix.ps1 -SkipFlutterBuild

param(
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

function Get-AppVersion {
    param([string]$PubspecPath)
    $content = Get-Content $PubspecPath -Raw
    if ($content -match '(?m)^version:\s*([\d.]+)\+(\d+)\s*$') {
        return $Matches[1]
    }
    throw "Could not parse version from $PubspecPath"
}

$ReleaseDir = Join-Path $Root "build\windows\x64\runner\Release"
$logoCandidates = @(
    (Join-Path $Root "assets\brand\app_icon.png"),
    (Join-Path $Root "windows\runner\resources\app_icon.png")
)

if (-not $SkipFlutterBuild) {
    Write-Host "Building Flutter release..." -ForegroundColor Yellow
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows --release failed" }
}

if (-not (Test-Path (Join-Path $ReleaseDir "focusmith.exe"))) {
    throw "Release build not found. Run flutter build windows --release first."
}

$hasLogo = $false
foreach ($logo in $logoCandidates) {
    if (Test-Path $logo) {
        $hasLogo = $true
        break
    }
}

if (-not $hasLogo) {
    $warn = @"
MSIX logo not found. Add one of:
  assets\brand\app_icon.png   (recommended, 512x512 PNG)
  windows\runner\resources\app_icon.png

Skipping MSIX. Installer/portable build is unaffected.
"@
    Write-Host $warn -ForegroundColor Yellow
    exit 0
}

Write-Host "Creating MSIX package..." -ForegroundColor Yellow
dart run msix:create
if ($LASTEXITCODE -ne 0) { throw "msix:create failed" }

$version = Get-AppVersion (Join-Path $Root "pubspec.yaml")
$info = @"
MSIX build complete. Look for *.msix in the project root or build output.

Install (sideload):
  Right-click the .msix -> Install
  or: Add-AppxPackage -Path .\FOCUSMITH_<version>.msix

Uninstall:
  Settings -> Apps -> FOCUSMITH -> Uninstall
"@
Write-Host $info -ForegroundColor Green
