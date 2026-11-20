import QtQuick
import ".."

// One quiet, direct control: icon, track and value share a single baseline.
Item {
    id: root
    property string label: ""
    property string glyph: ""
    property real value: 0
    property bool muted: false
    property bool canToggle: false
    property bool dragging: false
    property real preview: 0
    readonly property real amount: dragging ? preview : Math.max(0, Math.min(1, value))
    signal moved(real value)
    signal toggled()
    implicitHeight: 38
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: label
    Keys.onPressed: event => {
        const delta = event.key === Qt.Key_Right || event.key === Qt.Key_Up ? 0.05
            : event.key === Qt.Key_Left || event.key === Qt.Key_Down ? -0.05 : 0;
        if (delta) { moved(Math.max(0, Math.min(1, value + delta))); event.accepted = true; }
    }
    Icon {
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        glyph: root.glyph
        size: 15
        tint: root.muted ? Theme.muted : Theme.fg
        MouseArea {
            anchors.fill: parent
            anchors.margins: -7
            enabled: root.canToggle
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }
    Item {
        id: track
        x: 36
        width: Math.max(0, parent.width - 82)
        height: 24
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: parent.width
            height: 5
            anchors.verticalCenter: parent.verticalCenter
            radius: 3
            color: Theme.track
            border.width: root.activeFocus ? 1 : 0
            border.color: Theme.muted
        }
        Rectangle {
            width: track.width * (root.muted ? 0 : root.amount)
            height: 5
            anchors.verticalCenter: parent.verticalCenter
            radius: 3
            color: Theme.accent
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function update(px) {
                root.preview = Math.max(0, Math.min(1, px / Math.max(1, width)));
                root.moved(root.preview);
            }
            onPressed: mouse => { root.preview = root.value; root.dragging = true; root.forceActiveFocus(); update(mouse.x); }
            onPositionChanged: mouse => { if (pressed) update(mouse.x); }
            onReleased: mouse => { update(mouse.x); root.dragging = false; }
            onCanceled: root.dragging = false
        }
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: root.muted ? "Muted" : Math.round(root.amount * 100) + "%"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontLabel
    }
}
