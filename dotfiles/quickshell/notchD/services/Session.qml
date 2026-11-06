pragma Singleton

import QtQuick
import Quickshell

// Session and power actions. Destructive actions are confirmed in the UI
// before they reach this seam. Locking is delegated to shell.qml so the native
// Quickshell lock screen owns the session lock instead of spawning swaylock.
Singleton {
    id: root

    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") || ""

    signal lockRequested()

    function lock() {
        root.lockRequested();
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function logout() {
        if (root.sessionId.length > 0)
            Quickshell.execDetached(["loginctl", "terminate-session", root.sessionId]);
        else
            Quickshell.execDetached(["niri", "msg", "action", "quit", "--skip-confirmation"]);
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function poweroff() {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function powerOffMonitors() {
        Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
    }
}
