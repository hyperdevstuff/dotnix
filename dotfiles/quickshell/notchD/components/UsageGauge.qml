import QtQuick
import ".."

Item {
    id: root
    property real value: -1
    property color accent: Theme.accent
    property string label: value < 0 ? "—" : Math.round(value) + "%"
    property string caption: "Used"
    implicitWidth: 98
    implicitHeight: 98
    Canvas {
        id: arc
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const r = Math.max(1, Math.min(width, height) / 2 - 5);
            c.lineWidth = 6;
            c.lineCap = "round";
            c.strokeStyle = Theme.track;
            c.beginPath();
            c.arc(width / 2, height / 2, r, Math.PI * 0.75, Math.PI * 2.25);
            c.stroke();
            if (root.value > 0) {
                c.strokeStyle = root.accent;
                c.beginPath();
                c.arc(width / 2, height / 2, r, Math.PI * 0.75, Math.PI * (0.75 + 1.5 * Math.min(100, root.value) / 100));
                c.stroke();
            }
        }
    }
    onValueChanged: arc.requestPaint()
    onAccentChanged: arc.requestPaint()
    Connections {
        target: Theme
        function onTrackChanged() {
            arc.requestPaint();
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.accent
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.caption
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
