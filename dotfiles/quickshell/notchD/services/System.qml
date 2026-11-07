pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire

// System seam: battery, audio, brightness, power profiles, night light.
// Native Quickshell services are preferred; small CLI fallbacks only cover
// values the services do not expose (brightness, night light).
Singleton {
    id: root

    // ---------------------------------------------------------------- battery
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: !!battery && !!battery.isPresent
    readonly property bool batteryPresent: !!battery && !!battery.isPresent
    readonly property int batteryPercent: batteryReady ? Math.round(battery.percentage * 100) : 0
    readonly property bool batteryCharging: batteryReady && (battery.state === 1 || battery.state === 5)
    readonly property bool batteryFull: batteryReady && battery.state === 4
    readonly property real batteryHealth: (batteryReady && battery.healthSupported) ? Number(battery.healthPercentage) : -1
    readonly property bool batteryHealthSupported: batteryReady && !!battery.healthSupported
    readonly property real batteryWatts: batteryReady ? Math.abs(Number(battery.changeRate) || 0) : 0
    readonly property real batteryEnergy: batteryReady ? Number(battery.energy) || 0 : 0
    readonly property real batteryCapacity: batteryReady ? Number(battery.energyCapacity) || 0 : 0

    readonly property string batteryStateText: {
        if (!batteryReady) return "No battery";
        switch (battery.state) {
        case 1: return "Charging";
        case 2: return "Discharging";
        case 3: return "Empty";
        case 4: return "Fully charged";
        case 5: return "Charging";
        case 6: return "Discharging";
        default: return "On battery";
        }
    }

    readonly property string batteryTimeText: {
        if (!batteryReady) return "";
        if (batteryCharging && battery.timeToFull > 0) return formatDuration(battery.timeToFull) + " to full";
        if (!batteryCharging && battery.timeToEmpty > 0) return formatDuration(battery.timeToEmpty) + " left";
        return batteryStateText;
    }

    readonly property string batteryIcon: {
        if (!batteryReady) return "\uf244";
        if (batteryCharging) return "\uf0e7";
        const p = batteryPercent;
        if (p >= 88) return "\uf240";
        if (p >= 63) return "\uf241";
        if (p >= 38) return "\uf242";
        if (p >= 13) return "\uf243";
        return "\uf244";
    }

    // ---------------------------------------------------------------- power
    readonly property int powerProfile: PowerProfiles.profile        // 0 saver, 1 balanced, 2 performance
    readonly property bool hasPerformanceProfile: !!PowerProfiles.hasPerformanceProfile
    readonly property string powerProfileText: {
        if (powerProfile === 0) return "Power saver";
        if (powerProfile === 2) return "Performance";
        return "Balanced";
    }
    function setPowerProfile(profile) {
        PowerProfiles.profile = profile;
    }

    // ---------------------------------------------------------------- audio
    // Bind the default nodes so their audio properties become valid.
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
    readonly property bool audioReady: !!sink && !!sink.audio

    property real _wpctlVolume: 0.5
    property bool _wpctlMuted: false

    readonly property real volume: audioReady ? Number(sink.audio.volume) : _wpctlVolume
    readonly property bool volumeMuted: audioReady ? !!sink.audio.muted : _wpctlMuted

    readonly property real micVolume: (source && source.audio) ? Number(source.audio.volume) : 0.5
    readonly property bool micMuted: (source && source.audio) ? !!source.audio.muted : false

    readonly property string sinkName: nodeLabel(sink)
    readonly property string sourceName: nodeLabel(source)

    readonly property var sinks: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const n = all[i];
            if (!n || !n.audio) continue;
            if (!n.isSink || n.isStream || n.isMonitor) continue;
            out.push(n);
        }
        return out;
    }

    readonly property var sources: {
        const all = Pipewire.nodes ? Pipewire.nodes.values : [];
        const out = [];
        for (let i = 0; i < all.length; i++) {
            const n = all[i];
            if (!n || !n.audio) continue;
            if (n.isSink || n.isStream || n.isMonitor) continue;
            out.push(n);
        }
        return out;
    }

    function nodeLabel(node) {
        if (!node) return "";
        if (node.description) return String(node.description);
        if (node.nickname) return String(node.nickname);
        if (node.name) return String(node.name);
        return "Audio device";
    }

    function setVolume(value) {
        const v = Math.max(0, Math.min(1, Number(value) || 0));
        if (audioReady) sink.audio.volume = v;
        else { _wpctlVolume = v; Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(Math.round(v * 100)) + "%"]); }
    }

    function toggleMute() {
        if (audioReady) sink.audio.muted = !sink.audio.muted;
        else { _wpctlMuted = !_wpctlMuted; Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]); }
    }

    function setMicVolume(value) {
        const v = Math.max(0, Math.min(1, Number(value) || 0));
        if (source && source.audio) source.audio.volume = v;
        else Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", String(Math.round(v * 100)) + "%"]);
    }

    function toggleMicMute() {
        if (source && source.audio) source.audio.muted = !source.audio.muted;
        else Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node) {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    // ------------------------------------------------------------ brightness
    property real brightness: 0.5

    readonly property string brightnessText: Math.round(brightness * 100) + "%"

    function setBrightness(value) {
        const v = Math.max(0.01, Math.min(1, Number(value) || 0));
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", String(Math.round(v * 100)) + "%"]);
    }

    function stepBrightness(delta) {
        setBrightness(brightness + Number(delta || 0));
    }

    // Hardware keys change brightness through brightnessctl directly. Let the
    // OSD pull the new value instead of showing the last polled one.
    function refreshBrightness() { brightProc.running = true; }
    function refreshVolume() { volProc.running = true; }

    // ------------------------------------------------------------ night light
    // This GPU exposes no gamma control: niri advertises
    // zwlr_gamma_control_manager_v1 but the NVIDIA output answers `failed()`,
    // and gammastep then hangs forever instead of exiting. Night light is a
    // click-through tint overlay instead (see components/NightLight.qml).
    // Kelvin selects the tint colour; opacity scales with warmth. It is a warm
    // filter, not calibrated gamma, and it does not lift the black point much
    // at the default 0.34 maximum.
    property bool nightLight: false
    property int nightLightTemp: 3500

    readonly property int nightLightMin: 1700
    readonly property int nightLightMax: 6500
    readonly property color nightLightColor: root.kelvinColor(nightLightTemp)
    readonly property real nightLightAlpha: root.nightLight
        ? 0.34 * (root.nightLightMax - root.nightLightTemp) / (root.nightLightMax - root.nightLightMin)
        : 0.0
    readonly property string nightLightText: root.nightLight
        ? (root.nightLightTemp + "K · " + root.kelvinName(root.nightLightTemp))
        : "Off"

    function clamp255(v) { return Math.max(0, Math.min(255, v)); }

    // Tanner Helland's blackbody approximation. Good enough for a tint.
    function kelvinColor(k) {
        const t = Math.max(1000, Math.min(40000, Number(k) || 6500)) / 100;
        let r, g, b;
        if (t <= 66) {
            r = 255;
            g = 99.4708025861 * Math.log(t) - 161.1195681661;
            b = t <= 19 ? 0 : 138.5177312231 * Math.log(t - 10) - 305.0447927307;
        } else {
            r = 329.698727446 * Math.pow(t - 60, -0.1332047592);
            g = 288.1221695283 * Math.pow(t - 60, -0.0755148492);
            b = 255;
        }
        return Qt.rgba(root.clamp255(r) / 255, root.clamp255(g) / 255, root.clamp255(b) / 255, 1);
    }

    function kelvinName(k) {
        if (k <= 2200) return "candle";
        if (k <= 3000) return "very warm";
        if (k <= 4000) return "warm";
        if (k <= 5000) return "neutral";
        return "cool";
    }

    function setNightLight(enabled) { root.nightLight = !!enabled; }
    function toggleNightLight() { root.nightLight = !root.nightLight; }

    function setNightLightTemp(k) {
        const t = Math.max(root.nightLightMin, Math.min(root.nightLightMax, Math.round(Number(k) || 3500)));
        if (t === root.nightLightTemp) return;
        root.nightLightTemp = t;
        // Moving the control is intent to enable it.
        root.nightLight = true;
    }

    function stepNightLightTemp(delta) {
        root.setNightLightTemp(root.nightLightTemp + Math.round(Number(delta) || 100));
    }

    // ---------------------------------------------------------------- polling
    // Brightness has no native Quickshell service; poll it slowly so hardware
    // keys and external changes are reflected. PipeWire already pushes volume
    // changes, so wpctl is only polled while the service is unavailable.
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.audioReady) volProc.running = true;
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
        command: ["brightnessctl", "-m", "--class=backlight"]
        stdout: SplitParser {
            onRead: (line) => {
                const l = String(line).trim();
                if (l.length === 0) return;
                const parts = l.split(",");
                // brightnessctl -m: name,class,current,percent,max
                if (parts.length >= 4) {
                    const pct = parts[3].trim().replace("%", "");
                    const v = parseFloat(pct);
                    if (!isNaN(v)) root.brightness = v / 100.0;
                }
            }
        }
    }

    function formatDuration(seconds) {
        const s = Math.max(0, Number(seconds) || 0);
        const h = Math.floor(s / 3600);
        const m = Math.round((s % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }
}
