import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15

Page {
    id: root

    UiMetrics { id: ui }

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

    readonly property real pageMargin: ui.size(24, width, height)
    readonly property real headerHeight: ui.size(78, width, height)
    readonly property real controlHeight: ui.size(78, width, height)

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
                width: ui.size(88, root.width, root.height)
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    radius: ui.size(12, root.width, root.height)
                    color: backMouse.pressed ? root.headerPress : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: "←"
                    color: root.headerForeground
                    font.pointSize: ui.font(38, root.width, root.height)
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
                font.pointSize: ui.font(25, root.width, root.height)
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
                spacing: ui.size(14, root.width, root.height)

                Item { Layout.fillWidth: true; Layout.preferredHeight: ui.size(12, root.width, root.height) }

                Text {
                    text: "Title"
                    color: root.textSecondary
                    font.pointSize: ui.font(18, root.width, root.height)
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
                    font.pointSize: ui.font(20, root.width, root.height)
                    color: root.textPrimary
                    padding: ui.size(18, root.width, root.height)
                    verticalAlignment: TextInput.AlignVCenter
                    background: Rectangle {
                        radius: ui.size(10, root.width, root.height)
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
                    font.pointSize: ui.font(15, root.width, root.height)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                }

                Text {
                    text: "Content"
                    color: root.textSecondary
                    font.pointSize: ui.font(18, root.width, root.height)
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    Layout.topMargin: ui.size(8, root.width, root.height)
                }

                Rectangle {
                    id: bodyFrame

                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(ui.size(260, root.width, root.height), Math.min(root.height * 0.42, ui.size(400, root.width, root.height)))
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin

                    radius: ui.size(10, root.width, root.height)
                    color: "#FFFFFF"
                    border.color: bodyField.activeFocus ? root.accent : "#C9C9C9"
                    border.width: bodyField.activeFocus ? 2 : 1
                    clip: true

                    Flickable {
                        id: bodyFlick

                        anchors.fill: parent
                        anchors.margins: bodyFrame.border.width

                        clip: true
                        interactive: bodyField.activeFocus
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: Math.max(height, bodyField.height)

                        function ensureCursorVisible() {
                            var r = bodyField.cursorRectangle
                            var margin = ui.size(10, root.width, root.height)
                            var viewportTop = bodyFlick.contentY + margin
                            var viewportBottom = bodyFlick.contentY + bodyFlick.height - margin
                            var target = bodyFlick.contentY

                            if (r.y < viewportTop)
                                target = r.y - margin
                            else if (r.y + r.height > viewportBottom)
                                target = r.y + r.height - bodyFlick.height + margin

                            var maxY = Math.max(0, bodyFlick.contentHeight - bodyFlick.height)
                            bodyFlick.contentY = Math.max(0, Math.min(maxY, target))
                        }

                        TextArea {
                            id: bodyField
                            objectName: "bodyField"

                            width: bodyFlick.width
                            height: Math.max(
                                bodyFlick.height,
                                contentHeight + topPadding + bottomPadding + ui.size(4, root.width, root.height)
                            )

                            placeholderText: "Write your note..."
                            font.pointSize: ui.font(20, root.width, root.height)
                            color: root.textPrimary
                            padding: ui.size(17, root.width, root.height)
                            wrapMode: Text.Wrap
                            textFormat: TextEdit.PlainText
                            selectByMouse: false
                            selectByKeyboard: true
                            persistentSelection: false

                            background: Rectangle {
                                color: "transparent"
                            }

                            onCursorRectangleChanged: {
                                Qt.callLater(bodyFlick.ensureCursorVisible)
                            }

                            onTextChanged: {
                                if (attempted)
                                    validate()
                                Qt.callLater(bodyFlick.ensureCursorVisible)
                            }

                            onActiveFocusChanged: {
                                if (activeFocus)
                                    Qt.callLater(bodyFlick.ensureCursorVisible)
                            }
                        }
                    }
                }


                Text {
                    id: bodyError
                    visible: false
                    text: ""
                    color: root.errorColor
                    font.pointSize: ui.font(15, root.width, root.height)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                }

                Rectangle {
                    id: saveErrorBox
                    visible: false
                    Layout.fillWidth: true
                    Layout.preferredHeight: saveErrorLabel.implicitHeight + ui.size(30, root.width, root.height)
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    radius: ui.size(10, root.width, root.height)
                    color: "#FDECEA"
                    border.color: "#E7C2C0"
                    border.width: 1

                    Text {
                        id: saveErrorLabel
                        anchors.fill: parent
                        anchors.margins: ui.size(13, root.width, root.height)
                        text: ""
                        color: root.errorColor
                        font.pointSize: ui.font(15, root.width, root.height)
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    id: saveButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: ui.size(74, root.width, root.height)
                    Layout.leftMargin: root.pageMargin
                    Layout.rightMargin: root.pageMargin
                    Layout.topMargin: ui.size(8, root.width, root.height)
                    radius: ui.size(12, root.width, root.height)
                    color: saveTap.pressed ? "#5E2750" : root.accent

                    Text {
                        anchors.centerIn: parent
                        text: noteController.saving ? "Saving..." : "Save changes"
                        color: "#FFFFFF"
                        font.pointSize: ui.font(20, root.width, root.height)
                        font.weight: Font.DemiBold
                    }

                    TapHandler {
                        id: saveTap
                        enabled: root.loaded && !noteController.saving
                        onTapped: root.submit()
                    }
                }

                Item { Layout.fillWidth: true; Layout.preferredHeight: root.pageMargin + ui.size(8, root.width, root.height) }
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
