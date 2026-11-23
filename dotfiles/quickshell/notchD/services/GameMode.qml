pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string unit: "notchd-game-mode.service"
    property bool active: false
    property bool failed: false
    readonly property bool busy: toggleProcess.running || statusProcess.running

    function refresh() {
        if (!busy)
            statusProcess.running = true;
    }

    function toggle() {
        if (busy)
            return;
        failed = false;
        toggleProcess.command = ["systemctl", "--user", active ? "stop" : "start", unit];
        toggleProcess.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProcess
        command: ["systemctl", "--user", "is-active", "--quiet", root.unit]
        onExited: code => root.active = code === 0
    }

    Process {
        id: toggleProcess
        onExited: code => {
            root.failed = code !== 0;
            statusProcess.running = true;
        }
    }
}
