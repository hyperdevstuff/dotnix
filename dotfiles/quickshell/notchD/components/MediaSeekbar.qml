import QtQuick
import ".."
import "../services" as Services

// Only the played segment waves. Seeking previews locally and commits on release.
Item {
    id: root
    implicitHeight: 42
    property bool dragging: false
    property real preview: 0
    property real phase: 0
    property real amplitude: Services.Media.playing ? 3 : 0
    Behavior on amplitude {
        enabled: !Motion.reduceMotion
        NumberAnimation {
            duration: Motion.fast
        }
    }
    onAmplitudeChanged: wave.requestPaint()
    readonly property real duration: Math.max(0, Services.Media.length)
    readonly property real position: dragging ? preview : Math.max(0, Services.Media.position)
    readonly property real fraction: duration > 0 ? Math.max(0, Math.min(1, position / duration)) : 0
    activeFocusOnTab: Services.Media.canSeek
    Accessible.role: Accessible.Slider
    Accessible.name: "Track position"
    Accessible.description: timeText(position) + " of " + timeText(duration)
    function timeText(seconds) {
        const s = Math.max(0, Math.floor(Number(seconds) || 0));
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60;
    }
    Keys.onPressed: event => {
        if (!Services.Media.canSeek)
            return;
        if (event.key === Qt.Key_Right)
            Services.Media.seek(position + 5);
        else if (event.key === Qt.Key_Left)
            Services.Media.seek(position - 5);
        else if (event.key === Qt.Key_Home)
            Services.Media.seek(0);
        else if (event.key === Qt.Key_End)
            Services.Media.seek(duration);
        else
            return;
        event.accepted = true;
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && Services.Media.playing
        triggeredOnStart: true
        onTriggered: Services.Media.updatePosition()
    }
    Timer {
        interval: 40
        repeat: true
        running: root.visible && Services.Media.playing && root.fraction > 0 && !root.dragging && !Motion.reduceMotion
        onTriggered: {
            root.phase = (root.phase + 0.18) % (Math.PI * 2);
            wave.requestPaint();
        }
    }
    Canvas {
        id: wave
        width: parent.width
        height: 24
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const end = Math.max(3, (width - 6) * root.fraction + 3);
            ctx.lineWidth = 3;
            ctx.lineCap = "round";
            ctx.strokeStyle = Theme.track;
            if (end + 8 < width - 3) {
                ctx.beginPath();
                ctx.moveTo(end + 8, 12);
                ctx.lineTo(width - 3, 12);
                ctx.stroke();
            }
            if (root.fraction > 0) {
                ctx.strokeStyle = Theme.accent;
                ctx.beginPath();
                for (let x = 3; x <= end; x += 1) {
                    const taper = Math.min(1, (end - x) / 8, (x - 3) / 8);
                    const y = 12 + Math.sin((x - 3) * Math.PI / 12 - root.phase) * root.amplitude * taper;
                    if (x === 3)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                ctx.stroke();
            }
            ctx.strokeStyle = root.activeFocus ? Theme.fg : Theme.accent;
            ctx.beginPath();
            ctx.moveTo(end, 6);
            ctx.lineTo(end, 18);
            ctx.stroke();
        }
    }
    onFractionChanged: wave.requestPaint()
    onActiveFocusChanged: wave.requestPaint()
    Connections {
        target: Theme
        function onAccentChanged() {
            wave.requestPaint();
        }
        function onTrackChanged() {
            wave.requestPaint();
        }
    }
    MouseArea {
        anchors.fill: parent
        anchors.bottomMargin: 14
        enabled: Services.Media.canSeek
        cursorShape: Qt.PointingHandCursor
        function update(px) {
            root.preview = Math.max(0, Math.min(1, (px - 3) / Math.max(1, width - 6))) * root.duration;
        }
        onPressed: mouse => {
            root.preview = root.position;
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
            Services.Media.seek(root.preview);
            root.dragging = false;
        }
        onCanceled: root.dragging = false
    }
    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        text: root.timeText(root.position)
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11 * Theme.textScale
    }
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        text: root.duration > 0 ? root.timeText(root.duration) : "—:—"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11 * Theme.textScale
    }
}
