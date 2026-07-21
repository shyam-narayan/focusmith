# FOCUSMITH Developer Handbook

Technical architecture, schema, and conventions for **FOCUSMITH 1.2.0+3**.

---

## 1. Architectural blueprint

FOCUSMITH uses **Feature-First Clean Architecture**.

### Layers
1. **Presentation** — Fluent UI widgets, Riverpod watchers, local widget state.
2. **Domain** — Immutable entities and repository contracts (`Story`, `Note`, …).
3. **Data** — SQLite repositories, Hive preferences, seed/export helpers.

### State
- Primary orchestrator: `WorkspaceNotifier` / `workspaceProvider` (`lib/features/workspace/presentation/providers/workspace_provider.dart`).
- Holds stories, open tabs, selection, zoom, save status, search UI mode, rearrange mode, Quill controllers (per story).
- Dirty detection listens to Quill `document.changes` (not selection-only notifies).
- Seed runs once in `main()` when the stories table is empty.

---

## 2. Folder structure

```
lib/
├── main.dart
├── core/
│   ├── constants/          # AppColors, AppFonts
│   ├── database/           # SqliteService, HiveStorageService
│   ├── helpers/            # Debouncer (autosave)
│   ├── logging/
│   ├── services/           # BackupService, AiWorkspaceService
│   ├── settings/           # App settings (autosave, etc.)
│   ├── theme/
│   └── widgets/            # AppTitleBar
└── features/
    ├── workspace/          # Shell, tabs, domain/data for stories & notes
    ├── priority/           # Priority Board UI
    ├── editor/             # Quill panel, toolbar, find bar, embeds, status bar
    ├── search/             # SearchService + results panel
    ├── settings/           # Settings dialog
    └── history/            # Snapshot repository on save (capped)
```

---

## 3. Database schema

**SQLite** — relational + FTS. **Hive** — window/workspace preferences.

### Stories
| Column | Type | Notes |
|--------|------|--------|
| id | TEXT PK | UUID |
| title | TEXT | |
| priority | INTEGER | Ascending = higher on board |
| status | TEXT | e.g. todo |
| color | INTEGER | Accent |
| createdAt / updatedAt | INTEGER | Epoch ms |

### Notes
| Column | Type | Notes |
|--------|------|--------|
| id | TEXT PK | |
| storyId | TEXT UNIQUE FK | One note per story |
| deltaJson | TEXT | Quill Delta JSON |
| updatedAt | INTEGER | |

### History
Snapshots of `deltaJson` keyed by `storyId` (written on successful save; max 20 per story).

### stories_fts (FTS5)
`storyId` (UNINDEXED), `title`, `content` (plain text derived from Delta). Synced on note upsert / story update / delete. Global search quotes tokens for safe `MATCH`.

### Hive boxes
| Box | Keys (typical) |
|-----|----------------|
| `settings` | autosave_enabled |
| `window_state` | width, height, x, y |
| `workspace_state` | `openTabIds`, `selectedStoryId`, `zoom` |

---

## 4. Keyboard shortcuts (implemented)

### Workspace
| Shortcut | Action |
|----------|--------|
| `Ctrl+N` | New story |
| `Ctrl+W` | Close active tab |
| `Ctrl+S` | Save active story |
| `Ctrl+F` | Find in current story |
| `Ctrl+Shift+F` | Search all stories |
| `Esc` | Close find / dismiss search |
| `F3` / `Shift+F3` | Next / previous local match |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Cycle tabs |
| `Alt+Shift+↑/↓` | Move priority (**rearrange mode only**) |

### Editor (body focused)
| Shortcut | Action |
|----------|--------|
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo / redo document |
| `Ctrl+B` / `I` / `U` | Bold / italic / underline |
| `Ctrl+E` | Smart code (inline vs block) |
| `Ctrl+Alt+1/2/3/0` | H1 / H2 / H3 / paragraph |

### Not implemented
`Ctrl+Shift+S` (save all), `Ctrl+P` (quick open).

---

## 5. Design decisions

- **Fluent UI** — Windows 11-like dark charcoal + purple accent (`AppColors`).
- **Typography** — Single UI font: **Satoshi** (`AppFonts.family`). `Consolas` only for code blocks.
- **Acrylic / Mica** — `flutter_acrylic` on Windows startup.
- **Manual save** — Explicit `Ctrl+S`; optional Autosave (Settings). Window close and export flush unsaved buffers.
- **Theme** — Dark only; no theme switcher.
- **Title ≠ body** — Title field is separate; Quill body does not own the story title heading.
- **Search** — `Ctrl+F` local find; `Ctrl+Shift+F` global (FTS5 + live open buffers).
- **First launch** — One welcome story; user owns the workspace after closing it.
- **AI** — `AiWorkspaceService` is a placeholder for future plugins.

---

## 6. Build & analyze

```bash
flutter pub get
flutter analyze
flutter run -d windows
flutter build windows --release
```

Version comes from `pubspec.yaml`: `version: 1.2.0+3`.

### Windows installer & distribution

```powershell
# Installer (.exe) + portable ZIP — requires Inno Setup 6
.\scripts\build-installer.ps1

# Above + MSIX (needs assets/brand/app_icon.png)
.\scripts\build-all.ps1
```

| Script | Output |
|--------|--------|
| `scripts/build-installer.ps1` | `dist/FOCUSMITH-Setup-<ver>.exe`, portable ZIP |
| `scripts/build-msix.ps1` | `.msix` package |
| `scripts/build-all.ps1` | All of the above |

Full details: [installer/README.md](../installer/README.md)

---

## 7. Related docs

- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) — product vision  
- [PROGRESS.md](PROGRESS.md) — milestone tracker  
- [RELEASE_NOTES.md](RELEASE_NOTES.md) — user-facing notes  
- [CHANGELOG.md](CHANGELOG.md) — version history  
