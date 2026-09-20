import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color accent: "#77216F"
    readonly property color accentPressed: "#5E2750"
    readonly property color backgroundColor: "#F5F5F5"
    readonly property color cardColor: "#FFFFFF"
    readonly property color cardBorder: "#D8D3D7"
    readonly property color textPrimary: "#2D252B"
    readonly property color textSecondary: "#6F676D"
    readonly property color deleteColor: "#C62828"
    readonly property color deletePressed: "#9E1F1F"

    readonly property real uiScale: ui.scaleFor(width, height)
    readonly property real pageMargin: ui.size(24, width, height)
    readonly property real headerHeight: ui.size(78, width, height)
    readonly property real fabVisualSize: ui.size(100, width, height)
    readonly property real fabHitSize: ui.size(124, width, height)
    readonly property real deleteRevealWidth: ui.size(108, width, height)
    readonly property real deleteThreshold: ui.size(54, width, height)

    property int openedNoteId: -1

    UiMetrics { id: ui }

    background: Rectangle { color: root.backgroundColor }

    function closeSwipe() {
        root.openedNoteId = -1
    }

    function requestDelete(id, title) {
        root.closeSwipe()
        deleteDialog.noteId = id
        deleteDialog.noteTitle = title
        deleteDialog.deleteError = ""
        deleteDialog.open()
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerHeight
        color: root.headerBackground

        Text {
            anchors.left: parent.left
            anchors.leftMargin: root.pageMargin
            anchors.verticalCenter: parent.verticalCenter
            text: "MiniNotes"
            color: root.headerForeground
            font.pointSize: ui.font(26, root.width, root.height)
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: root.pageMargin
            anchors.verticalCenter: parent.verticalCenter
            text: noteController.noteCount === 0
                ? ""
                : noteController.noteCount === 1
                    ? "1 note"
                    : noteController.noteCount + " notes"
            color: "#E6DDE4"
            font.pointSize: ui.font(16, root.width, root.height)
            font.weight: Font.Medium
        }
    }

    ListView {
        id: notesView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.pageMargin
        anchors.rightMargin: root.pageMargin
        anchors.topMargin: root.pageMargin
        anchors.bottomMargin: root.pageMargin + root.fabHitSize + ui.size(14, root.width, root.height)
        clip: true
        spacing: ui.size(16, root.width, root.height)
        boundsBehavior: Flickable.StopAtBounds
        model: noteController.notesModel

        delegate: Item {
            id: delegateRoot
            width: notesView.width
            height: ui.size(154, root.width, root.height)

            property bool dragging: false
            property real pressX: 0

            onVisibleChanged: {
                if (!visible)
                    card.x = 0
            }

            Connections {
                target: root
                function onOpenedNoteIdChanged() {
                    if (root.openedNoteId !== noteId && !delegateRoot.dragging)
                        card.x = 0
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: ui.size(16, root.width, root.height)
                color: root.deleteColor

                Button {
                    id: deleteButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: root.deleteRevealWidth
                    enabled: !noteController.deleting

                    background: Rectangle {
                        radius: ui.size(16, root.width, root.height)
                        color: deleteButton.pressed
                            ? root.deletePressed
                            : root.deleteColor
                    }

                    contentItem: Column {
                        anchors.centerIn: parent
                        spacing: ui.size(4, root.width, root.height)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "×"
                            color: "#FFFFFF"
                            font.pointSize: ui.font(28, root.width, root.height)
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Delete"
                            color: "#FFFFFF"
                            font.pointSize: ui.font(14, root.width, root.height)
                            font.weight: Font.DemiBold
                        }
                    }

                    onClicked: root.requestDelete(noteId, title)
                }
            }

            Rectangle {
                id: card
                width: parent.width
                height: parent.height
                x: 0
                radius: ui.size(16, root.width, root.height)
                color: cardMouse.pressed ? "#EEE8EC" : root.cardColor
                border.color: root.cardBorder
                border.width: 1

                Behavior on x {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: ui.size(20, root.width, root.height)
                    spacing: ui.size(8, root.width, root.height)

                    Text {
                        width: parent.width
                        text: title
                        color: root.textPrimary
                        font.pointSize: ui.font(21, root.width, root.height)
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: body.replace(/\s+/g, " ")
                        color: root.textSecondary
                        font.pointSize: ui.font(18, root.width, root.height)
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: updatedAt
                        color: "#918990"
                        font.pointSize: ui.font(14, root.width, root.height)
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    preventStealing: true
                    drag.target: card
                    drag.axis: Drag.XAxis
                    drag.minimumX: -root.deleteRevealWidth
                    drag.maximumX: 0

                    onPressed: {
                        delegateRoot.pressX = mouse.x
                        delegateRoot.dragging = false
                    }

                    onPositionChanged: {
                        if (Math.abs(card.x) > ui.size(6, root.width, root.height))
                            delegateRoot.dragging = true
                    }

                    onReleased: {
                        if (card.x <= -root.deleteThreshold) {
                            root.openedNoteId = noteId
                            card.x = -root.deleteRevealWidth
                        } else {
                            root.openedNoteId = -1
                            card.x = 0
                        }
                    }

                    onClicked: {
                        if (delegateRoot.dragging)
                            return

                        if (card.x < -ui.size(16, root.width, root.height)) {
                            card.x = 0
                            root.openedNoteId = -1
                            return
                        }

                        var view = root.StackView.view
                        if (view)
                            view.push("EditNotePage.qml", { "noteId": noteId })
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, ui.size(330, root.width, root.height))
            height: ui.size(290, root.width, root.height)
            visible: noteController.noteCount === 0

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: ui.size(14, root.width, root.height)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📝"
                    font.pointSize: ui.font(70, root.width, root.height)
                }

                Text {
                    width: parent.width
                    text: "No notes yet"
                    color: root.textPrimary
                    font.pointSize: ui.font(25, root.width, root.height)
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Tap + to create your first note"
                    color: root.textSecondary
                    font.pointSize: ui.font(18, root.width, root.height)
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Item {
        id: fabHitArea
        width: root.fabHitSize
        height: root.fabHitSize
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: ui.size(10, root.width, root.height)
        anchors.bottomMargin: ui.size(10, root.width, root.height)

        Rectangle {
            id: fab
            width: root.fabVisualSize
            height: root.fabVisualSize
            anchors.centerIn: parent
            radius: width / 2
            color: fabTap.pressed ? root.accentPressed : root.accent
            scale: fabTap.pressed ? 0.96 : 1.0

            Text {
                anchors.centerIn: parent
                text: "+"
                color: "#FFFFFF"
                font.pointSize: ui.font(44, root.width, root.height)
                font.weight: Font.Light
            }
        }

        TapHandler {
            id: fabTap
            onTapped: {
                var view = root.StackView.view
                if (view)
                    view.push("CreateNotePage.qml")
            }
        }
    }

    Dialog {
        id: deleteDialog
        modal: true
        title: "Delete note?"

        // Give the dialog a wider body and smaller fixed outer margins.
        // The content typography and control sizes remain unchanged.
        width: Math.min(root.width - 20, 520)
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        // Extra breathing room belongs to the dialog surface, not the controls.
        padding: 22

        property int noteId: -1
        property string noteTitle: ""
        property string deleteError: ""

        contentItem: ColumnLayout {
            spacing: ui.size(16, root.width, root.height)

            Text {
                Layout.fillWidth: true
                text: deleteDialog.noteTitle
                color: root.textPrimary
                font.pointSize: ui.font(18, root.width, root.height)
                font.weight: Font.DemiBold
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "This note will be permanently deleted."
                color: root.textSecondary
                font.pointSize: ui.font(16, root.width, root.height)
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: deleteDialog.deleteError.length > 0
                text: deleteDialog.deleteError
                color: root.deleteColor
                font.pointSize: ui.font(14, root.width, root.height)
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: ui.size(10, root.width, root.height)

                Button {
                    id: confirmDeleteButton
                    Layout.fillWidth: true
                    implicitHeight: ui.size(58, root.width, root.height)
                    text: "Delete"
                    enabled: !noteController.deleting

                    background: Rectangle {
                        radius: ui.size(8, root.width, root.height)
                        color: confirmDeleteButton.pressed
                            ? "#A91F1F"
                            : "#C62828"
                        opacity: confirmDeleteButton.enabled ? 1.0 : 0.55
                    }

                    contentItem: Text {
                        text: confirmDeleteButton.text
                        color: "#FFFFFF"
                        font.pointSize: ui.font(17, root.width, root.height)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        deleteDialog.deleteError = ""
                        noteController.deleteNote(deleteDialog.noteId)
                    }
                }

                Button {
                    id: cancelDeleteButton
                    Layout.fillWidth: true
                    implicitHeight: ui.size(58, root.width, root.height)
                    text: "Cancel"
                    enabled: !noteController.deleting

                    background: Rectangle {
                        radius: ui.size(8, root.width, root.height)
                        color: cancelDeleteButton.pressed
                            ? "#5F5F5F"
                            : "#757575"
                        opacity: cancelDeleteButton.enabled ? 1.0 : 0.55
                    }

                    contentItem: Text {
                        text: cancelDeleteButton.text
                        color: "#FFFFFF"
                        font.pointSize: ui.font(17, root.width, root.height)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: deleteDialog.close()
                }
            }
        }
    }

    Connections {
        target: noteController

        function onNoteDeleted(id) {
            if (id === deleteDialog.noteId)
                deleteDialog.close()
        }

        function onDeleteFailed(message) {
            deleteDialog.deleteError = message
            deleteDialog.open()
        }
    }
}
