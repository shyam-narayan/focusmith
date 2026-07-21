# FOCUSMITH

**Focus-driven Windows desktop workspace** (focus + smith) — rich-text stories, VS Code-style tabs, and a keyboard-first Priority Board.

**Version:** `1.2.0+3`

> “What should I work on right now?”

---

## Run locally

```bash
flutter pub get
flutter run -d windows
```

Release build:

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/focusmith.exe`

### Installable release (Windows)

For an end-user **installer** and **portable ZIP**, install [Inno Setup 6](https://jrsoftware.org/isinfo.php), then:

```powershell
.\scripts\build-installer.ps1
```

Artifacts land in `dist/`:

- `FOCUSMITH-Setup-<version>.exe` — install / uninstall via Settings → Apps
- `FOCUSMITH-<version>-win64-portable.zip` — unzip and run (no installer)

See [installer/README.md](installer/README.md) for MSIX, code signing, and uninstall details.

---

## What’s in 1.2.0

- Rebrand from PRIOTODO to **FOCUSMITH**
- Priority Board with drag reorder and gated `Alt+Shift+↑/↓` rearrange mode
- Tabbed workspace with open-tab persistence across restarts
- Flutter Quill rich editor (title separate from body), custom toolbar, manual `Ctrl+S`
- **Ctrl+F** local find / **Ctrl+Shift+F** global search
- Optional Autosave in Settings; save-on-exit; export flushes open buffers
- Single welcome story on first launch
- SQLite + FTS5 storage, Hive window/workspace restore
- Dark theme only — local-only, no cloud required

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [Project overview](docs/PROJECT_OVERVIEW.md) | Vision, features, FAQs |
| [Progress tracker](docs/PROGRESS.md) | Milestone status |
| [Developer handbook](docs/DEVELOPMENT.md) | Architecture, schema, shortcuts |
| [Changelog](docs/CHANGELOG.md) | Release history |
| [Release notes](docs/RELEASE_NOTES.md) | User-facing notes |

---

## Platform

Windows is the primary target (Fluent UI + Mica). The Flutter codebase is portable, but desktop UX is optimized for Windows.
