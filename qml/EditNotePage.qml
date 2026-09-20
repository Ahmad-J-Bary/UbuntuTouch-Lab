import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15

Page {
    id: root

    property int noteId: -1
    property bool attempted: false
    property bool loaded: false

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color headerPress: "#4A1731"
    readonly property color textPrimary: "#333333"
    readonly property color textSecondary: "#777777"
    readonly property color accent: "#77216F"
    readonly property color errorColor: "#C1001E"

    readonly property real pageMargin: 24
    readonly property real headerHeight: 78
    readonly property real controlHeight: 78

    background: Rectangle { color: "#F5F5F5" }

    Component.onCompleted: loadNote()

    function loadNote() {
        if (noteId <= 0)
            return

        var note = noteController.getNote(noteId)
        if (!note || !note.id) {
            saveErrorLabel.text = "This note could not be found"
            saveErrorBox.visible = true
            return
        }

        titleField.text = note.title
        bodyField.text = note.body
        loaded = true
    }

    function submit() {
        attempted = true
        if (!validate())
            return

        saveErrorBox.visible = false
        noteController.updateNote(noteId, titleField.text, bodyField.text)
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            color: root.headerBackground

            Item {
                id: backArea
                width: 88
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: backMouse.pressed ? root.headerPress : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: root.headerForeground
                    font.pointSize: 38
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    onClicked: {
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
                anchors.leftMargin: 6
                anchors.rightMargin: root.pageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: "Edit Note"
                color: root.headerForeground
                font.pointSize: 25
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        ScrollView {
            id: formScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: formScroll.availableWidth
                spacing: 14

                Item { Layout.fillWidth: true; Layout.preferredHeight: 12 }

                Text {
                    text: "Title"
                    color: root.textSecondary
                    font.pointSize: 18
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                }

                TextField {
                    id: titleField
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.controlHeight
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    placeholderText: "Note title"
                    font.pointSize: 20
                    color: root.textPrimary
                    padding: 18
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle {
                        radius: 10
                        color: "#FFFFFF"
                        border.color: titleField.activeFocus ? root.accent : "#C9C9C9"
                        border.width: titleField.activeFocus ? 2 : 1
                    }
                    Keys.onReturnPressed: bodyField.forceActiveFocus()
                    Keys.onEnterPressed: bodyField.forceActiveFocus()
                    onTextEdited: if (attempted) validate()
                }

                Text {
                    id: titleError
                    visible: false
                    text: ""
                    color: root.errorColor
                    font.pointSize: 15
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                }

                Text {
                    text: "Content"
                    color: root.textSecondary
                    font.pointSize: 18
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    Layout.topMargin: 8
                }

                TextArea {
                    id: bodyField
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(260, Math.min(root.height * 0.42, 400))
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    placeholderText: "Write your note..."
                    font.pointSize: 20
                    color: root.textPrimary
                    padding: 17
                    wrapMode: Text.Wrap
                    background: Rectangle {
                        radius: 10
                        color: "#FFFFFF"
                        border.color: bodyField.activeFocus ? root.accent : "#C9C9C9"
                        border.width: bodyField.activeFocus ? 2 : 1
                    }
                    onTextChanged: if (attempted) validate()
                }

                Text {
                    id: bodyError
                    visible: false
                    text: ""
                    color: root.errorColor
                    font.pointSize: 15
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                }

                Rectangle {
                    id: saveErrorBox
                    visible: false
                    Layout.fillWidth: true
                    Layout.preferredHeight: saveErrorLabel.implicitHeight + 30
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    radius: 10
                    color: "#FDECEA"
                    border.color: "#E7C2C0"
                    border.width: 1

                    Text {
                        id: saveErrorLabel
                        anchors.fill: parent
                        anchors.margins: 13
                        text: ""
                        color: root.errorColor
                        font.pointSize: 15
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    id: saveButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 74
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    Layout.topMargin: 8
                    radius: 12
                    color: saveTap.pressed ? "#5E2750" : root.accent

                    Text {
                        anchors.centerIn: parent
                        text: noteController.saving ? "Saving..." : "Save changes"
                        color: "#FFFFFF"
                        font.pointSize: 20
                        font.weight: Font.DemiBold
                    }

                    TapHandler {
                        id: saveTap
                        enabled: root.loaded && !noteController.saving
                        onTapped: root.submit()
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: root.pageMargin + 8 }
            }
        }
    }

    Connections {
        target: noteController

        function onNoteUpdated() {
            if (root.StackView.view)
                root.StackView.view.pop()
        }

        function onUpdateFailed(message) {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }

        function onValidationFailed(message) {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }
    }
}
