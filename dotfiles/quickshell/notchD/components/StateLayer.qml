import QtQuick
import ".."

// One state at a time, tinted with the control's content color. Focus uses
// tonal emphasis without outlines or dash markers. No input handler
// or animation: keyboard navigation stays immediate and the owner keeps focus.
Item {
    id: root
    anchors.fill: parent
    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    property real radius: Theme.radiusSmall
    property color ink: Theme.fg
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.ink
        opacity: !root.enabled ? 0 : root.pressed ? Theme.pressedStateOpacity : root.focused ? Theme.focusStateOpacity : root.hovered ? Theme.hoverStateOpacity : 0
    }
}
