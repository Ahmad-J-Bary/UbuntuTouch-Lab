# MiniNotes 0.1.3

This release fixes the QML startup failure found on Ubuntu Touch 24.04.

## Root cause

The Ubuntu Touch target's QML runtime requires explicit versions on module imports. The 0.1.3 QML files used unversioned imports such as `import QtQuick`, which caused:

`Library import requires a version`

The 0.1.4 sources restore versioned imports:

- `QtQuick 2.12`
- `QtQuick.Controls 2.12`
- `QtQuick.Layouts 1.15`
- `QtQuick.Window 2.12`

No database or backend behavior was changed by this fix.

## Verification

After building and installing, inspect the runtime with:

```bash
clickable log --arch arm64
```

The expected startup sequence includes:

```text
Database opened at ...
Notes table is ready
Loading QML: .../qml/Main.qml
MiniNotes QML root loaded successfully
```

The previous `Library import requires a version` messages should be absent.
