# Windows distribution

FOCUSMITH ships as a Flutter Windows desktop app. Use the scripts below to produce installable artifacts.

## Prerequisites

| Tool | Purpose | Download |
|------|---------|----------|
| Flutter SDK | Build `focusmith.exe` | [flutter.dev](https://flutter.dev) |
| Inno Setup 6 | `.exe` installer + uninstaller | [jrsoftware.org](https://jrsoftware.org/isinfo.php) |
| (Optional) MSIX | `.msix` package for sideload/Store | Added via `msix` dev dependency |

## Quick build (recommended)

From the project root in PowerShell:

```powershell
.\scripts\build-installer.ps1
```

This will:

1. Run `flutter build windows --release`
2. Create `dist/FOCUSMITH-<version>-win64-portable.zip`
3. Compile `dist/FOCUSMITH-Setup-<version>.exe` (if Inno Setup is installed)

**Full build** (installer + portable + MSIX when logo is present):

```powershell
.\scripts\build-all.ps1
```

## Output artifacts

| File | Use |
|------|-----|
| `dist/FOCUSMITH-Setup-1.2.0.exe` | End-user installer (Start Menu, Add/Remove Programs) |
| `dist/FOCUSMITH-1.2.0-win64-portable.zip` | Portable — unzip and run `focusmith.exe` |
| `*.msix` | Modern Windows package (sideload or Store) |

## End users — install

1. Run `FOCUSMITH-Setup-<version>.exe`
2. Follow the wizard (optional desktop shortcut)
3. Launch from Start Menu → **FOCUSMITH**

## End users — uninstall

1. **Settings → Apps → Installed apps → FOCUSMITH → Uninstall**  
   or Start Menu → **Uninstall FOCUSMITH**
2. The uninstaller asks whether to also delete local workspace data:
   - **Yes** — removes `%APPDATA%\FOCUSMITH` (stories, notes, settings)
   - **No** — keeps your data for a future reinstall

Portable installs: delete the unzipped folder. User data in `%APPDATA%\FOCUSMITH` is unchanged unless you delete it manually.

## MSIX (optional)

Requires `assets/brand/app_icon.png` (512×512 PNG recommended).

```powershell
.\scripts\build-msix.ps1
```

Install: double-click the `.msix` or `Add-AppxPackage -Path .\package.msix`  
Uninstall: Settings → Apps → FOCUSMITH

For production MSIX/Store submission you need a code-signing certificate (`msix_config.certificate_path` in `pubspec.yaml`).

## Version sync

Keep these aligned when releasing:

- `pubspec.yaml` → `version: 1.2.0+3`
- `msix_config.msix_version` → `1.2.0.0` (four-part MSIX version)
- Installer version is read automatically from `pubspec.yaml` by the build script

## Code signing (optional)

Unsigned installers may trigger Windows SmartScreen. For wider distribution, sign the setup executable with an Authenticode certificate:

```powershell
signtool sign /fd SHA256 /a /tr http://timestamp.digicert.com /td SHA256 dist\FOCUSMITH-Setup-1.2.0.exe
```

## Manual Inno Setup compile

```powershell
flutter build windows --release
& "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" /DMyAppVersion=1.2.0 /DMyAppBuild=3 installer\focusmith.iss
```

Script: [`focusmith.iss`](focusmith.iss)
