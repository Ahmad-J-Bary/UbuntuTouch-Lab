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

- Ubuntu Touch 24.04+ (Qt 6 runtime) or any desktop with Qt 6 (>= 6.2)
- clickable 8.8+ for device builds (needs docker/podman on the host)
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
`mininotes.desktop`). The device framework is `ubuntu-touch-24.04-2.x` (the
app is a Qt 6 application; the POCO X3 NFC runs Ubuntu Touch 24.04 with the
Qt 6.10.2 runtime). The Qt 6 dev packages and the `QSQLITE` driver are pulled
in via `dependencies_target`.

Notes:

- Clickable requires a project path **without spaces** and a container engine
  (docker/podman) on the build machine. This machine has neither sudo nor a
  container daemon, so a **user-space rootless Podman 5.7.0** is used
  (`/tmp/opencode/podman-env.sh` + `/tmp/opencode/podman-exec.sh`, image store
  under `~/.local/share/containers`). It runs in its own user namespace
  (single-uid mapping, `ignore_chown_errors`, `fuse-overlayfs`).
- The SDK image (`mininotes-sdk:24.04-2.x-arm64`) is pre-provisioned from
  `clickable/amd64-ut24.04-2.x-arm64`: apt is forced to stay as root
  (`/etc/apt/apt.conf.d/99rootless`) because the "__apt" user cannot drop
  privileges inside the single-uid user namespace, the Qt 6 arm64 dev packages
  are preinstalled, and click-reviewers-tools is taught the `2404.2` policy.
- Because clickable 8.10 generates its own image Dockerfile (which fails in
  this setup), builds are invoked with the pre-provisioned image and image
  setup disabled:
  `clickable build --arch arm64 --docker-image localhost/mininotes-sdk:24.04-2.x-arm64 --skip-image-setup`
- The apparmor profile is declarative (`policy_version` 2404.2, `policy_groups`
  empty), matching the ubuntu-touch-24.04-2.x framework. The app stores its
  SQLite database under `~/.local/share/mininotes/` which matches the framework
  confinement for the package name.
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

Desktop: clean CMake build, backend tests (10/10) and headless E2E UI check
(`AUTOMATION: RESULT PASS`) all pass; SQLite round-trips UTF-8/Arabic/emoji and
special characters intact.

Device (POCO X3 NFC, arm64, Ubuntu Touch 24.04 / Qt 6.10.2): the ARM64 binary
was verified on the real device via the same headless E2E automation — create
note, validation, save, and auto-return all pass and the note persists across
app restarts. The database row on the device holds the entered text exactly
(Arabic `العربية`, emoji, quotes, backslash, semicolon). A system-wide `click
install` was not possible in this lab because the device session has no root
(`/opt/click.ubuntu.com` and AppArmor registration need root), and real-session
GPU rendering needs the click-app-launch hybris environment; the app itself
starts and initialises its database under the device's Mir compositor session.

Containerized builds: `clickable build --arch arm64` now works end-to-end with
rootless Podman (see Notes). The produced click passes click-review, reports
`architecture: arm64` and `framework: ubuntu-touch-24.04-2.x`, and contains the
binary, `qml/`, manifest, desktop, declarative apparmor and icon.