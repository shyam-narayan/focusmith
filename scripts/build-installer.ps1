# Builds FOCUSMITH for Windows: release binary, Inno Setup installer, portable ZIP.
# Prerequisites: Flutter SDK, Inno Setup 6 (https://jrsoftware.org/isinfo.php)
#
# Usage:
#   .\scripts\build-installer.ps1
#   .\scripts\build-installer.ps1 -SkipFlutterBuild
#   .\scripts\build-installer.ps1 -PortableOnly

param(
    [switch]$SkipFlutterBuild,
    [switch]$PortableOnly,
    [switch]$SkipInstaller
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $Root

function Get-AppVersion {
    param([string]$PubspecPath)
    $content = Get-Content $PubspecPath -Raw
    if ($content -match '(?m)^version:\s*([\d.]+)\+(\d+)\s*$') {
        return @{
            Version = $Matches[1]
            Build   = $Matches[2]
        }
    }
    throw "Could not parse version from $PubspecPath"
}

function Find-InnoSetupCompiler {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    foreach ($path in $candidates) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

$versionInfo = Get-AppVersion (Join-Path $Root "pubspec.yaml")
$AppVersion = $versionInfo.Version
$AppBuild = $versionInfo.Build
$ReleaseDir = Join-Path $Root "build\windows\x64\runner\Release"
$DistDir = Join-Path $Root "dist"

Write-Host "FOCUSMITH Windows packaging - v$AppVersion ($AppBuild)" -ForegroundColor Cyan

if (-not $SkipFlutterBuild) {
    Write-Host "`n[1/3] Building Flutter release..." -ForegroundColor Yellow
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "flutter build windows --release failed" }
} else {
    Write-Host "`n[1/3] Skipping Flutter build (-SkipFlutterBuild)" -ForegroundColor DarkGray
}

if (-not (Test-Path (Join-Path $ReleaseDir "focusmith.exe"))) {
    throw "Release build not found: $ReleaseDir\focusmith.exe`nRun without -SkipFlutterBuild first."
}

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null

Write-Host "`n[2/3] Creating portable ZIP..." -ForegroundColor Yellow
$zipPath = Join-Path $DistDir "FOCUSMITH-$AppVersion-win64-portable.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $ReleaseDir "*") -DestinationPath $zipPath -CompressionLevel Optimal
Write-Host "  -> $zipPath" -ForegroundColor Green

if ($PortableOnly) {
    Write-Host "`nDone (portable only)." -ForegroundColor Cyan
    exit 0
}

if ($SkipInstaller) {
    Write-Host "`nDone (installer skipped)." -ForegroundColor Cyan
    exit 0
}

Write-Host "`n[3/3] Compiling Inno Setup installer..." -ForegroundColor Yellow
$iscc = Find-InnoSetupCompiler
if (-not $iscc) {
    $msg = @"

Inno Setup 6 was not found. Install it from:
  https://jrsoftware.org/isinfo.php

Portable ZIP was still created at:
  $zipPath

After installing Inno Setup, re-run:
  .\scripts\build-installer.ps1 -SkipFlutterBuild

"@
    Write-Host $msg -ForegroundColor Yellow
    exit 1
}

$issPath = Join-Path $Root "installer\focusmith.iss"
& $iscc "/DMyAppVersion=$AppVersion" "/DMyAppBuild=$AppBuild" $issPath
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed" }

$setupPath = Join-Path $DistDir "FOCUSMITH-Setup-$AppVersion.exe"
Write-Host "  -> $setupPath" -ForegroundColor Green

$done = @"

Done. Artifacts in dist\:
  FOCUSMITH-Setup-$AppVersion.exe     (installer - use for end users)
  FOCUSMITH-$AppVersion-win64-portable.zip

Install:   run the Setup exe
Uninstall: Settings -> Apps -> FOCUSMITH
             (optional prompt to delete %APPDATA%\FOCUSMITH data)

"@
Write-Host $done -ForegroundColor Cyan
