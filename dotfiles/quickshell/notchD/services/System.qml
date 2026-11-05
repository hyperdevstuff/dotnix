pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    // Battery
    readonly property var battery: UPower.displayDevice
    readonly property int batteryPercent: battery ? Math.round(battery.percentage * 100) : 0
    readonly property bool batteryCharging: battery ? (battery.state === 1 || battery.state === 5) : false
    readonly property bool batteryPresent: battery ? battery.isPresent : false

    // Volume / brightness (polled)
    property real volume: 0.5
    property real brightness: 0.5
    property bool volumeMuted: false

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volProc.running = true;
            brightProc.running = true;
        }
    }

    Process {
        id: volProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: SplitParser {
            onRead: (line) => {
                const m = line.match(/Volume:\s*([\d.]+)/);
                if (m) root.volume = parseFloat(m[1]);
                root.volumeMuted = line.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.split(",");
                if (parts.length >= 5) {
                    const pct = parts[4].replace("%", "").trim();
                    const v = parseFloat(pct);
                    if (!isNaN(v)) root.brightness = v / 100.0;
                }
            }
        }
    }
}