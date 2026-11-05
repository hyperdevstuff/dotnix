pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // Battery (UPower). percentage is a 0..1 fraction in Quickshell 0.3.2.
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: !!battery && !!battery.isPresent
    readonly property int batteryPercent: batteryReady ? Math.round(battery.percentage * 100) : 0
    readonly property bool batteryCharging: batteryReady && (battery.state === 1 || battery.state === 5)
    readonly property bool batteryPresent: battery ? !!battery.isPresent : false

    // Volume: prefer PipeWire service, fall back to wpctl polling.
    readonly property var _pipewireSink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    property real _wpctlVolume: 0.5
    property bool _wpctlMuted: false

    readonly property real volume: (_pipewireSink && _pipewireSink.audio)
        ? _pipewireSink.audio.volume
        : _wpctlVolume
    readonly property bool volumeMuted: (_pipewireSink && _pipewireSink.audio)
        ? _pipewireSink.audio.muted
        : _wpctlMuted

    // Brightness (polled)
    property real brightness: 0.5

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
                const l = String(line).trim();
                if (l.length === 0) return;
                const m = l.match(/Volume:\s*([\d.]+)/);
                if (m) {
                    const v = parseFloat(m[1]);
                    if (!isNaN(v)) root._wpctlVolume = v;
                }
                root._wpctlMuted = l.indexOf("[MUTED]") >= 0;
            }
        }
    }

    Process {
        id: brightProc
        command: ["brightnessctl", "-m"]
        stdout: SplitParser {
            onRead: (line) => {
                const l = String(line).trim();
                if (l.length === 0) return;
                const parts = l.split(",");
                // brightnessctl -m: name,class,current,percent,max  (parts[3] is percent)
                if (parts.length >= 4) {
                    const pct = parts[3].trim().replace("%", "");
                    const v = parseFloat(pct);
                    if (!isNaN(v)) root.brightness = v / 100.0;
                }
            }
        }
    }
}
