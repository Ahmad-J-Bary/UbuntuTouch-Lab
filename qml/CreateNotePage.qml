import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color headerPress: "#4A1731"
    readonly property color textPrimary: "#333333"
    readonly property color textSecondary: "#777777"
    readonly property color accent: "#77216F"
    readonly property color errorColor: "#C1001E"

    readonly property real margin: Math.max(16, Math.min(root.width, root.height) * 0.04)
    readonly property real fieldHeight: Math.max(56, Math.min(root.height * 0.09, 72))

    background: Rectangle {
        color: "#F5F5F5"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(56, Math.min(root.width * 0.08, 72))
            color: root.headerBackground

            Row {
                anchors.fill: parent
                leftPadding: 8
                rightPadding: Math.max(16, root.width * 0.04)
                spacing: 8

                Item {
                    id: backArea
                    width: Math.max(56, Math.min(root.width * 0.12, 64))
                    height: parent.height

                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: backMouse.pressed ? root.headerPress : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "<"
                        color: root.headerForeground
                        font.pixelSize: Math.max(30, Math.min(root.width * 0.05, 40))
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        onClicked: {
                            if (!noteController.saving)
                                StackView.view.pop()
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "New Note"
                    color: root.headerForeground
                    font.pixelSize: Math.max(20, Math.min(root.width * 0.04, 28))
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width - backArea.width
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: root.margin
            Layout.rightMargin: root.margin
            Layout.topMargin: Math.max(12, root.margin * 0.75)
            Layout.bottomMargin: root.margin
            spacing: 10

            Text {
                text: "Title"
                color: root.textSecondary
                font.pixelSize: Math.max(15, Math.min(root.width * 0.03, 20))
                Layout.fillWidth: true
            }

            TextField {
                id: titleField
                objectName: "titleField"
                Layout.fillWidth: true
                Layout.preferredHeight: root.fieldHeight
                placeholderText: "Note title"
                font.pixelSize: Math.max(17, Math.min(root.width * 0.035, 24))
                color: root.textPrimary
                padding: 12
                selectByMouse: true

                background: Rectangle {
                    radius: 4
                    color: "#FFFFFF"
                    border.color: titleField.activeFocus ? root.accent : "#C9C9C9"
                    border.width: 1
                }

                Keys.onReturnPressed: bodyField.forceActiveFocus()
                Keys.onEnterPressed: bodyField.forceActiveFocus()
                onTextEdited: {
                    if (attempted)
                        validate()
                }
            }

            Text {
                id: titleError
                objectName: "titleError"
                visible: false
                text: ""
                color: root.errorColor
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Text {
                text: "Content"
                color: root.textSecondary
                font.pixelSize: Math.max(15, Math.min(root.width * 0.03, 20))
                Layout.fillWidth: true
            }

            TextArea {
                id: bodyField
                objectName: "bodyField"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 120
                placeholderText: "Write your note..."
                font.pixelSize: Math.max(17, Math.min(root.width * 0.035, 24))
                color: root.textPrimary
                padding: 12
                wrapMode: Text.Wrap
                selectByMouse: true

                background: Rectangle {
                    radius: 4
                    color: "#FFFFFF"
                    border.color: bodyField.activeFocus ? root.accent : "#C9C9C9"
                    border.width: 1
                }

                onTextChanged: {
                    if (attempted)
                        validate()
                }
            }

            Text {
                id: bodyError
                objectName: "bodyError"
                visible: false
                text: ""
                color: root.errorColor
                font.pixelSize: 13
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            Rectangle {
                id: saveErrorBox
                objectName: "createPageErrorBox"
                visible: false
                Layout.fillWidth: true
                Layout.preferredHeight: saveErrorLabel.implicitHeight + 20
                radius: 4
                color: "#FDECEA"
                border.color: "#E7C2C0"
                border.width: 1

                Text {
                    id: saveErrorLabel
                    anchors.fill: parent
                    anchors.margins: 10
                    text: ""
                    color: root.errorColor
                    font.pixelSize: 13
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                id: saveButton
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(56, Math.min(root.height * 0.09, 72))
                radius: 6
                color: saveButtonArea.enabled ? root.accent : "#A98FA6"

                Text {
                    anchors.centerIn: parent
                    text: noteController.saving ? "Saving..." : "Save"
                    color: saveButtonArea.enabled ? "#FFFFFF" : "#E6DDE4"
                    font.pixelSize: Math.max(18, Math.min(root.width * 0.035, 26))
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: saveButtonArea
                    anchors.fill: parent
                    enabled: !noteController.saving
                    onClicked: root.submit()
                }
            }
        }
    }

    property bool attempted: false

    function submit() {
        attempted = true
        if (validate()) {
            saveErrorBox.visible = false
            noteController.saveNote(titleField.text, bodyField.text)
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

    onVisibleChanged: {
        if (visible) {
            titleField.forceActiveFocus()
        }
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