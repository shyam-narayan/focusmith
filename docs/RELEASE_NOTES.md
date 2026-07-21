# Release Notes — FOCUSMITH 1.2.0+3

**Release date:** 2026-07-21  
**Build:** `1.2.0+3`  
**Platform:** Windows (primary)

---

## Highlights

**FOCUSMITH** (*focus + smith*) is the new name for the workspace formerly known as PRIOTODO. Same product — priority board, rich editor, tabs, local search — with updated branding, binary name (`focusmith.exe`), and export format (`.focusmith`).

### Rebrand
- Application title, docs, and Windows metadata now say **FOCUSMITH**
- Export extension: `.focusmith`
- Database file: `focusmith.db`

### Priority Board
- Drag to reorder; create stories with `+` or `Ctrl+N`
- Double-click a title to rename
- **Rearrange mode** (sort icon): enables `Alt+Shift+↑/↓` for the selected story

### Editor
- Title field + rich body (headings, lists, color, quote, smart code, separators)
- Manual save with `Ctrl+S`; optional Autosave in Settings
- Undo / redo: `Ctrl+Z` / `Ctrl+Shift+Z`
- Unsaved work is flushed on window close and before export

### Tabs & restore
- Open tabs and the active story restore after quit
- If you closed every tab before quitting, you get the empty placeholder on launch

### Search
- **Ctrl+F** — find in the active story (match strip with ↑/↓)
- **Ctrl+Shift+F** — search all stories (title-bar + results overlay)
- `Esc` closes find / dismisses results; `F3` / `Shift+F3` cycle local matches
- Local find clears when switching tabs

### First launch
- One **Welcome to FOCUSMITH** story explains the product
- Close or delete it — nothing else is pre-created

### Settings
- Autosave on/off (persisted)
- Export workspace to a `.focusmith` file (includes live open buffers)
- Dark theme only

---

## Install / run

**Developers:**

```bash
flutter pub get
flutter run -d windows
# or
flutter build windows --release
```

**End users (installer):** run `FOCUSMITH-Setup-<version>.exe` from the release `dist/` folder (built via `scripts/build-installer.ps1`).

**Uninstall:** Settings → Apps → FOCUSMITH. The uninstaller optionally removes `%APPDATA%\FOCUSMITH` workspace data.

See [installer/README.md](../installer/README.md) for portable ZIP and MSIX packaging.

---

## Privacy

All data stays on your machine (SQLite + Hive under the app support directory). Export is optional and user-initiated.

---

## Upgrading from PRIOTODO

Existing `priotodo.db` data is not migrated automatically. Export from the old build if you need to preserve stories, or start fresh under `focusmith.db`.

---

## What’s next

Useful follow-ups: import `.focusmith`, save-all, quick-open, tags.
