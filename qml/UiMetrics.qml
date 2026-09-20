import QtQuick 2.12

QtObject {
    readonly property real referenceWidth: 360
    readonly property real minimumScale: 1.12
    readonly property real maximumScale: 1.40
    readonly property real comfortBoost: 1.18

    function scaleFor(width, height) {
        var shortestSide = Math.min(width, height)
        var fit = shortestSide / referenceWidth
        return Math.max(
            minimumScale,
            Math.min(maximumScale, fit * comfortBoost)
        )
    }

    function size(base, width, height) {
        return Math.round(base * scaleFor(width, height))
    }

    function font(base, width, height) {
        return base * scaleFor(width, height)
    }
}
