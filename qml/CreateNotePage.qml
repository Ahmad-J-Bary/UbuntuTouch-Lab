import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color headerPress: "#4A1731"
    readonly property color pageBackground: "#F5F5F5"
    readonly property color textPrimary: "#333333"
    readonly property color textSecondary: "#777777"
    readonly property color accent: "#77216F"
    readonly property color errorColor: "#C1001E"
    readonly property color inputBackground: "#FFFFFF"
    readonly property color inputBorder: "#C9C9C9"

    background: Rectangle {
        color: root.pageBackground
    }

    Column {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            width: parent.width
            height: 56
            color: root.headerBackground

            Row {
                anchors.fill: parent
                leftPadding: 8
                rightPadding: 16
                spacing: 8

                Item {
                    id: backArea
                    width: 56
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
                        font.pixelSize: 34
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
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width - backArea.width
                }
            }
        }

        ScrollView {
            id: scroll
            width: parent.width
            height: parent.height - header.height
            clip: true

            Column {
                id: form
                width: scroll.width
                leftPadding: 16
                rightPadding: 16
                topPadding: 16
                bottomPadding: 24
                spacing: 10

                Text {
                    text: "Title"
                    color: root.textSecondary
                    font.pixelSize: 14
                }

                TextField {
                    id: titleField
                    objectName: "titleField"
                    width: form.width - form.leftPadding - form.rightPadding
                    height: 52
                    placeholderText: "Note title"
                    font.pixelSize: 18
                    color: root.textPrimary
                    padding: 12
                    selectByMouse: true

                    background: Rectangle {
                        radius: 4
                        color: root.inputBackground
                        border.color: titleField.activeFocus ? root.accent : root.inputBorder
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
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    width: form.width - form.leftPadding - form.rightPadding
                }

                Text {
                    text: "Content"
                    color: root.textSecondary
                    font.pixelSize: 14
                }

                TextArea {
                    id: bodyField
                    objectName: "bodyField"
                    width: form.width - form.leftPadding - form.rightPadding
                    height: 220
                    placeholderText: "Write your note..."
                    font.pixelSize: 18
                    color: root.textPrimary
                    padding: 12
                    wrapMode: Text.Wrap
                    selectByMouse: true

                    background: Rectangle {
                        radius: 4
                        color: root.inputBackground
                        border.color: bodyField.activeFocus ? root.accent : root.inputBorder
                        border.width: 1
                    }

                    onTextEdited: {
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
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    width: form.width - form.leftPadding - form.rightPadding
                }

                Rectangle {
                    id: saveErrorBox
                    objectName: "createPageErrorBox"
                    visible: false
                    width: form.width - form.leftPadding - form.rightPadding
                    height: saveErrorLabel.implicitHeight + 20
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
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    id: saveButton
                    width: form.width - form.leftPadding - form.rightPadding
                    height: 54
                    radius: 6
                    color: saveButtonArea.enabled ? root.accent : "#A98FA6"

                    Text {
                        anchors.centerIn: parent
                        text: noteController.saving ? "Saving..." : "Save"
                        color: saveButtonArea.enabled ? "#FFFFFF" : "#E6DDE4"
                        font.pixelSize: 18
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
        onNoteSaved: {
            if (root.StackView.view)
                root.StackView.view.pop()
        }
        onSaveFailed: {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }
        onValidationFailed: {
            saveErrorLabel.text = message
            saveErrorBox.visible = true
        }
    }
}