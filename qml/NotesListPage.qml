import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color headerPress: "#4A1731"
    readonly property color pageBackground: "#F5F5F5"
    readonly property color textPrimary: "#333333"
    readonly property color accent: "#77216F"

    background: Rectangle {
        color: root.pageBackground
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 56
        color: root.headerBackground

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "MiniNotes"
            color: root.headerForeground
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 48
        spacing: 16

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "📝"
            font.pixelSize: 64
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: noteController.noteCount === 0
                ? "No notes yet"
                : noteController.noteCount === 1 ? "1 note stored" : noteController.noteCount + " notes stored"
            color: root.textPrimary
            font.pixelSize: 22
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Tap + to write your first note"
            color: "#888888"
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            visible: noteController.noteCount === 0
        }
    }

    Rectangle {
        id: fab
        width: 64
        height: 64
        radius: width / 2
        color: fabArea.pressed ? "#5E2750" : root.accent
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32

        Text {
            anchors.centerIn: parent
            text: "+"
            color: "#FFFFFF"
            font.pixelSize: 40
            font.weight: Font.Light
        }

        MouseArea {
            id: fabArea
            anchors.fill: parent
            onClicked: StackView.view.push("CreateNotePage.qml")
        }
    }
}