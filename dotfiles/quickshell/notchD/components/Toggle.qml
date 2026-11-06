import QtQuick
import ".."

// Small pill switch. The parent owns `checked` so it can stay bound to a
// service; this control only emits `toggled`.
Item {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled()

    implicitWidth: 40
    implicitHeight: 23
    opacity: enabled ? 1.0 : 0.45

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.track
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    Rectangle {
        id: knob
        width: 17
        height: 17
        radius: width / 2
        y: 3
        x: root.checked ? (track.width - width - 3) : 3
        color: root.checked ? Theme.accentInk : Theme.fg
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
