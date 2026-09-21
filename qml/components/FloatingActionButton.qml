import QtQuick 2.12

import "../theme"

Item {
    id: root

    property real visualSize: 100
    property real hitSize: 124

    property real viewportWidth: 360
    property real viewportHeight: 640

    property color accent: "#77216F"
    property color accentPressed: "#5E2750"

    signal clicked()

    width: root.hitSize
    height: root.hitSize

    UiMetrics {
        id: ui
    }

    Rectangle {
        id: fab

        width: root.visualSize
        height: root.visualSize

        anchors.centerIn: parent

        radius: width / 2

        color: fabTap.pressed
            ? root.accentPressed
            : root.accent

        scale: fabTap.pressed ? 0.96 : 1.0

        Text {
            anchors.centerIn: parent

            text: "+"

            color: "#FFFFFF"

            font.pointSize:
                ui.font(
                    44,
                    root.viewportWidth,
                    root.viewportHeight
                )

            font.weight: Font.Light
        }
    }

    TapHandler {
        id: fabTap

        onTapped: root.clicked()
    }
}
