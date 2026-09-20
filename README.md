# MiniNotes (Ubuntu Touch)

MiniNotes is a small, offline-first, privacy-friendly notes application for Ubuntu Touch.

The project is built as a native Ubuntu Touch application using **QML + Qt 6** for the frontend, **C++17** for the application/backend layer, and **SQLite** for persistent storage.

The main goal of the project is to learn and validate native Ubuntu Touch application development incrementally, while keeping the architecture simple, maintainable, testable, and suitable for mobile devices.

|                         |                                |
| ----------------------- | ------------------------------ |
| Current version         | **0.1.3**                      |
| Status                  | **Experimental / Development** |
| Platform                | Ubuntu Touch                   |
| Target architecture     | arm64                          |
| Framework               | `ubuntu-touch-24.04-2.x`       |
| Device used for testing | POCO X3 NFC (`surya`)          |
| UI technology           | QML / Qt 6                     |
| Backend                 | C++17                          |
| Database                | SQLite                         |
| Build system            | CMake + Clickable              |

---

## Project goals

MiniNotes is being developed incrementally.

Each feature should be completed, tested, and verified on the real Ubuntu Touch device before moving to the next major feature.

The project follows these principles:

* Native Ubuntu Touch technologies.
* QML for UI only.
* C++ for application logic and data access.
* SQLite for persistent local storage.
* QML must never access SQLite directly.
* Input must be validated in both UI and C++.
* Database operations use prepared statements.
* Touch interaction must be comfortable on mobile screens.
* Arabic, English, emoji, and special characters must work correctly.
* Features should be tested on both desktop and the real Ubuntu Touch device.

---

# Current status — 0.1.3

Version **0.1.3** is the current working baseline of the project.

The application successfully:

* Builds for ARM64 using Clickable.
* Installs on the POCO X3 NFC.
* Launches correctly through Lomiri.
* Responds correctly to touch input.
* Creates notes.
* Validates empty title/content.
* Stores notes in SQLite.
* Preserves UTF-8 content including Arabic and emoji.
* Persists notes across application restarts.
* Uses the intended C++ backend architecture.

The current user interface is functional but still requires visual and UX refinement before the project moves to the next major version.

---

# Development roadmap

## 0.1.x — Feature completion and UX refinement

The remaining `0.1.x` work is focused on completing the basic note experience and polishing the mobile interface.

### Feature 1 — Create Note

Status: **Implemented**

The application currently supports:

* Creating a note.
* Title validation.
* Content validation.
* SQLite persistence.
* Duplicate-save protection.
* Error reporting.
* UTF-8 / Arabic / emoji support.
* Automatic return to the notes screen after saving.

---

### Feature 2 — Browse and Edit Notes

Status: **Next 0.1.x feature**

The notes screen should display the actual stored notes instead of only showing a counter such as:

```text
2 notes stored
```

The planned behavior is:

```text
Notes List
    │
    ├── Note
    ├── Note
    ├── Note
    │
    └── + New Note
```

Each note should provide:

* Title.
* Short preview of the content.
* Useful timestamp information.
* A large touch-friendly area.

Selecting a note should open a dedicated note page where the user can:

* Read the complete note.
* Edit the title.
* Edit the content.
* Save the changes.
* Return to the notes list.

The existing:

```text
created_at
updated_at
```

database fields will be used to preserve creation and modification timestamps.

---

## 0.1.x — Mobile UX refinement

Before starting `0.2.0`, the interface will receive a dedicated UX pass.

The goal is not simply to increase font sizes, but to make the complete interface more comfortable on the POCO X3 NFC and similar touchscreen devices.

### UI improvements

The following areas will be reviewed and adjusted:

* Header height.
* Header title size.
* Back button size.
* Back button touch area.
* Screen titles.
* Text field height.
* Text field font size.
* Text area height.
* Input padding.
* Labels.
* Save button size.
* Save button touch area.
* Floating `+` button size.
* Floating `+` touch area.
* Note card size.
* Note title typography.
* Note preview typography.
* Timestamps.
* Vertical and horizontal spacing.
* Bottom safe space around floating controls.
* Overall visual hierarchy.
* Scrolling behavior.
* Touch feedback.

The target is a comfortable mobile UI rather than a desktop UI scaled down to fit a phone.

---

# Planned 0.2.0

`0.2.0` will start only after the basic note workflow and the `0.1.x` UX refinement are complete.

The exact feature set for `0.2.0` will be defined after the current `0.1.x` work is tested on the real device.

Possible future areas include:

* Delete notes.
* Confirmation dialogs.
* Search.
* Better note browsing.
* Sorting.
* Empty-state improvements.
* More complete note metadata handling.
* Additional UI/UX improvements.
* Further mobile-specific interaction improvements.

The final `0.2.0` scope should be decided based on the actual behavior of the completed `0.1.x` release rather than being implemented prematurely.

---

# Architecture

```text
                    QML UI
                       │
                       │ signals / properties / Q_INVOKABLE
                       ▼
                NoteController
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

### Responsibilities

#### QML

Responsible only for:

* Presentation.
* Navigation.
* User interaction.
* Validation feedback.
* Displaying model data.

QML must not execute SQL or access the SQLite database directly.

#### NoteController

Responsible for:

* Exposing application operations to QML.
* Managing saving/updating state.
* Exposing note data to the UI.
* Emitting success/failure signals.
* Protecting against duplicate operations.

#### NoteRepository

Responsible for:

* Validation backstop.
* SQLite operations.
* Prepared statements.
* Creating, reading, updating, and later deleting notes.

#### Database

Responsible for:

* SQLite connection.
* Database initialization.
* Schema creation.
* Database lifecycle.

---

# Database schema

Current schema:

```sql
CREATE TABLE IF NOT EXISTS notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
```

The schema already supports the basic create/read/update workflow planned for the `0.1.x` series.

All database writes should use prepared statements and bound parameters.

---

# Data flow

Creating a note:

```text
User
  │
  ▼
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
QML returns to Notes List
```

Reading a note:

```text
Notes List
  │
  ▼
NoteController
  │
  ▼
NoteRepository
  │
  ▼
SQLite SELECT
  │
  ▼
QML displays notes
```

Updating a note:

```text
EditNotePage.qml
  │
  ▼
NoteController
  │
  ▼
NoteRepository::updateNote()
  │
  ▼
SQLite UPDATE
  │
  ▼
updated_at changed
  │
  ▼
QML refreshes notes
```

---

# Validation

Validation exists at multiple layers.

The UI provides immediate feedback such as:

```text
Title is required
Content is required
```

The C++ repository validates the same conditions again before performing database operations.

This ensures that the backend does not depend on QML validation for data integrity.

---

# UTF-8 and international text

MiniNotes must correctly support:

* Arabic.
* English.
* Mixed Arabic and English.
* Emoji.
* Quotes.
* Backslashes.
* Semicolons.
* Newlines.
* Long text.

Example:

```text
Hello Ubuntu Touch
العربية
مرحبا بالعالم
😀
' " \ ;
```

These values must survive the complete path:

```text
QML → C++ → SQLite → C++ → QML
```

without corruption.

---

# Requirements

* Ubuntu Touch 24.04+
* Qt 6
* CMake >= 3.16
* Clickable >= 8.8
* Docker or Podman for Clickable builds
* ARM64 Ubuntu Touch device for on-device testing

The current development device is:

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

The QML files are copied next to the executable during the build.

The SQLite database is stored in Qt's `AppDataLocation`.

---

# Backend tests

The backend test suite covers the important data-layer scenarios, including:

* Valid note creation.
* Empty title.
* Empty body.
* Long UTF-8 text.
* Arabic and English content.
* Emoji.
* Special characters.
* Duplicate save requests.
* Database failure.
* Persistence across reopen.

Build and run:

```sh
cmake -S . -B build -DMININOTES_BUILD_TESTS=ON
cmake --build build -j4
ctest --test-dir build --output-on-failure
```

The current baseline expects the existing backend suite to pass completely before a release is considered stable.

---

# Headless UI test

The project includes a headless QML/E2E test.

Run:

```sh
QT_QPA_PLATFORM=offscreen \
MININOTES_E2E_TEST=1 \
./build/mininotes
```

Expected result:

```text
AUTOMATION: RESULT PASS
```

The E2E test should be extended whenever important user-facing behavior is added.

---

# Build for Ubuntu Touch

Build:

```sh
clickable build --arch arm64 --skip-review
```

Install on the connected device:

```sh
clickable install --arch arm64
```

Launch:

```sh
clickable launch --arch arm64 --skip-kill
```

View application logs:

```sh
clickable log --arch arm64
```

For runtime debugging, the application logs should be inspected before making speculative code changes.

---

# Packaging

The Click package contains:

```text
mininotes
qml/
manifest.json
mininotes.apparmor
mininotes.desktop
assets/icons/mininotes.svg
```

Application metadata is defined through:

```text
manifest.json.in
```

The AppArmor profile is:

```text
mininotes.apparmor
```

The desktop entry is:

```text
mininotes.desktop
```

---

# Important Ubuntu Touch development notes

The application is designed specifically for Ubuntu Touch and should be tested through the actual Lomiri environment.

When an application fails to launch, the preferred debugging sequence is:

```text
Build
  ↓
Install
  ↓
Launch
  ↓
clickable log
  ↓
Identify the actual runtime error
  ↓
Fix the smallest responsible layer
  ↓
Rebuild
  ↓
Retest
```

The goal is to avoid changing QML, C++, packaging, and database code simultaneously when only one layer is responsible for the failure.

---

# Project structure

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
│   └── main.cpp
│
├── qml/
│   ├── Main.qml
│   ├── NotesListPage.qml
│   ├── CreateNotePage.qml
│   └── EditNotePage.qml
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

The exact file list may grow as new features are introduced.

---

# Development policy

The project is intentionally developed in small, verifiable steps.

A feature should not be considered complete until:

1. The backend implementation works.
2. The UI implementation works.
3. Validation is covered.
4. Persistent storage is verified.
5. The feature works with real touch interaction.
6. The feature is tested on the real Ubuntu Touch device.
7. Runtime logs show no unexpected application errors.
8. The README reflects the actual project state.

---

# Release progression

```text
0.1.0
  │
  ├── Project foundation
  │
0.1.1
  │
  ├── Initial Create Note implementation
  │
0.1.2
  │
  ├── Stability / packaging improvements
  │
0.1.3
  │
  ├── Working device baseline
  ├── Create Note
  ├── SQLite persistence
  └── Touch interaction
  │
  ▼
0.1.x
  │
  ├── Browse stored notes
  ├── Open notes
  ├── Edit notes
  ├── UX / responsive mobile refinement
  ├── Larger touch targets
  ├── Typography and spacing improvements
  └── Real-device verification
  │
  ▼
0.2.0
  │
  └── Next feature milestone
```

The transition to **0.2.0** should happen only after the remaining `0.1.x` work is completed and verified on the real device.

---

# Current development status

### Completed

* Native Qt/QML application foundation.
* C++ backend.
* SQLite integration.
* Database schema.
* Create Note.
* Input validation.
* Prepared statements.
* UTF-8 / Arabic / emoji handling.
* Persistence.
* Duplicate-save protection.
* ARM64 Clickable build.
* Real-device installation.
* Real-device launch.
* Touch interaction.

### Current 0.1.x work

* Browsing stored notes.
* Opening a stored note.
* Editing notes.
* Updating `updated_at`.
* Mobile UX refinement.
* Larger controls and touch targets.
* Improved typography and spacing.
* Better note-list presentation.

### Next major milestone

```text
0.2.0
```

The exact contents of `0.2.0` will be finalized after the current `0.1.x` work is completed and validated.
