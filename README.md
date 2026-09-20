# MiniNotes (Ubuntu Touch)

MiniNotes is a small, offline-first, privacy-friendly notes application for Ubuntu Touch.

The project is built as a native Ubuntu Touch application using **QML + Qt 6** for the frontend, **C++17** for the application/backend layer, and **SQLite** for persistent local storage.

The project is developed incrementally: each feature is implemented, tested, and verified on the real Ubuntu Touch device before moving to the next milestone.

| | |
|---|---|
| Current version | **0.2.1** |
| Status | **Experimental / Development** |
| Platform | Ubuntu Touch |
| Target architecture | arm64 |
| Framework | `ubuntu-touch-24.04-2.x` |
| Device used for testing | POCO X3 NFC (`surya`) |
| UI | QML / Qt Quick Controls |
| Backend | C++17 |
| Database | SQLite |
| Build system | CMake + Clickable |

---

## Project goals

MiniNotes focuses on native Ubuntu Touch development with a clean separation between UI and data access.

Core principles:

- QML is responsible for presentation, navigation, and user interaction.
- C++ is responsible for application logic and data access.
- QML never accesses SQLite directly.
- The C++ layer re-validates user input before writing to the database.
- Database writes use prepared statements with bound parameters.
- Touch targets and spacing must be comfortable on mobile screens.
- Arabic, English, emoji, and special characters must round-trip correctly.
- Each completed feature is verified on the real Ubuntu Touch device.

---

# Current status — 0.2.1

Version **0.2.1** extends the basic create/read/update workflow with permanent deletion and a dedicated mobile UX scaling system.

The application currently supports:

- Creating notes.
- Validating title and content.
- Persisting notes in SQLite.
- Browsing stored notes.
- Opening an existing note.
- Editing an existing note.
- Updating `updated_at`.
- Permanently deleting notes.
- Swipe-to-reveal deletion from the note list.
- Confirmation before permanent deletion.
- Real-time list/model refresh after save, update, or delete.
- Arabic, English, emoji, and special-character handling.
- Touch-friendly controls and larger interaction areas.
- Centralized UI scaling through `qml/UiMetrics.qml`.

The current 0.2.1 UX refinement also keeps the delete-confirmation dialog wider without increasing the scale of the controls inside it.

---

# Features

## Feature 1 — Create Note

Status: **Implemented**

The create-note workflow supports:

- Title validation.
- Content validation.
- Prepared SQLite INSERT.
- Duplicate-save protection.
- Save-state feedback.
- UTF-8 content.
- Automatic return to the note list after a successful save.

## Feature 2 — Browse and Edit Notes

Status: **Implemented**

The note list displays stored notes using a Qt model exposed by the C++ controller.

Each note shows:

- Title.
- Content preview.
- Last-updated timestamp.
- A large touch-friendly card.

Tapping a note opens `EditNotePage.qml`, where the user can edit the title and content and save the changes.

## Feature 3 — Delete Note

Status: **Implemented**

A note can be deleted by swiping it horizontally to reveal the delete action.

The flow is:

```text
Note card
   │
   │ swipe
   ▼
Reveal Delete action
   │
   ▼
Delete note?
   │
   ├── Delete   → permanent SQLite DELETE
   │
   └── Cancel   → close dialog
```

Deletion is implemented in C++ using a prepared statement:

```sql
DELETE FROM notes WHERE id = ?;
```

The delete confirmation dialog uses a vertical action layout:

1. **Delete** — red background, white text.
2. **Cancel** — gray background, white text.

The dialog surface is intentionally wider with fixed padding so the dialog itself has more breathing room without scaling up the controls inside it.

---

# UI/UX system

The project uses a centralized QML metrics object:

```text
qml/UiMetrics.qml
```

It provides a common scale for:

- Margins.
- Header sizes.
- Card sizes.
- Buttons.
- Touch targets.
- Typography.
- Spacing.

The goal is to avoid independently tuning dozens of hard-coded dimensions across pages.

For the delete-confirmation dialog, the width and surface padding are adjusted independently from the control typography so that only the dialog itself becomes more spacious.

---

# Architecture

```text
                         QML UI
                           │
                           │ properties / signals / Q_INVOKABLE
                           ▼
                    NoteController
                           │
                           ├──────────────► NoteListModel
                           │
                           ▼
                    NoteRepository
                           │
                           ▼
                        Database
                           │
                           ▼
                         SQLite
```

### QML

Responsible for:

- Presentation.
- Navigation.
- User interaction.
- Validation feedback.
- Displaying model data.
- Swipe gestures and confirmation UI.

QML does not execute SQL.

### NoteController

Responsible for exposing application operations to QML, managing operation state, refreshing data, and emitting success/failure signals.

Current public operations include:

```text
saveNote()
updateNote()
getNote()
refreshNotes()
refreshNoteCount()
deleteNote()
```

### NoteRepository

Responsible for all SQLite operations:

```text
createNote()
updateNote()
deleteNote()
findNote()
listNotes()
count()
```

All writes use prepared statements.

### NoteListModel

`QAbstractListModel` exposes stored notes to QML using model roles for:

- ID.
- Title.
- Body.
- Created timestamp.
- Updated timestamp.

---

# Database schema

```sql
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

The schema supports the current create/read/update/delete workflow without requiring additional tables.

The SQLite database is stored under Qt's `QStandardPaths::AppDataLocation`.

---

# Data flow

### Create

```text
CreateNotePage.qml
       │
       ▼
NoteController::saveNote()
       │
       ▼
NoteRepository::createNote()
       │
       ▼
SQLite INSERT
       │
       ▼
noteSaved()
       │
       ▼
Notes list refresh
```

### Read

```text
NotesListPage.qml
       │
       ▼
NoteController::refreshNotes()
       │
       ▼
NoteRepository::listNotes()
       │
       ▼
NoteListModel
       │
       ▼
QML ListView
```

### Update

```text
EditNotePage.qml
       │
       ▼
NoteController::updateNote()
       │
       ▼
NoteRepository::updateNote()
       │
       ▼
SQLite UPDATE
       │
       ▼
noteUpdated()
       │
       ▼
Notes list refresh
```

### Delete

```text
NotesListPage.qml
       │
       ▼
swipe → Delete
       │
       ▼
confirmation dialog
       │
       ▼
NoteController::deleteNote()
       │
       ▼
NoteRepository::deleteNote()
       │
       ▼
SQLite DELETE
       │
       ▼
noteDeleted()
       │
       ▼
Notes list refresh
```

---

# Validation and persistence

Validation is intentionally multi-layered.

The QML layer provides immediate user feedback, while the C++ layer performs the final validation before a database operation.

Examples:

```text
Title is required
Content is required
```

UTF-8 data is handled end-to-end, including Arabic, emoji, quotes, backslashes, semicolons, and multiline content.

---

# Requirements

- Ubuntu Touch 24.04+
- Qt 6 runtime
- CMake >= 3.16
- Clickable >= 8.8
- Docker or Podman for Clickable builds
- ARM64 Ubuntu Touch device for on-device testing

Current device:

```text
POCO X3 NFC
Codename: surya
Architecture: arm64
Ubuntu Touch: 24.04
```

---

# Build on desktop

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4
./build/mininotes
```

---

# Backend tests

Build and run the QtTest suite:

```sh
cmake -S . -B build -DMININOTES_BUILD_TESTS=ON
cmake --build build -j4
ctest --test-dir build --output-on-failure
```

The current suite covers:

- Valid note creation.
- Empty title.
- Empty body.
- Long UTF-8 content.
- Special characters.
- Duplicate save requests.
- Database failure.
- Persistence across reopen.
- Listing notes.
- Finding notes by ID.
- Updating notes.
- Deleting notes.

---

# Headless UI test

Run:

```sh
QT_QPA_PLATFORM=offscreen \
MININOTES_E2E_TEST=1 \
./build/mininotes
```

Expected result for the existing automation path:

```text
AUTOMATION: RESULT PASS
```

The E2E automation should be extended whenever a new critical user-facing workflow is introduced.

---

# Build for Ubuntu Touch

```sh
clickable build --arch arm64 --skip-review
clickable install --arch arm64
clickable launch --arch arm64 --skip-kill
```

View runtime logs:

```sh
clickable log --arch arm64
```

When debugging a launch/runtime issue, inspect the application log before making unrelated UI or backend changes.

---

# Package structure

```text
MiniNotes/
│
├── src/
│   ├── note.h
│   ├── database.h
│   ├── database.cpp
│   ├── noterepository.h
│   ├── noterepository.cpp
│   ├── notecontroller.h
│   ├── notecontroller.cpp
│   ├── notelistmodel.h
│   ├── notelistmodel.cpp
│   └── main.cpp
│
├── qml/
│   ├── Main.qml
│   ├── NotesListPage.qml
│   ├── CreateNotePage.qml
│   ├── EditNotePage.qml
│   └── UiMetrics.qml
│
├── tests/
│   └── tst_backend.cpp
│
├── assets/
│   └── icons/
│       └── mininotes.svg
│
├── CMakeLists.txt
├── clickable.yaml
├── manifest.json.in
├── mininotes.apparmor
├── mininotes.desktop
└── README.md
```

---

# Development and release policy

A feature is considered complete only when:

1. The backend implementation works.
2. The QML workflow works.
3. Validation is covered.
4. Persistent storage is verified.
5. Touch interaction works correctly.
6. The feature is tested on the real Ubuntu Touch device.
7. Runtime logs show no unexpected application errors.
8. `README.md` reflects the actual project state.

The project intentionally keeps one canonical documentation file: **`README.md`**.

No version-specific README files are required.

---

# Release progression

```text
0.1.x
  │
  ├── Create Note
  ├── SQLite persistence
  ├── Browse notes
  └── Edit notes
  │
  ▼
0.2.1
  │
  ├── Stable browse/read/edit workflow
  └── Mobile UI scaling foundation
  │
  ▼
0.2.1
  │
  ├── Swipe-to-reveal Delete
  ├── Permanent SQLite deletion
  ├── Delete confirmation
  ├── Centralized UiMetrics scaling
  ├── Larger touch targets
  └── Delete dialog UX refinement
```

The application remains on **0.2.1** for these UI refinements. The version should not be incremented merely for the delete-dialog styling changes.

---

# Current 0.2.1 UX behavior

The delete confirmation dialog is intentionally designed as a compact mobile confirmation surface:

```text
┌─────────────────────────────────┐
│ Delete note?                    │
│                                 │
│ Note title                      │
│                                 │
│ This note will be permanently   │
│ deleted.                        │
│                                 │
│ ┌─────────────────────────────┐ │
│ │            Delete           │ │  red / white
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │            Cancel           │ │  gray / white
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

Only the dialog surface width/padding is enlarged; the internal control sizing remains governed by the existing 0.2.1 UI metrics.
