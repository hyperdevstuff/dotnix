import QtQuick
import ".."

// Translucent panel background. niri blurs whatever is behind the window;
// this rectangle supplies the tint, hairline and top highlight.
Rectangle {
    id: root

    property real panelRadius: Theme.radius
    property bool attachTop: false
    property bool showHighlight: true

    color: Theme.panel
    border.width: 1
    border.color: Theme.hairline
    topLeftRadius: attachTop ? 0 : panelRadius
    topRightRadius: attachTop ? 0 : panelRadius
    bottomLeftRadius: panelRadius
    bottomRightRadius: panelRadius
    antialiasing: true

    Behavior on color { ColorAnimation { duration: 180 } }

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
