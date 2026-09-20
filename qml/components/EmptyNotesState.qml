import QtQuick 2.12

import "../theme"

Item {
    id: root

    property real viewportWidth: 360
    property real viewportHeight: 640

    property color textPrimary: "#2D252B"
    property color textSecondary: "#6F676D"

    UiMetrics {
        id: ui
    }

    Column {
        anchors.centerIn: parent

        width: parent.width

        spacing:
            ui.size(
                14,
                root.viewportWidth,
                root.viewportHeight
            )

        Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: "📝"

            font.pointSize:
                ui.font(
                    70,
                    root.viewportWidth,
                    root.viewportHeight
                )
        }

        Text {
            width: parent.width

            text: "No notes yet"

            color: root.textPrimary

            font.pointSize:
                ui.font(
                    25,
                    root.viewportWidth,
                    root.viewportHeight
                )

            font.weight: Font.DemiBold

            horizontalAlignment:
                Text.AlignHCenter
        }

        Text {
            width: parent.width

            text: "Tap + to create your first note"

            color: root.textSecondary

            font.pointSize:
                ui.font(
                    18,
                    root.viewportWidth,
                    root.viewportHeight
                )

            wrapMode: Text.WordWrap

            horizontalAlignment:
                Text.AlignHCenter
        }
    }
}
