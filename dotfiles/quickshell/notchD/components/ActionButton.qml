import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property string label: ""
    property string symbol: ""
    property bool filled: false
    property bool tonal: false
    property bool selected: false
    signal clicked
    implicitWidth: label.length ? row.implicitWidth + 24 : 36
    implicitHeight: 36
    radius: 12
    color: !enabled ? Theme.surface : filled ? Theme.accent : selected || tonal ? Theme.accentContainer : mouse.pressed ? Theme.surfacePress : mouse.containsMouse || activeFocus ? Theme.surfaceHover : "transparent"
    readonly property color ink: filled ? Theme.accentInk : selected || tonal ? Theme.accentContainerInk : Theme.fg
    opacity: enabled ? 1 : 0.4
    border.color: activeFocus ? Theme.accent : "transparent"
    scale: mouse.pressed ? 0.97 : 1
    Behavior on scale {
        NumberAnimation {
            duration: Motion.reduceMotion ? 0 : 110
        }
    }
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label || symbol.replace(/_/g, " ")
    Accessible.onPressAction: if (enabled)
        clicked()
    Keys.onReturnPressed: if (enabled)
        clicked()
    Keys.onSpacePressed: if (enabled)
        clicked()
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        Symbol {
            visible: root.symbol.length > 0
            name: root.symbol
            size: 18
            tint: root.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.ink
            font.family: Theme.fontFamily
            font.pixelSize: 12 * Theme.textScale
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
