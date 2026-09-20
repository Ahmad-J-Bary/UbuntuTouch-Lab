import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: root

    readonly property color headerBackground: "#2C001E"
    readonly property color headerForeground: "#FFFFFF"
    readonly property color accent: "#77216F"
    readonly property color accentPressed: "#5E2750"

    // Mobile-first dimensions in Qt device-independent coordinates.
    readonly property real pageMargin:
        Math.max(20, Math.min(width * 0.055, 28))

    readonly property real headerHeight: 64

    readonly property real fabVisualSize: 96
    readonly property real fabHitSize: 112

    background: Rectangle {
        color: "#F5F5F5"
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

            font.pointSize: 21
            font.weight: Font.DemiBold

            verticalAlignment: Text.AlignVCenter
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom

        anchors.leftMargin: root.pageMargin
        anchors.rightMargin: root.pageMargin

        spacing: 18

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent

                width: Math.min(
                    parent.width,
                    420
                )

                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "📝"

                    font.pointSize: 56

                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap

                    text: noteController.noteCount === 0
                        ? "No notes yet"
                        : noteController.noteCount === 1
                            ? "1 note stored"
                            : noteController.noteCount + " notes stored"

                    color: "#333333"

                    font.pointSize: 21
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width

                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap

                    text: "Tap + to write your first note"

                    color: "#777777"

                    font.pointSize: 16

                    visible: noteController.noteCount === 0
                }
            }
        }
    }

    // Transparent touch target around the visible FAB.
    Item {
        id: fabHitArea

        width: root.fabHitSize
        height: root.fabHitSize

        anchors.right: parent.right
        anchors.bottom: parent.bottom

        anchors.rightMargin: 16
        anchors.bottomMargin: 16

        Rectangle {
            id: fab

            width: root.fabVisualSize
            height: root.fabVisualSize

            anchors.centerIn: parent

            radius: width / 2

            color: fabTap.pressed
                ? root.accentPressed
                : root.accent

            // Visual feedback.
            scale: fabTap.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 80
                }
            }

            Text {
                anchors.centerIn: parent

                text: "+"

                color: "#FFFFFF"

                font.pointSize: 38
                font.weight: Font.Light

                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }
        }

        TapHandler {
            id: fabTap

            // TapHandler is designed for both touchscreen taps and mouse clicks.
            onTapped: {
                var view = root.StackView.view

                if (view)
                    view.push("CreateNotePage.qml")
            }
        }
    }
}