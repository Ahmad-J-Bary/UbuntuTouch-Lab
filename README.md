# MiniNotes

MiniNotes is a small, offline-first and privacy-friendly notes application built with Qt, QML and C++.

The project started as a native Ubuntu Touch application and is now being reorganized into a layered, multiplatform architecture with the goal of sharing as much code as possible across Linux desktop, Windows, macOS, Android and iOS, while keeping Ubuntu Touch support.

|                             |                                                       |
| --------------------------- | ----------------------------------------------------- |
| Current development version | **0.2.4**                                             |
| Status                      | **Experimental / Development**                        |
| Current OpenStore release   | **0.2.4**                                             |
| OpenStore target            | Ubuntu Touch `24.04-1.x` / Qt 5.15 compatibility path |
| Development target          | Qt 6                                                  |
| Architecture                | ARM64 for the current Ubuntu Touch release            |
| Tested device               | POCO X3 NFC (`surya`)                                 |
| Frontend                    | QML / Qt Quick Controls                               |
| Core language               | C++17                                                 |
| Database                    | SQLite                                                |
| Build system                | CMake + Clickable                                     |

---

## Project goals

MiniNotes is being developed around a shared application core and platform-specific targets.

The main goals are:

* Keep the domain and application logic independent from a specific platform.
* Share the maximum amount of C++ and QML code between targets.
* Keep SQLite access behind a repository abstraction.
* Keep QML responsible for presentation and user interaction.
* Support touch-friendly mobile interfaces without creating separate application codebases for every platform.
* Preserve a native Qt architecture suitable for Linux, Windows, macOS, Android, iOS and Ubuntu Touch.
* Maintain reliable automated tests while continuously validating the application on a real Ubuntu Touch device.

---

# Current status — 0.2.4

MiniNotes currently provides a complete local note workflow:

* Create notes.
* Validate title and content.
* Persist notes in SQLite.
* Browse stored notes.
* Open existing notes.
* Edit existing notes.
* Update `updated_at`.
* Permanently delete notes.
* Swipe to reveal the delete action.
* Confirm permanent deletion.
* Refresh the note list after save, update or delete.
* Handle Arabic, English, emoji and special characters.
* Provide touch-friendly controls and scalable mobile dimensions.

The current development branch is also being reorganized from the original Ubuntu Touch-focused structure into a layered architecture intended for multiple platforms.

---

# Current features

## Create Note

Status: **Implemented**

The create workflow provides:

* Title validation.
* Content validation.
* SQLite persistence.
* Prepared SQL statements.
* Duplicate-save protection.
* UTF-8 support.
* Automatic return to the note list after a successful save.

## Browse and Edit Notes

Status: **Implemented**

Stored notes are exposed to QML through a Qt model.

Each note currently provides:

* Title.
* Content preview.
* Last-updated timestamp.
* Touch-friendly interaction.

Opening a note loads the editing page, where the user can update the title and content.

## Delete Note

Status: **Implemented**

A note can be deleted by swiping its card horizontally.

The workflow is:

```text
Note card
   │
   │ swipe
   ▼
Reveal Delete action
   │
   ▼
Confirmation dialog
   │
   ├── Delete → permanent SQLite DELETE
   │
   └── Cancel → close dialog
```

Deletion uses a prepared SQL statement:

```sql
DELETE FROM notes WHERE id = ?;
```

The confirmation dialog uses separate Delete and Cancel actions and is designed for touch interaction.

---

# Architecture

The project is currently being migrated from a direct controller-to-SQLite design to a layered architecture.

The current architecture is:

```text
                         QML UI
                           │
                           ▼
                    NoteController
                           │
                           ▼
                    INoteRepository
                           ▲
                           │
                 SqliteNoteRepository
                           │
                           ▼
                        Database
                           │
                           ▼
                         SQLite
```

## Domain

Located under:

```text
src/domain/
```

The domain layer currently contains:

```text
note.h
inote_repository.h
```

`Note` represents the note data structure.

`INoteRepository` defines the storage contract without depending on a specific storage implementation.

The domain layer does not depend on SQLite.

## Application

Located under:

```text
src/application/
```

This layer is reserved for application-level use cases such as `NoteService`.

The application service layer is the next major refactoring step.

## Data

Located under:

```text
src/data/
└── sqlite/
    ├── database.h
    ├── database.cpp
    ├── sqlite_note_repository.h
    └── sqlite_note_repository.cpp
```

This layer contains the current SQLite implementation.

`SqliteNoteRepository` implements `INoteRepository` and is responsible for persistence.

## Presentation

Located under:

```text
src/presentation/
```

Current files:

```text
note_controller.h
note_controller.cpp
note_list_model.h
note_list_model.cpp
```

`NoteController` exposes application operations to QML.

`NoteListModel` adapts stored notes to Qt's model/view system.

The presentation layer does not depend directly on SQLite.

## Application entry point

Located at:

```text
src/app/main.cpp
```

The application entry point acts as the composition root. It creates the concrete SQLite implementation and injects it into the presentation layer.

---

# QML structure

The QML code is now organized by responsibility:

```text
qml/
├── Main.qml
├── pages/
│   ├── CreateNotePage.qml
│   ├── EditNotePage.qml
│   └── NotesListPage.qml
├── theme/
│   └── UiMetrics.qml
├── components/
├── navigation/
└── platform/
```

`Main.qml` is the QML entry point.

The page files contain the current application screens.

`UiMetrics.qml` provides centralized UI scaling.

The `components`, `navigation` and `platform` directories are reserved for the next stages of the multiplatform UI refactoring.

---

# UI and responsive design

The project uses a centralized QML metrics system:

```text
qml/theme/UiMetrics.qml
```

The goal is to keep:

* Margins.
* Spacing.
* Typography.
* Card dimensions.
* Button sizes.
* Touch targets.

consistent without duplicating scaling logic across every page.

The long-term UI architecture is intended to adapt to phone, tablet and desktop layouts while keeping the core QML components shared.

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

The SQLite database is stored using Qt's platform-aware application data location.

---

# Data flow

## Create

```text
CreateNotePage.qml
       │
       ▼
NoteController::saveNote()
       │
       ▼
INoteRepository
       │
       ▼
SqliteNoteRepository
       │
       ▼
SQLite INSERT
```

## Read

```text
NotesListPage.qml
       │
       ▼
NoteController
       │
       ▼
INoteRepository
       │
       ▼
SqliteNoteRepository
       │
       ▼
NoteListModel
       │
       ▼
QML ListView
```

## Update

```text
EditNotePage.qml
       │
       ▼
NoteController::updateNote()
       │
       ▼
INoteRepository
       │
       ▼
SqliteNoteRepository
       │
       ▼
SQLite UPDATE
```

## Delete

```text
NotesListPage.qml
       │
       ▼
Delete confirmation
       │
       ▼
NoteController::deleteNote()
       │
       ▼
INoteRepository
       │
       ▼
SqliteNoteRepository
       │
       ▼
SQLite DELETE
```

---

# Validation and persistence

User-facing validation is currently exposed through the presentation layer while the data is persisted through the repository layer.

The system supports:

```text
Arabic
English
Emoji
Quotes
Backslashes
Semicolons
Multiline text
UTF-8 content
```

SQLite writes use prepared statements with bound parameters.

---

# Testing

The current backend test suite is located at:

```text
tests/tst_backend.cpp
```

It currently covers:

* Valid note creation.
* Empty title.
* Empty content.
* Long UTF-8 text.
* Special characters.
* Duplicate save requests.
* Database failure.
* Persistence across reopen.
* Listing notes.
* Finding notes by ID.
* Updating notes.
* Deleting notes.

Build and run the tests:

```sh
cmake -S . -B build/refactor \
    -DCMAKE_BUILD_TYPE=Debug \
    -DMININOTES_BUILD_TESTS=ON

cmake --build build/refactor -j"$(nproc)"

ctest --test-dir build/refactor --output-on-failure
```

The current refactoring checkpoint passes:

```text
100% tests passed
```

---

# Host development

The current development environment uses Qt 6.

Install the required development packages on Ubuntu:

```sh
sudo apt install \
    cmake \
    qt6-base-dev \
    qt6-declarative-dev \
    libqt6sql6-sqlite \
    qml6-module-qtquick \
    qml6-module-qtquick-window \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-templates \
    qml6-module-qtquick-layouts \
    qml6-module-qtqml-workerscript
```

Configure:

```sh
cmake -S . \
    -B build/refactor \
    -DCMAKE_BUILD_TYPE=Debug \
    -DMININOTES_BUILD_TESTS=ON
```

Build:

```sh
cmake --build build/refactor -j"$(nproc)"
```

Test:

```sh
ctest --test-dir build/refactor --output-on-failure
```

---

# Ubuntu Touch

The currently published OpenStore release uses:

```text
Framework: ubuntu-touch-24.04-1.x
Qt: Qt 5 compatibility path
Architecture: arm64
```

This compatibility target exists because the OpenStore review path currently supports the 24.04-1.x AppArmor policy while the 24.04-2.x reviewer path has a known policy-data limitation.

The shared application architecture is intentionally being kept independent from this packaging choice.

Ubuntu Touch development remains an important target and is continuously tested on:

```text
POCO X3 NFC
Codename: surya
Architecture: arm64
```

Build and install using Clickable:

```sh
clickable build --arch arm64 --skip-review
clickable install --arch arm64
clickable launch --arch arm64 --skip-kill
```

Runtime logs:

```sh
clickable log --arch arm64
```

---

# Multiplatform roadmap

The project is being reorganized so that most of the source code can be shared between platforms.

Planned targets:

```text
Linux desktop
Windows
macOS
Android
iOS
Ubuntu Touch
```

The intended structure is:

```text
Shared Domain
      │
      ▼
Application Services
      │
      ▼
Repository Abstractions
      │
      ├── SQLite
      └── Other platform/data implementations
      │
      ▼
Shared QML UI
      │
      ├── Linux
      ├── Windows
      ├── macOS
      ├── Android
      ├── iOS
      └── Ubuntu Touch
```

Platform-specific code will be isolated rather than duplicated throughout the shared application logic.

---

# Current refactoring roadmap

The multiplatform architecture is being introduced incrementally:

```text
✅ Establish Git feature branch
✅ Create layered project structure
✅ Reorganize C++ source files
✅ Reorganize QML pages and theme
✅ Verify host build
✅ Verify backend tests
✅ Introduce INoteRepository
⬜ Introduce NoteService
⬜ Separate platform services
⬜ Extract reusable QML components
⬜ Add CMake presets
⬜ Linux desktop target
⬜ Windows target
⬜ macOS target
⬜ Android target
⬜ iOS target
⬜ Platform-specific packaging and CI
```

The project is intentionally refactored in small, testable stages so that the existing Ubuntu Touch application remains functional throughout the migration.

---

# Development policy

A change should be considered complete only when:

1. The C++ implementation builds successfully.
2. Existing backend tests pass.
3. QML references remain valid.
4. Persistence behavior remains intact.
5. Ubuntu Touch behavior remains functional where applicable.
6. New user-facing workflows have appropriate automated coverage.
7. `README.md` reflects the actual project state.

The project keeps one canonical documentation file:

```text
README.md
```

No version-specific README files are maintained.

---

# Release strategy

The current OpenStore release and the multiplatform development branch are intentionally separated.

The project will remain in the `0.x` development series while the architecture and platform targets are still evolving.

A new minor version will be used for meaningful user-facing milestones rather than for every internal refactoring step.

`1.0.0` will be considered only after the shared architecture and the initial platform targets are sufficiently stable for a production release.
