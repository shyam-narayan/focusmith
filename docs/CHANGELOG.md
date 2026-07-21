# Changelog

All notable changes to the FOCUSMITH project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] — 2026-07-21

Rebrand release (`1.2.0+3`).

### Changed
- Application renamed from **PRIOTODO** to **FOCUSMITH** (focus + smith) across UI, docs, Windows binary, and project layout.
- Export package extension: `.focusmith` (was `.priotodo`).
- SQLite database file: `focusmith.db` (was `priotodo.db`).
- Dart package / project name: `focusmith`.

### Docs
- README, overview, handbook, progress, release notes, and changelog updated for FOCUSMITH.

## [1.1.0] — 2026-07-20

Polish and reliability release (`1.1.0+2`).

### Added
- First-launch **Welcome to FOCUSMITH** story (single note explaining the product); no demo seed pack.
- Save-on-window-close (`prepareForAppExit`); export flushes open editor buffers first.
- History snapshot cap (20 per story).

### Changed
- Search UX finalized: **Ctrl+F** = find in current story; **Ctrl+Shift+F** = global search (title bar). Removed File / Tabs / All scope chips.
- Local find bar clears when switching tabs; Esc closes find then dismisses global search.
- Settings Autosave toggle rebuilt as a `ConsumerWidget` so it updates correctly.

### Fixed
- Caret/selection no longer marks the document unsaved or triggers autosave.
- Flush pending autosave before creating a story; persist closed-tab buffers.
- Quill controllers disposed after the editor switches away (avoids used-after-dispose).
- Editor rebuilds when a controller becomes ready (`controllerEpoch`).
- Title rename commits when switching stories while the title field is focused.
- Concurrent save / controller ensure / priority reorder serialized.
- Global FTS queries sanitized (quoted tokens) with live-buffer fallback.
- Priority Board drag proxy overflow on the trailing menu control.

### Docs
- README, overview, handbook, progress, and release notes aligned to `1.1.0+2`.

## [1.0.0] — 2026-07-17

First production iteration (`1.0.0+1`). Consolidates the alpha.1 / alpha.2 workspace into a shippable Windows desktop app.

### Added
- Full workspace shell: custom title bar, story tabs, Quill editor, Priority Board, status bar.
- SQLite stories/notes/history + FTS5 full-text index; Hive window and workspace restore.
- Riverpod workspace orchestration (tabs, selection, zoom, save status, search, rearrange mode).
- Custom Quill toolbar (undo/redo, paragraph styles, inline formats, color, lists, quote, smart code, separator, clear formatting).
- Dedicated story title field separate from the document body.
- Manual save (`Ctrl+S`) with optional Settings autosave (2s debounce); unsaved/saving/saved/error status and history snapshots.
- Priority Board: drag reorder, create/delete, double-click rename, rearrange-mode toggle for `Alt+Shift+↑/↓`.
- Search overlay; seed stories for empty databases (replaced in 1.1.0 by a single welcome note).
- Settings: autosave toggle; export workspace as `.focusmith`. Dark theme only.
- AI-ready service skeleton (`AiWorkspaceService`).
- Window geometry persistence and Mica/acrylic on Windows.
- App icon (taskbar / `.exe`) matching the title-bar checkmark brand mark.
- App-wide **Satoshi** typeface; monospace only for code.

### Fixed
- Editor caret/focus stability (per-story focus + scroll controllers).
- Heading styles apply real size/weight; list marker–to–text spacing.
- Click below last line places caret at end of document.
- Open-tab restore: empty tab set stays empty (placeholder); non-empty set restores exactly.
- Ctrl+Z / Ctrl+Shift+Z respect plain-text fields vs Quill document history.
- Priority shortcuts gated behind rearrange mode so the editor does not steal them unexpectedly.

### Changed
- Optional Autosave via Settings (off by default); `Ctrl+S` always works.
- Removed Priority Board filter control; rename removed from ⋮ menu (double-click only).
- Search results render as an overlay instead of pushing the main layout.

### Docs
- README, overview, developer handbook, progress tracker, and release notes aligned to 1.0.0+1.

## [1.0.0-alpha.2] — 2026-07-17

Pre-release workspace assembly and editor/board polish (superseded by 1.0.0).

### Added
- Workspace shell, SQLite/Hive, Quill, seed data, settings export, AI skeleton.

### Fixed / Changed
- Toolbar, title/body split, tab persistence, rearrange mode, search, undo/redo, list/separator polish (see 1.0.0).

## [1.0.0-alpha.1] — 2026-07-17

### Added
- Initial Feature-First project structure and core dependencies.
- Architecture docs (`PROJECT_OVERVIEW.md`, `DEVELOPMENT.md`).
