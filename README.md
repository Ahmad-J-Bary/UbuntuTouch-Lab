# MiniNotes (Ubuntu Touch)

A small, offline-first, privacy-friendly notes app for Ubuntu Touch.

| | |
|---|---|
| Current version | **0.1.1** |
| Status | **Experimental** |
| Platform | Ubuntu Touch |
| Architecture | arm64 |
| Framework | ubuntu-touch-24.04-2.x |

MiniNotes 0.1.1 is the first experimental Ubuntu Touch release. It implements
**Feature 1 — Create Note** only (no search, edit, delete, import/export, sync,
or extra pages).

Native stack: **QML (QtQuick Controls 2)** frontend + **C++20/17**, **SQLite**
backend, packaged with **Clickable**. QML never touches the database directly;
all persistence goes through a C++ controller and repository using prepared
statements.

> **Device install caveat:** a real device may require an appropriate
> installation method depending on the Ubuntu Touch image. This release has not
> been installed as a Click app on a device through the normal app environment,
> so full touch/on-device acceptance is **not** claimed yet.

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
- A container engine (rootless is fine). This host uses rootless Podman 5.7.0
  in a user namespace; CI uses Docker on the GitHub runner.
- CMake >= 3.16 (desktop builds)

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
in via `dependencies_target`. The architecture and framework are *not*
hardcoded: they come from environment variables set by Clickable
(`$ENV{ARCH}`, `$ENV{CLICK_FRAMEWORK}`) in `manifest.json.in`.

### CI (GitHub Actions)

The `.github/workflows/ubuntu-touch.yml` workflow (`ubuntu-touch`) runs on
`ubuntu-24.04` for every push to `main` and every pull request. It:

1. installs Qt 6 + Clickable 8.10.0,
2. builds and runs the backend test suite (`10/10` expected),
3. runs the headless QML/E2E automation (`MININOTES_E2E_TEST=1`,
   `QT_QPA_PLATFORM=offscreen`, expects `AUTOMATION: RESULT PASS`),
4. provisions the **official** Clickable `clickable/amd64-ut24.04-2.x-arm64`
   image on the runner (Qt6 arm64 deps + reviewer `2404.2` policy data),
5. builds the ARM64 click with
   `clickable build --arch arm64 --docker-image … --skip-image-setup`,
6. validates it with `click info` / `click contents` (arch `arm64`, framework
   `ubuntu-touch-24.04-2.x`, AArch64 binary, all packed files present, JSON
   apparmor),
7. uploads `build/aarch64-linux-gnu/app/mininotes_0.1.1_arm64.click` as the
   **`mininotes-ubuntu-touch-arm64`** workflow artifact.

The upstream click-reviewer (click-reviewers-tools 0.85) ships AppArmor
policy metadata only up to `2404.1`; the ubuntu-touch-24.04-2.x framework
uses `2404.2`. That is a reviewer *data* limitation (the runtime `2404.2`
policy exists in the SDK image itself), not a package defect — the workflow
therefore adds the `2404.2` baseline to the reviewer as a copy of `2404.1`
(the declarative default for an empty `policy_groups` profile) instead of
skipping or downgrading the review.

### Local ARM64 build (this machine)

This development host has neither sudo nor a container daemon, so a user-space
rootless Podman 5.7.0 is used (see Notes below). The validated build command,
using a locally pre-provisioned SDK image:

```sh
clickable build --arch arm64 \
  --docker-image localhost/mininotes-sdk:24.04-2.x-arm64 --skip-image-setup
```

On a machine with a normal rootless or root Docker/Podman, the plain form
`clickable build --arch arm64` (letting Clickable provision the official
image) is equivalent.

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

CI (GitHub Actions, `.github/workflows/ubuntu-touch.yml`): backend tests,
headless QML/E2E, ARM64 click build against the official Clickable image,
package validation, and the `mininotes-ubuntu-touch-arm64` artifact.

Device (POCO X3 NFC, arm64, Ubuntu Touch 24.04 / Qt 6.10.2): the ARM64 binary
was verified on the real device via the same headless E2E automation — create
note, validation, save, and auto-return all pass and the note persists across
app restarts. The database row on the device holds the entered text exactly
(Arabic `العربية`, emoji, quotes, backslash, semicolon).

### Device install (POCO) — findings

Probed on the device (ubuntu-touch-24.04-2.x, sideload-capable image):

- `pkcon`: **absent** — no `pkcon` binary exists anywhere (the
  `packagekit-tools` package is not installed), so Clickable's own install
  path (`pkcon install-local --allow-untrusted`) cannot run on this device.
- PackageKit: daemon present (`/usr/libexec/packagekitd`) but inactive and
  ships **only the `apt` backend** — it cannot install `.click` packages.
- Privileged installer present: the `com.lomiri.click` system D-Bus service
  (`Install(path)`) is D-Bus-activatable and is what OpenStore uses. Its
  verification path (`debsig-verify`) **rejects unsigned** `.click` packages,
  so an unsigned local build cannot be installed through it either.
- `click install` (system path into `/opt/click.ubuntu.com`) requires **root**
  (phablet has sudo *with* password; no NOPASSWD). `click install --user` is
  not a supported system-install mode in this framework.
- Consequence: there is **no working user-space installer** for an unsigned
  local `.click` on this device. System/GUI installation is only possible by
  (a) signing the package with a trusted key, (b) using a development image /
  channel that ships `packagekit-tools` + the click backend, or (c) a
  privileged `click install` (root/password). Per project constraints, the
  production root filesystem, `/opt/click.ubuntu.com`, `/etc/click/` and
  `/var/lib/apparmor/` are **not** modified.
- The latest click (`build/aarch64-linux-gnu/app/mininotes_0.1.1_arm64.click`)
  is pushed to the device at `/home/phablet/Documents/` and passes on-device
  inspection/parse checks; final Lomiri-launcher + touch acceptance still
  requires one of the privileged/signed routes above.

Containerized builds: `clickable build --arch arm64` now works end-to-end with
rootless Podman (see Notes) and in CI. The produced click passes click-review,
reports `architecture: arm64` and `framework: ubuntu-touch-24.04-2.x`, and
contains the binary, `qml/`, manifest, desktop, declarative apparmor and icon.