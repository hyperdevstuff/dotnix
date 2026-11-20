import QtQuick
import ".."

Canvas {
    id: root
    property var values: []
    property color accent: Theme.accent
    property real maximum: 100
    onValuesChanged: requestPaint()
    onAccentChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Text {
        anchors.centerIn: parent
        visible: root.values.length < 2
        text: "Collecting history…"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
    }
    onPaint: {
        const c = getContext("2d");
        c.reset();
        if (values.length < 2)
            return;
        const max = Math.max(1, maximum);
        function y(v) {
            return height - 3 - Math.max(0, Math.min(1, v / max)) * (height - 6);
        }
        c.lineWidth = 2;
        c.lineJoin = "round";
        c.lineCap = "round";
        c.strokeStyle = accent;
        c.beginPath();
        for (let i = 0; i < values.length; i++) {
            const x = 2 + i * (width - 4) / (values.length - 1);
            if (i === 0)
                c.moveTo(x, y(values[i]));
            else
                c.lineTo(x, y(values[i]));
        }
        c.stroke();
        c.lineTo(width - 2, height);
        c.lineTo(2, height);
        c.closePath();
        c.fillStyle = Qt.rgba(accent.r, accent.g, accent.b, 0.10);
        c.fill();
    }
}
