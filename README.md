# MiniNotes

MiniNotes is a small, offline-first and privacy-friendly notes application built with Qt, QML and C++.

The project originally started as a native Ubuntu Touch application and is now being reorganized into a layered, multiplatform architecture so that the same application core and QML UI can be shared across Linux desktop, Windows, macOS, Android and iOS while retaining Ubuntu Touch support.

| Item | Current state |
| --- | --- |
| Development version | **0.2.6** |
| Status | **Experimental / Development** |
| Current OpenStore release | **0.2.5** |
| Ubuntu Touch target | `ubuntu-touch-24.04-1.x` / ARM64 |
| Development Qt target | **Qt 6** |
| Frontend | QML / Qt Quick Controls |
| Core language | C++17 |
| Database | SQLite |
| Build system | CMake + CMake Presets |
| Ubuntu Touch packaging | Clickable |
| Linux desktop target | **Supported / CI validated** |

---

# Project goals

MiniNotes is being developed around a shared application core and platform-specific targets.

The main goals are:

* Keep domain and application logic independent from a specific platform.
* Share the maximum amount of C++ and QML code between targets.
* Keep SQLite access behind a repository abstraction.
* Keep QML responsible for presentation and user interaction.
* Keep platform-specific APIs behind explicit abstractions.
* Support touch-friendly mobile interfaces without maintaining separate application codebases.
* Provide a native Qt architecture suitable for Linux, Windows, macOS, Android, iOS and Ubuntu Touch.
* Maintain reliable automated tests across the supported targets.

---

# Current status — 0.2.6

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
* Provide touch-friendly controls and scalable UI dimensions.
* Run on Linux desktop using the same shared application architecture.
* Run on Ubuntu Touch ARM64 through Clickable.

The current development branch is also being reorganized from the original Ubuntu Touch-focused structure into a layered, multiplatform architecture.

---

# Features

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

---

# Architecture

The project now uses a layered architecture designed to keep platform-specific implementation details isolated.

```text
                         QML UI
                           │
                           ▼
                    NoteController
                           │
                           ▼
                     NoteService
                           │
                           ▼
                 INoteRepository
                           │
                           ▼
              SqliteNoteRepository
                           │
                           ▼
                        Database
                           │
                           ▼
                         SQLite
```

Platform-dependent services are separated from the shared application layers:

```text
                    Application / Domain
                             │
                    platform abstractions
                             │
                             ▼
                       QtPlatformPaths
                             │
                             ▼
                     Qt / OS facilities
```

The intended rule is:

```text
Domain
  ↓
Application
  ↓
Abstractions
  ↓
Platform / Data implementations
```

Shared layers must not depend directly on SQLite, Ubuntu Touch-specific paths, or UI layout details.

---

# Source tree

Current C++ structure:

```text
src/
├── app/
│   └── main.cpp
├── application/
│   ├── note_service.cpp
│   └── note_service.h
├── domain/
│   ├── note.h
│   └── inote_repository.h
├── data/
│   └── sqlite/
│       ├── database.cpp
│       ├── database.h
│       ├── sqlite_note_repository.cpp
│       └── sqlite_note_repository.h
├── presentation/
│   ├── note_controller.cpp
│   ├── note_controller.h
│   ├── note_list_model.cpp
│   └── note_list_model.h
└── platform/
    ├── platform_paths.h
    └── qt/
        ├── qt_platform_paths.cpp
        └── qt_platform_paths.h
```

Current QML structure:

```text
qml/
├── Main.qml
├── pages/
│   ├── CreateNotePage.qml
│   ├── EditNotePage.qml
│   └── NotesListPage.qml
├── components/
│   ├── PageHeader.qml
│   ├── NoteEditorForm.qml
│   ├── NoteCard.qml
│   ├── EmptyNotesState.qml
│   ├── FloatingActionButton.qml
│   └── DeleteNoteDialog.qml
└── theme/
    └── UiMetrics.qml
```

`Main.qml` is the QML entry point.

The `pages` directory contains application screens.

The `components` directory contains reusable presentation components shared by the application pages.

`UiMetrics.qml` provides centralized responsive sizing and typography.

---

# Domain layer

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

`INoteRepository` defines the storage contract without depending on SQLite.

The domain layer contains no Qt SQL or SQLite implementation details.

---

# Application layer

Located under:

```text
src/application/
```

The application layer currently contains:

```text
note_service.h
note_service.cpp
```

`NoteService` owns application-level note validation and use-case coordination.

The service validates user input before delegating persistence to the repository abstraction.

---

# Data layer

Located under:

```text
src/data/sqlite/
```

Current files:

```text
database.h
database.cpp
sqlite_note_repository.h
sqlite_note_repository.cpp
```

`SqliteNoteRepository` implements `INoteRepository` and owns SQLite persistence.

Database writes use prepared statements with bound parameters.

The database schema is:

```sql
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

---

# Presentation layer

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

`NoteController` exposes application operations and state to QML.

`NoteListModel` adapts stored notes to Qt's model/view system.

The presentation layer does not access SQLite directly.

---

# Platform services

Platform-specific path handling is abstracted through:

```text
src/platform/platform_paths.h
src/platform/qt/qt_platform_paths.h
src/platform/qt/qt_platform_paths.cpp
```

The Qt implementation uses platform-aware application data locations rather than hard-coded filesystem paths.

The application database is therefore stored in the operating system's application data location.

For example, on the current Linux development machine the database is located under:

```text
~/.local/share/mininotes/mininotes.db
```

The path is not hard-coded in the application.

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
NoteService
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
NoteService
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
NoteService
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
NoteService
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

The application supports:

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

Input validation is performed at the application-service boundary.

SQLite writes use prepared statements with bound parameters.

The database is persistent across application restarts.

---

# CMake Presets

Standard host development configurations are provided through:

```text
CMakePresets.json
```

Available presets:

```text
linux-debug
linux-release
linux-tests
linux-e2e
```

## Debug

```sh
cmake --preset linux-debug
cmake --build --preset linux-debug
```

## Release

```sh
cmake --preset linux-release
cmake --build --preset linux-release
```

## Backend tests

```sh
cmake --preset linux-tests
cmake --build --preset linux-tests
ctest --preset linux-tests
```

## QML E2E

```sh
cmake --preset linux-e2e
cmake --build --preset linux-e2e

QT_QPA_PLATFORM=offscreen \
QT_QUICK_BACKEND=software \
MININOTES_E2E_TEST=1 \
./build/linux-e2e/mininotes
```

---

# Linux desktop

Linux is the first explicit desktop target of the multiplatform architecture.

The Linux desktop target uses the same shared:

```text
Domain
  ↓
Application
  ↓
Repository abstraction
  ↓
SQLite
```

and the same QML UI used by the other targets.

## Local desktop build

```sh
cmake --preset linux-release
cmake --build --preset linux-release
```

Run:

```sh
./build/linux-release/mininotes
```

## Linux desktop verification

The current Linux desktop target has been verified with:

* Debug build.
* Release build.
* Backend tests.
* Headless QML E2E.
* Startup smoke test.
* SQLite persistence.
* Arabic / English / emoji input.
* Existing note workflow.
* Desktop window execution at the host display resolution.

The automated Linux desktop workflow is:

```text
.github/workflows/linux-desktop.yml
```

It currently performs:

```text
Checkout
   ↓
Install Qt 6 dependencies
   ↓
Linux Release build
   ↓
Backend tests
   ↓
QML E2E
   ↓
Startup smoke test
```

The Linux workflow is intentionally separate from the Ubuntu Touch Clickable workflow.

---

# Linux desktop packaging and releases

The current Linux desktop CI validates the application but does not yet publish a Linux binary to GitHub Releases.

The intended release artifact is:

```text
mininotes-linux-x86_64.tar.gz
```

A tagged release will eventually contain both:

```text
mininotes_<version>_arm64.click
mininotes-linux-x86_64.tar.gz
```

The Linux release packaging step will be added separately after the Linux desktop target is stabilized.

---

# Ubuntu Touch

The current OpenStore release uses:

```text
Framework: ubuntu-touch-24.04-1.x
Qt: Qt 5 compatibility path
Architecture: arm64
```

The shared application architecture is intentionally independent from this packaging choice.

Ubuntu Touch packaging is built with Clickable:

```sh
clickable build --arch arm64
```

The current GitHub Actions workflow is:

```text
.github/workflows/ubuntu-touch.yml
```

It performs:

```text
Host build and tests
        ↓
Architecture boundary checks
        ↓
Headless QML E2E
        ↓
Provision Ubuntu Touch ARM64 SDK
        ↓
Build .click package
        ↓
Validate package metadata/content
        ↓
Upload artifact
```

The Ubuntu Touch target is continuously validated for ARM64.

---

# Testing

The current backend test suite contains dedicated QTest executables:

```text
mininotes_backend_test
mininotes_service_test
mininotes_platform_test
```

Run all tests:

```sh
cmake --preset linux-tests
cmake --build --preset linux-tests
ctest --preset linux-tests
```

The current checkpoint has:

```text
100% tests passed
```

The QML E2E test verifies:

* Validation labels.
* Successful note creation.
* Database count increase.
* Automatic return to the note list.
* Arabic / English / emoji / special characters.

Example:

```text
AUTOMATION: validation-labels OK
AUTOMATION: saved OK
AUTOMATION: auto-pop-after-save OK
AUTOMATION: RESULT PASS
```

---

# Host development dependencies

On Ubuntu Linux:

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

The project currently uses:

```text
C++17
Qt 6
CMake 4.x or another compatible modern CMake version
SQLite
```

---

# Multiplatform roadmap

The project is being reorganized incrementally:

```text
✅ 1. Git feature branch
✅ 2. Basic project structure
✅ 3. C++ source reorganization
✅ 4. QML source reorganization
✅ 5. Host build + backend tests
✅ 6. INoteRepository abstraction
✅ 7. NoteService
✅ 8. Platform services
✅ 9. Reusable QML components
✅ 10. CMake Presets
✅ 11. Linux desktop target
⬜ 12. Windows target
⬜ 13. macOS target
⬜ 14. Android target
⬜ 15. iOS target
🟨 16. Platform-specific packaging and CI matrix
```

Current platform status:

| Target | Status |
| --- | --- |
| Ubuntu Touch ARM64 | CI + Click packaging |
| Linux desktop x86_64 | CI + build/test/E2E |
| Windows | Planned |
| macOS | Planned |
| Android | Planned |
| iOS | Planned |

The architecture is being designed so that most of the application remains shared:

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

---

# CI/CD

Current workflows:

```text
.github/workflows/ubuntu-touch.yml
.github/workflows/linux-desktop.yml
```

The Ubuntu Touch workflow validates ARM64 Click packaging.

The Linux Desktop workflow validates the x86_64 desktop target.

GitHub Actions run names are based on the triggering commit message for push events.

Versioned releases currently use semantic version tags:

```text
vMAJOR.MINOR.PATCH
```

For example:

```text
v0.2.6
```

The release pipeline automatically builds and publishes the Ubuntu Touch ARM64 `.click`, Linux x86_64 `.tar.gz`, Linux AMD64 `.deb`, and Linux AMD64 `.snap` artifacts to the corresponding GitHub Release.

Release artifacts are generated automatically from version tags by GitHub Actions.

---

# Release strategy

The project remains in the `0.x` development series while the architecture and platform targets are still evolving.

A version tag is treated as a release candidate for the current supported targets.

The planned release structure is:

```text
Git tag
   │
   ├── Ubuntu Touch ARM64 .click
   │
   └── Linux desktop x86_64 archive
```

Future releases will extend the same model to:

```text
Windows
macOS
Android
iOS
```

The project will remain in the `0.x` development series until the shared architecture and initial platform targets are sufficiently stable for a production release.

`1.0.0` will be considered only after the initial shared architecture and platform targets are sufficiently stable.

---

# Development policy

A change should be considered complete only when:

1. The C++ implementation builds successfully.
2. Existing backend tests pass.
3. QML references remain valid.
4. Persistence behavior remains intact.
5. Relevant platform behavior remains functional.
6. New user-facing workflows have appropriate automated coverage.
7. `README.md` reflects the actual project state.
8. CI validation passes for the affected targets.

The project keeps one canonical documentation file:

```text
README.md
```

No version-specific README files are maintained.

---

# Current architecture checkpoint

At the end of the current Linux desktop stage, the architecture is:

```text
                         QML
                          │
                          ▼
                  Presentation layer
                 NoteController/Model
                          │
                          ▼
                  Application layer
                     NoteService
                          │
                          ▼
                    Domain layer
                 Note / Repository API
                          │
                          ▼
                    Data layer
                SqliteNoteRepository
                          │
                          ▼
                       SQLite

Platform concerns are isolated behind:
             IPlatformPaths
                    │
                    ▼
            QtPlatformPaths
```

The same core is intended to remain reusable across the upcoming Windows, macOS, Android and iOS targets.
