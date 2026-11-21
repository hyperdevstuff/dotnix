pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Only active graph links are evidence of capture. Direct V4L2 access bypasses
// PipeWire and cannot be observed here. Niri supplies screen-cast state.
Singleton {
    id: root

    readonly property bool available: Pipewire.ready
    readonly property var _nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var _links: Pipewire.links ? Pipewire.links.values : []
    property var _casts: []
    property bool _castStreamReady: false

    // Properties and link states require explicit tracking in Quickshell.
    PwObjectTracker { objects: root._nodes.concat(root._links) }

    readonly property var _capture: classifyLinks(root._links)
    readonly property bool screenAvailable: _castStreamReady

    function classifyLinks(links) {
        const microphone = [];
        const camera = [];
        for (let i = 0; i < links.length; ++i) {
            const link = links[i];
            if (!link || link.state !== PwLinkState.Active || !link.source || !link.target)
                continue;
            const source = link.source.properties || {};
            const target = link.target.properties || {};
            const sourceClass = String(source["media.class"] || "");
            const targetClass = String(target["media.class"] || "");
            const app = String(target["application.name"] || target["application.process.binary"] || "");
            if (sourceClass === "Audio/Source" && targetClass === "Stream/Input/Audio") {
                // A monitor is a speaker loopback, not a microphone.
                if (source["device.class"] !== "monitor" && source["node.name"] !== "monitor")
                    microphone.push(app);
            }
            if (sourceClass === "Video/Source" && targetClass === "Stream/Input/Video") {
                // Only classify a known camera source; a portal screen stream
                // is also Video/Source and must not become a camera badge.
                const api = String(source["device.api"] || "").toLowerCase();
                const role = String(source["media.role"] || "").toLowerCase();
                if (api === "v4l2" || api === "libcamera" || role === "camera")
                    camera.push(app);
            }
        }
        return { microphone: microphone, camera: camera };
    }

    function names(values) {
        const result = [];
        for (let i = 0; i < values.length; ++i) {
            const name = String(values[i] || "").trim();
            if (name && result.indexOf(name) < 0) result.push(name);
        }
        return result;
    }
    readonly property bool microphoneActive: _capture.microphone.length > 0
    readonly property bool cameraActive: _capture.camera.length > 0
    readonly property var microphoneApps: names(_capture.microphone)
    readonly property var cameraApps: names(_capture.camera)
    readonly property bool screenActive: _castStreamReady && _casts.some(c => c && c.is_active && c.pid !== Quickshell.processId)
    readonly property var screenApps: [] // niri does not reliably identify the receiving app
    readonly property bool anyActive: microphoneActive || cameraActive || screenActive

    // niri sends a snapshot on connection, followed by incremental events.
    function castEvent(line) {
        let event;
        try { event = JSON.parse(line); } catch (e) { return; }
        if (event.CastsChanged) {
            _casts = event.CastsChanged.casts || [];
            _castStreamReady = true;
        } else if (event.CastStartedOrChanged && event.CastStartedOrChanged.cast) {
            const cast = event.CastStartedOrChanged.cast;
            const list = _casts.filter(c => c.stream_id !== cast.stream_id);
            list.push(cast);
            _casts = list;
        } else if (event.CastStopped) {
            const id = event.CastStopped.stream_id;
            _casts = _casts.filter(c => c.stream_id !== id);
        }
    }
    Process {
        id: castEvents
        command: ["niri", "msg", "--json", "event-stream"]
        running: !!Quickshell.env("NIRI_SOCKET")
        stdout: SplitParser { onRead: line => root.castEvent(line) }
        onExited: {
            root._casts = [];
            root._castStreamReady = false;
            if (Quickshell.env("NIRI_SOCKET")) reconnect.start();
        }
    }
    Timer {
        id: reconnect
        interval: 1000
        onTriggered: castEvents.running = true
    }
}
