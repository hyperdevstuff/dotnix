import QtQuick
import ".."

// Filled M3-style track, visible handle, and an independent mute target.
Item {
    id: root
    property string label: ""
    property string glyph: ""
    property real value: 0
    property real displayValue: -1
    property bool muted: false
    property bool canToggle: false
    property bool dragging: false
    property real preview: 0
    readonly property real amount: dragging ? preview : Math.max(0, Math.min(1, value))
    signal moved(real value)
    signal toggled
    implicitHeight: 48
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: label
    Accessible.description: Math.round(amount * 100) + "%"
    Keys.onPressed: event => {
        const delta = event.key === Qt.Key_Right || event.key === Qt.Key_Up ? 0.05 : event.key === Qt.Key_Left || event.key === Qt.Key_Down ? -0.05 : 0;
        if (delta) {
            moved(Math.max(0, Math.min(1, value + delta)));
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            moved(0);
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            moved(1);
            event.accepted = true;
        }
    }
    Rectangle {
        width: 40
        height: 40
        radius: 14
        anchors.verticalCenter: parent.verticalCenter
        color: muteMouse.containsMouse ? Theme.surfaceHover : "transparent"
        Icon {
            anchors.centerIn: parent
            glyph: root.glyph
            size: 20
            tint: root.muted ? Theme.muted : Theme.fg
        }
        MouseArea {
            id: muteMouse
            anchors.fill: parent
            enabled: root.canToggle
            hoverEnabled: true
            cursorShape: root.canToggle ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.toggled()
        }
    }
    Item {
        id: track
        x: 48
        width: Math.max(1, parent.width - 92)
        height: 40
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 16
            radius: 8
            color: Theme.track
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, (parent.width - 8) * (root.muted ? 0 : root.amount))
            height: 16
            radius: 8
            color: root.muted ? Theme.muted : Theme.accent
        }
        Rectangle {
            x: (parent.width - width) * root.amount
            anchors.verticalCenter: parent.verticalCenter
            width: 4
            height: root.dragging ? 32 : 28
            radius: 2
            color: root.activeFocus ? Theme.fg : Theme.accent
            border.width: root.activeFocus ? 1 : 0
            border.color: Theme.panelSolid
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function update(px) {
                root.preview = Math.max(0, Math.min(1, px / Math.max(1, width)));
                root.moved(root.preview);
            }
            onPressed: mouse => {
                root.preview = root.value;
                root.dragging = true;
                root.forceActiveFocus();
                update(mouse.x);
            }
            onPositionChanged: mouse => {
                if (pressed)
                    update(mouse.x);
            }
            onReleased: mouse => {
                update(mouse.x);
                root.dragging = false;
            }
            onCanceled: root.dragging = false
        }
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: root.muted ? "Off" : Math.round((root.displayValue >= 0 ? root.displayValue : root.amount) * 100) + "%"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11 * Theme.textScale
    }
}
