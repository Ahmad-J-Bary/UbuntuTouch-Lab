import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color accent: "#77216F"

    background: Rectangle {
        color: "#F5F5F5"
    }

    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(56, Math.min(root.width * 0.08, 72))
        color: root.headerBackground

        Text {
            anchors.left: parent.left
            anchors.leftMargin: Math.max(16, root.width * 0.04)
            anchors.verticalCenter: parent.verticalCenter
            text: "MiniNotes"
            color: root.headerForeground
            font.pixelSize: Math.max(20, Math.min(root.width * 0.04, 28))
            font.weight: Font.DemiBold
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 480)
        spacing: Math.max(14, root.width * 0.03)

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "📝"
            font.pixelSize: Math.max(72, Math.min(root.width * 0.18, 112))
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: noteController.noteCount === 0
                ? "No notes yet"
                : noteController.noteCount === 1 ? "1 note stored" : noteController.noteCount + " notes stored"
            color: "#333333"
            font.pixelSize: Math.max(22, Math.min(root.width * 0.04, 32))
            font.weight: Font.DemiBold
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Tap + to write your first note"
            color: "#888888"
            font.pixelSize: Math.max(16, Math.min(root.width * 0.032, 22))
            visible: noteController.noteCount === 0
        }
    }

    Rectangle {
        id: fab
        width: fabSize
        height: fabSize
        radius: fabSize / 2
        color: fabArea.pressed ? "#5E2750" : root.accent
        anchors.right: parent.right
        anchors.rightMargin: Math.max(20, root.width * 0.05)
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(24, root.width * 0.05)

        readonly property real fabSize: Math.max(64, Math.min(root.width * 0.14, 80))

        Text {
            anchors.centerIn: parent
            text: "+"
            color: "#FFFFFF"
            font.pixelSize: fabSize * 0.55
            font.weight: Font.Light
        }

        MouseArea {
            id: fabArea
            anchors.fill: parent
            onClicked: StackView.view.push("CreateNotePage.qml")
        }
    }
}