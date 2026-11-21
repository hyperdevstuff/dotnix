pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// The caller must provide a shell window that remains visible while active.
// A Wayland idle inhibitor applies only while its surface is visible.
Singleton {
    id: root

    property var window: null
    property int durationMinutes: 0
    property double _deadline: 0
    property int remainingSeconds: 0
    readonly property bool active: _deadline > 0 && remainingSeconds > 0
    readonly property string remainingText: active
        ? Math.ceil(remainingSeconds / 60) + " min left" : "Off"

    function start(minutes) {
        const m = Number(minutes);
        if ((m !== 15 && m !== 30 && m !== 60) || !window || !window.visible)
            return false;
        durationMinutes = m;
        _deadline = Date.now() + m * 60000;
        remainingSeconds = m * 60;
        return true;
    }

    function stop() {
        _deadline = 0;
        remainingSeconds = 0;
        durationMinutes = 0;
    }

    function updateRemaining() {
        if (!_deadline) return;
        const seconds = Math.ceil((_deadline - Date.now()) / 1000);
        if (seconds <= 0) stop();
        else remainingSeconds = seconds;
    }

    // Never report an active inhibitor after the surface goes away.
    Connections {
        target: root.window
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            if (root.window && !root.window.visible) root.stop();
        }
    }
    onWindowChanged: if (!window || !window.visible) stop()

    IdleInhibitor {
        window: root.window
        enabled: root.active
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        onTriggered: root.updateRemaining()
    }
}
