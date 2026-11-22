pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

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

    readonly property var playbackLinks: Pipewire.links ? Pipewire.links.values : []
    PwObjectTracker {
        objects: root.playbackLinks.concat(Pipewire.nodes ? Pipewire.nodes.values : [])
    }

    // Active playback links also cover players that do not expose MPRIS.
    readonly property bool playbackActive: Media.players.some(player => player && player.isPlaying)
        || playbackLinks.some(link => link && link.state === PwLinkState.Active
            && link.source && link.source.properties?.["media.class"] === "Stream/Output/Audio"
            && link.target && link.target.isSink)
    readonly property bool suspendArmed: enabled && suspendEnabled && UPower.onBattery && !playbackActive
    readonly property bool suspendDue: suspendArmed && suspendMonitor.isIdle

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
        id: suspendMonitor
        timeout: root.suspendAfter
        // Disarm during playback. When playback ends, start a fresh timeout.
        enabled: root.suspendArmed
        respectInhibitors: true
    }
    onSuspendDueChanged: if (suspendDue) suspendRequested()
}
