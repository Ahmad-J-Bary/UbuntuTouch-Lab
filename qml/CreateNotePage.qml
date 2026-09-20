import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color headerPress: "#4A1731"
    readonly property color textPrimary: "#333333"
    readonly property color textSecondary: "#777777"
    readonly property color accent: "#77216F"
    readonly property color errorColor: "#C1001E"

    readonly property real pageMargin:
        Math.max(20, Math.min(width * 0.055, 28))

    readonly property real headerHeight: 64
    readonly property real controlHeight: 64

    background: Rectangle {
        color: "#F5F5F5"
    }

    ColumnLayout {
        anchors.fill: parent

        spacing: 0

        // ---------------------------------------------------------------------
        // Header
        // ---------------------------------------------------------------------

        Rectangle {
            id: header

            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight

            color: root.headerBackground

            Item {
                id: backArea

                width: 64
                height: parent.height

                Rectangle {
                    anchors.fill: parent

                    radius: 8

                    color: backTap.pressed
                        ? root.headerPress
                        : "transparent"
                }

                Text {
                    anchors.centerIn: parent

                    text: "‹"

                    color: root.headerForeground

                    font.pointSize: 31
                    font.weight: Font.DemiBold

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                TapHandler {
                    id: backTap

                    onTapped: {
                        if (!noteController.saving) {
                            var view = root.StackView.view

                            if (view)
                                view.pop()
                        }
                    }
                }
            }

            Text {
                anchors.left: backArea.right
                anchors.right: parent.right

                anchors.leftMargin: 8
                anchors.rightMargin: root.pageMargin

                anchors.verticalCenter: parent.verticalCenter

                text: "New Note"

                color: root.headerForeground

                font.pointSize: 20
                font.weight: Font.DemiBold

                elide: Text.ElideRight

                verticalAlignment: Text.AlignVCenter
            }
        }

        // ---------------------------------------------------------------------
        // Scrollable form
        // ---------------------------------------------------------------------

        ScrollView {
            id: formScroll

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            contentWidth: availableWidth

            ColumnLayout {
                id: form

                width: formScroll.availableWidth

                spacing: 10

                // Margins
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                }

                // -----------------------------------------------------------------
                // Title label
                // -----------------------------------------------------------------

                Text {
                    text: "Title"

                    color: root.textSecondary

                    font.pointSize: 15
                    font.weight: Font.DemiBold

                    Layout.fillWidth: true
                }

                // -----------------------------------------------------------------
                // Title field
                // -----------------------------------------------------------------

                TextField {
                    id: titleField

                    objectName: "titleField"

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.controlHeight

                    placeholderText: "Note title"

                    font.pointSize: 17

                    color: root.textPrimary

                    padding: 16

                    selectByMouse: false

                    background: Rectangle {
                        radius: 8

                        color: "#FFFFFF"

                        border.color:
                            titleField.activeFocus
                                ? root.accent
                                : "#C9C9C9"

                        border.width:
                            titleField.activeFocus
                                ? 2
                                : 1
                    }

                    Keys.onReturnPressed:
                        bodyField.forceActiveFocus()

                    Keys.onEnterPressed:
                        bodyField.forceActiveFocus()

                    onTextEdited: {
                        if (attempted)
                            validate()
                    }

                    // Explicitly keep touch focus behavior obvious.
                    TapHandler {
                        onTapped:
                            titleField.forceActiveFocus()
                    }
                }

                // -----------------------------------------------------------------
                // Title error
                // -----------------------------------------------------------------

                Text {
                    id: titleError

                    objectName: "titleError"

                    visible: false

                    text: ""

                    color: root.errorColor

                    font.pointSize: 13

                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                }

                // -----------------------------------------------------------------
                // Content label
                // -----------------------------------------------------------------

                Text {
                    text: "Content"

                    color: root.textSecondary

                    font.pointSize: 15
                    font.weight: Font.DemiBold

                    Layout.fillWidth: true

                    Layout.topMargin: 8
                }

                // -----------------------------------------------------------------
                // Body
                // -----------------------------------------------------------------

                TextArea {
                    id: bodyField

                    objectName: "bodyField"

                    Layout.fillWidth: true
                    Layout.preferredHeight:
                        Math.max(220, Math.min(root.height * 0.32, 320))

                    placeholderText: "Write your note..."

                    font.pointSize: 17

                    color: root.textPrimary

                    padding: 16

                    wrapMode: Text.Wrap

                    selectByMouse: false

                    background: Rectangle {
                        radius: 8

                        color: "#FFFFFF"

                        border.color:
                            bodyField.activeFocus
                                ? root.accent
                                : "#C9C9C9"

                        border.width:
                            bodyField.activeFocus
                                ? 2
                                : 1
                    }

                    onTextChanged: {
                        if (attempted)
                            validate()
                    }

                    TapHandler {
                        onTapped:
                            bodyField.forceActiveFocus()
                    }
                }

                // -----------------------------------------------------------------
                // Body error
                // -----------------------------------------------------------------

                Text {
                    id: bodyError

                    objectName: "bodyError"

                    visible: false

                    text: ""

                    color: root.errorColor

                    font.pointSize: 13

                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                }

                // -----------------------------------------------------------------
                // Save error
                // -----------------------------------------------------------------

                Rectangle {
                    id: saveErrorBox

                    objectName: "createPageErrorBox"

                    visible: false

                    Layout.fillWidth: true

                    Layout.preferredHeight:
                        saveErrorLabel.implicitHeight + 28

                    radius: 8

                    color: "#FDECEA"

                    border.color: "#E7C2C0"
                    border.width: 1

                    Text {
                        id: saveErrorLabel

                        anchors.fill: parent
                        anchors.margins: 12

                        text: ""

                        color: root.errorColor

                        font.pointSize: 13

                        wrapMode: Text.WordWrap

                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // -----------------------------------------------------------------
                // Save button
                // -----------------------------------------------------------------

                Rectangle {
                    id: saveButton

                    Layout.fillWidth: true
                    Layout.preferredHeight: 64

                    Layout.topMargin: 6

                    radius: 10

                    color:
                        !saveTap.enabled
                            ? "#A98FA6"
                            : saveTap.pressed
                                ? "#5E2750"
                                : root.accent

                    Text {
                        anchors.centerIn: parent

                        text:
                            noteController.saving
                                ? "Saving..."
                                : "Save"

                        color:
                            saveTap.enabled
                                ? "#FFFFFF"
                                : "#E6DDE4"

                        font.pointSize: 18
                        font.weight: Font.DemiBold
                    }

                    TapHandler {
                        id: saveTap

                        enabled: !noteController.saving

                        onTapped:
                            root.submit()
                    }
                }

                // Bottom breathing room.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.pageMargin
                }
            }
        }
    }

    property bool attempted: false

    function submit() {
        attempted = true

        if (validate()) {
            saveErrorBox.visible = false

            noteController.saveNote(
                titleField.text,
                bodyField.text
            )
        }
    }

    function validate() {
        var valid = true

        if (titleField.text.trim().length === 0) {
            titleError.text = "Title is required"
            titleError.visible = true
            valid = false
        } else {
            titleError.visible = false
        }

        if (bodyField.text.trim().length === 0) {
            bodyError.text = "Content is required"
            bodyError.visible = true
            valid = false
        } else {
            bodyError.visible = false
        }

        return valid
    }

    Connections {
        target: noteController

        function onNoteSaved() {
            if (root.StackView.view)
                root.StackView.view.pop()
        }

        function onSaveFailed(message) {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }

        function onValidationFailed(message) {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }
    }
}