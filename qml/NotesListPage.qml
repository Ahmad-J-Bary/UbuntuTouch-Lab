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

    readonly property real pageMargin: 24
    readonly property real headerHeight: 78
    readonly property real fabVisualSize: 100
    readonly property real fabHitSize: 124

    background: Rectangle { color: root.backgroundColor }

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
            font.pointSize: 26
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
            font.pointSize: 16
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
        anchors.bottomMargin: root.pageMargin + root.fabHitSize + 10
        clip: true
        spacing: 16
        boundsBehavior: Flickable.StopAtBounds
        model: noteController.notesModel

        delegate: Item {
            id: noteCardItem
            width: notesView.width
            height: 144

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 16
                color: cardTap.pressed ? "#EEE8EC" : root.cardColor
                border.color: root.cardBorder
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 8

                    Text {
                        width: parent.width
                        text: title
                        color: root.textPrimary
                        font.pointSize: 21
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: body.replace(/\s+/g, " ")
                        color: root.textSecondary
                        font.pointSize: 18
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        text: updatedAt
                        color: "#918990"
                        font.pointSize: 14
                        elide: Text.ElideRight
                    }
                }

                TapHandler {
                    id: cardTap
                    onTapped: {
                        var view = root.StackView.view
                        if (view)
                            view.push("EditNotePage.qml", { "noteId": noteId })
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: Math.min(parent.width, 330)
            height: 290
            visible: noteController.noteCount === 0

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 14

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📝"
                    font.pointSize: 70
                }

                Text {
                    width: parent.width
                    text: "No notes yet"
                    color: root.textPrimary
                    font.pointSize: 25
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: "Tap + to create your first note"
                    color: root.textSecondary
                    font.pointSize: 18
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
        anchors.rightMargin: 10
        anchors.bottomMargin: 10

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
                font.pointSize: 44
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
}
