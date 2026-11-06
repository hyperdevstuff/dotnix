pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Idle actions driven by ext-idle-notify-v1. Three independent monitors so
// locking, blanking and suspending do not share a single timeout.
//
// The defaults are deliberately conservative for a laptop; shell.qml can
// disable individual actions or change the timeouts from settings later.
Singleton {
    id: root

    property bool enabled: true
    property bool displayOffEnabled: true
    property bool suspendEnabled: true

    // Seconds.
    property real lockAfter: 300          // 5 min
    property real displayOffAfter: 600    // 10 min
    property real suspendAfter: 1200      // 20 min

    signal lockRequested()
    signal displayOffRequested()
    signal suspendRequested()

    IdleMonitor {
        timeout: root.lockAfter
        enabled: root.enabled
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.lockRequested()
    }

    IdleMonitor {
        timeout: root.displayOffAfter
        enabled: root.enabled && root.displayOffEnabled
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.displayOffRequested()
    }

    IdleMonitor {
        timeout: root.suspendAfter
        enabled: root.enabled && root.suspendEnabled
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) root.suspendRequested()
    }
}
