import QtQuick
import ".."
import QtQuick.Layouts

// Volume / brightness / mic control with live drag updates and one commit
// on release. Mirrors Tide's interaction model without using its code.
Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string muteIconOn: "\uf028"
    property string muteIconOff: "\uf027"
    property real value: 0.5
    property bool muted: false
    property bool showMute: true
    property color fillColor: Theme.accent

    signal moved(real value)
    signal committed(real value)
    signal muteToggled
    signal cancelled

    implicitHeight: 68
    implicitWidth: 260

    property bool dragging: false
    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : Math.max(0, Math.min(1, value))

    ColumnLayout {
        anchors.fill: parent
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Icon {
                glyph: root.icon
                size: 14
                tint: root.muted ? Theme.muted : Theme.fg
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: root.title
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12 * Theme.textScale
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.subtitle
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: root.subtitle.length > 0
                }
            }

            Text {
                text: root.muted ? "Muted" : (Math.round(root.shownValue * 100) + "%")
                color: root.muted ? Theme.muted : Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12 * Theme.textScale
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
            }

            Item {
                visible: root.showMute
                width: 24
                height: 24
                Icon {
                    anchors.centerIn: parent
                    glyph: root.muted ? root.muteIconOff : root.muteIconOn
                    size: 13
                    tint: root.muted ? Theme.muted : Theme.fg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.muteToggled()
                }
            }
        }

        Item {
            id: trackArea
            Layout.fillWidth: true
            height: 18

            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: Theme.track
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, Math.min(track.width, track.width * root.shownValue))
                height: 4
                radius: 2
                color: root.muted ? Theme.muted : root.fillColor
                Behavior on width {
                    enabled: !root.dragging
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                width: 12
                height: 12
                radius: 6
                x: Math.max(0, Math.min(track.width - width, track.width * root.shownValue - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                color: root.muted ? Theme.muted : Theme.fg
                border.width: 1
                border.color: Theme.panelSolid
                Behavior on x {
                    enabled: !root.dragging
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                function applyAt(mx) {
                    const w = Math.max(1, track.width);
                    const v = Math.max(0, Math.min(1, mx / w));
                    root.dragValue = v;
                    root.moved(v);
                }

                onPressed: mouse => {
                    root.dragging = true;
                    applyAt(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (root.dragging)
                        applyAt(mouse.x);
                }
                onReleased: {
                    if (!root.dragging)
                        return;
                    root.dragging = false;
                    root.committed(root.dragValue);
                }
                onCanceled: {
                    if (!root.dragging)
                        return;
                    root.dragging = false;
                    root.cancelled();
                }
                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    const v = Math.max(0, Math.min(1, root.shownValue + step));
                    root.moved(v);
                    root.committed(v);
                }
            }
        }
    }
}
