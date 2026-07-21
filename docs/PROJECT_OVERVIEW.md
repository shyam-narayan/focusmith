# FOCUSMITH: The Focus-Driven Workspace

> "What should I work on right now?"

**FOCUSMITH** (*focus + smith*) is a premium, minimal, keyboard-first Windows desktop workspace for software developers and professionals. It combines the focus of a clean notes app, the utility of VS Code tabs, and the prioritization power of a task board into one lightweight native application.

**Current release:** **1.2.0+3** (July 2026)

---

## The Vision

FOCUSMITH is **not** a typical to-do list, a generic note-taking app, or a bloated project-management tool. It is a highly focused personal workspace.

Professionals spend their workdays jumping between client stories, debug logs, meeting notes, API paths, and hotfixes. FOCUSMITH sits at the center of this workflow and constantly answers: **"What should I work on right now?"**

The core of the application is the **Priority Board**. Every workspace document (a **Story**) belongs to this board. Priority order drives what you see next; open tabs and the active story restore across sessions.

---

## Key Features (v1.2.0)

1. **Priority Board** — Sidebar with rank, title, status, drag reorder, double-click rename, and create/delete.
2. **Rearrange mode** — Toggle next to `+`; while active, `Alt+Shift+↑/↓` moves the selected story. Helper tips show only in this mode; leaving for the editor exits the mode (order already persisted).
3. **Tabbed workspace** — Open tabs persist across restarts. Closing all tabs restores the empty placeholder (“Select or create a story…”).
4. **Rich text workspace** — Quill-backed body with a Jira-style toolbar (undo/redo, headings, inline formats, color, lists, quote, smart code, document separator). Story **title** is a separate field above the body.
5. **Save** — `Ctrl+S` always; optional Autosave in Settings; unsaved work flushed on window close and before export.
6. **Search** — `Ctrl+F` finds in the active story; `Ctrl+Shift+F` searches the whole workspace (FTS5 + live open buffers). `Esc` closes find / dismisses results.
7. **First launch** — A single welcome note explains the product; after you close it, the workspace is yours.
8. **Persistence** — SQLite for stories/notes/history/FTS; Hive for window geometry, open tabs, selection, zoom, and settings.
9. **Settings & backup** — Autosave toggle; export workspace as a `.focusmith` JSON package.
10. **AI-ready skeleton** — Local service contract for future assistants/plugins (not wired to a provider).

---

## Target Audience

- **Software engineers & architects** — Tasks, bug details, stack traces, daily notes.
- **Freelancers & consultants** — Client objectives, milestones, working notes.
- **Product managers & professionals** — Priorities, meeting minutes, action items.

---

## Milestone Status

Founding milestones are **complete**; 1.1.0 adds search polish and reliability. See [PROGRESS.md](PROGRESS.md).

| Milestone | Status |
|-----------|--------|
| M1 — Bootstrap, Fluent theme, window bindings | Done |
| M2 — SQLite schema | Done |
| M3 — App shell & Priority Board | Done |
| M4 — Quill editor & tabs | Done |
| M5 — Save & workspace persistence | Done |
| M6 — FTS search & editor undo/redo | Done |
| M7 — `.focusmith` export | Done |
| M8 — AI-ready service skeleton | Done |

---

## Post–1.1 ideas (not committed)

- Import `.focusmith` packages
- Save-all / quick-open
- Tags and status workflows
- Multi-pane / custom splitter widths
- Optional AI provider plugins

---

## Frequently Asked Questions

### Is my data secure and private?
Yes. FOCUSMITH runs entirely locally. Stories and notes live in SQLite on your machine. There is no cloud sync or telemetry by default.

### Can I run this on Mac or Linux?
Windows is the primary target (Fluent styling, Mica, Windows shortcuts). The Flutter codebase can be built elsewhere, but those platforms are not first-class.

### What is a "Story"?
A Story is the primary unit of work: metadata (priority, status, title, color) plus an attached rich-text document body.
