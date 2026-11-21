import QtQuick
import ".."

// Opaque panel background. The pill and the expanded hub share this exact
// colour, so the morph never changes tone. The old top highlight is off by
// default: it caught the light at the rounded left edge and leaked white.
Rectangle {
    id: root

    property real panelRadius: Theme.radius
    property bool attachTop: false
    property bool showHighlight: false

    // Per-corner control so the hub and its flyout can share one continuous
    // edge (square inner corners) without a second panel component.
    property real cornerTopLeft: attachTop ? 0 : panelRadius
    property real cornerTopRight: attachTop ? 0 : panelRadius
    property real cornerBottomLeft: panelRadius
    property real cornerBottomRight: panelRadius

    color: Theme.panel
    border.width: 1
    border.color: Theme.hairline
    topLeftRadius: root.cornerTopLeft
    topRightRadius: root.cornerTopRight
    bottomLeftRadius: root.cornerBottomLeft
    bottomRightRadius: root.cornerBottomRight
    antialiasing: true

    Behavior on color {
        ColorAnimation {
            duration: 180
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 1
        height: 1
        radius: 1
        visible: root.showHighlight
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.65)
    }
}
