# MiniNotes (Ubuntu Touch)

A small, offline-first, privacy-friendly notes app for Ubuntu Touch.
Currently implements **Feature 1 — CREATE NOTE** only (no search, edit, delete,
import/export, sync, or extra pages).

Native stack: **QML (QtQuick Controls 2)** frontend + **C++20/17**, **SQLite**
backend, packaged with **Clickable**. QML never touches the database directly;
all persistence goes through a C++ controller and repository using prepared
statements.

## Architecture

```
QML (Main.qml / NotesListPage.qml / CreateNotePage.qml)
        │  noteController context property (signals + Q_INVOKABLE saveNote)
        ▼
NoteController  (moc-based QObject, QML bridge, saving-state / duplicate-guard)
        ▼
NoteRepository  (validation backstop + all SQL via prepared statements)
        ▼
Database        (QSQLITE driver, CREATE TABLE IF NOT EXISTS, connections)
        ▼
~/…/AppDataLocation/mininotes.db
```

- DB schema:
  `notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT
  NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)`
- Insert uses a single prepared statement with parameter binding — no string
  concatenation, no injection surface.
- Validation is multi-layered: UI shows messages ("Title is required",
  "Content is required") and the C++ repository re-checks before writing.
- UTF-8 is handled end-to-end (Arabic, emoji, quotes, backslashes are
  round-tripped intact).

## Requirements

- Ubuntu Touch / Ubuntu Desktop, clickable 8.x (for device builds)
- Qt >= 5.12 (device SDK 20.04) or Qt6 (desktop)
- CMake >= 3.16

## Build & run on desktop

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j4
./build/mininotes
```

Notes:

- The QML sources are auto-copied next to the binary (CMake `POST_BUILD`), so
  the app can be run straight out of the build dir.
- DB location: your Qt app-data dir (e.g. `~/.local/share/MiniNotes/mininotes/mininotes.db`).

## Tests

Backend functional tests (QtTest) cover the mandatory acceptance list: valid
note, empty title, empty body, long UTF-8 text, special characters
(`'"\;` Arabic/English/emoji), duplicate save request, database failure, and
persistence across reopen.

```sh
cmake -S . -B build -DMININOTES_BUILD_TESTS=ON
cmake --build build -j4
ctest --test-dir build --output-on-failure
```

Run a headless end-to-end UI check (drives validation + save + auto-return):

```sh
QT_QPA_PLATFORM=offscreen MININOTES_E2E_TEST=1 ./build/mininotes
# expect: AUTOMATION: RESULT PASS
```

## Package for Ubuntu Touch (clickable 8)

```sh
clickable build --arch arm64   # requires docker or podman on the host
clickable install --arch arm64 # POCO X3 NFC connected via ADB
clickable launch --arch arm64
```

`clickable.yaml` is written for clickable 8.8+ (v8 config format; app metadata
lives in `manifest.json.in`, apparmor in `mininotes.apparmor`, desktop file in
`mininotes.desktop`). The device framework is `ubuntu-sdk-20.04` and the SQLite
driver is added via `dependencies_target: [libqt5sql5-sqlite]`.

Notes:

- Clickable requires a project path **without spaces** and a container engine
  (docker/podman) on the build machine.
- Module names follow F-Droid-style `name.hook` conventions only if you rename
  the app; the current `name` is `mininotes`.
- The click regroups binary, `qml/`, `manifest.json`, `mininotes.apparmor`,
  `mininotes.desktop` and `assets/icons/mininotes.svg` into one install root.

## Files

- `src/note.h` – value type (id, title, body, timestamps)
- `src/database.h/.cpp` – QSQLITE open/create/close
- `src/noterepository.h/.cpp` – prepared-statement CRUD (insert/count/…)
- `src/notecontroller.h/.cpp` – QML-facing controller
- `src/main.cpp` – app entry, DB init, context properties
- `qml/Main.qml` – StackView root; optional E2E automation driver
- `qml/NotesListPage.qml` – home page + add button
- `qml/CreateNotePage.qml` – create-note form with validation UI
- `tests/tst_backend.cpp` – QtTest backend suite (10 tests)
- `clickable.yaml`, `manifest.json.in`, `mininotes.apparmor`,
  `mininotes.desktop`, `assets/icons/mininotes.svg` – click packaging

## Status

Desktop: build (CMake + toy toolchain), backend tests (10/10) and headless E2E
UI check all pass. Device install/launch on the POCO X3 NFC was not possible in
this environment (device not connected; click builds need docker/podman).