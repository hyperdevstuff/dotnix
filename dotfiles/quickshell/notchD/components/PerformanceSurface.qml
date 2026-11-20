// SPDX-License-Identifier: GPL-3.0-only
// Caelestia-inspired resource hierarchy; see performance-attribution/README.md.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    property var metrics: ({})
    property var previous: null
    property string status: "Sampling…"
    property real cpu: -1
    property real download: -1
    property real upload: -1
    property var cpuHistory: []
    property var gpuHistory: []
    property var networkHistory: []
    readonly property bool wide: width >= 700
    readonly property real memory: metrics.memory ? metrics.memory.used / metrics.memory.total * 100 : -1
    readonly property real storage: metrics.storage ? metrics.storage.used / metrics.storage.total * 100 : -1
    function bytes(value) {
        if (!isFinite(value) || value < 0)
            return "—";
        if (value < 1024)
            return Math.round(value) + " B";
        if (value < 1048576)
            return (value / 1024).toFixed(1) + " KiB";
        if (value < 1073741824)
            return (value / 1048576).toFixed(1) + " MiB";
        return (value / 1073741824).toFixed(1) + " GiB";
    }
    function rate(value) {
        return value < 0 ? "Sampling…" : bytes(value) + "/s";
    }
    function uptime(value) {
        const m = Math.floor((value || 0) / 60);
        return (m >= 1440 ? Math.floor(m / 1440) + "d " : "") + Math.floor(m % 1440 / 60) + "h " + m % 60 + "m";
    }
    function refresh() {
        if (visible && !proc.running)
            proc.running = true;
    }
    function consume(data) {
        if (!data.cpu || !data.memory || !data.network || !data.storage || !data.gpu)
            throw new Error("Incomplete snapshot");
        const initial = previous === null;
        if (previous && data.time > previous.time) {
            const dt = data.time - previous.time;
            const total = data.cpu.total - previous.cpu.total;
            if (total > 0) {
                cpu = Math.max(0, Math.min(100, 100 * (1 - (data.cpu.idle - previous.cpu.idle) / total)));
                cpuHistory = cpuHistory.concat([cpu]).slice(-30);
            }
            download = Math.max(0, (data.network.rx - previous.network.rx) / dt);
            upload = Math.max(0, (data.network.tx - previous.network.tx) / dt);
            networkHistory = networkHistory.concat([download + upload]).slice(-30);
        }
        if (data.gpu.usage !== null)
            gpuHistory = gpuHistory.concat([data.gpu.usage]).slice(-30);
        metrics = data;
        previous = data;
        status = "Live · 2s";
        if (initial && visible)
            initialSample.restart();
    }
    // Establish a delta promptly on opening; then use the regular interval.
    Timer {
        id: initialSample
        interval: 250
        onTriggered: root.refresh()
    }
    Timer {
        interval: 2000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Process {
        id: proc
        command: ["notchd-metrics"]
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: proc.output = text
        }
        onExited: code => {
            try {
                if (code !== 0)
                    throw new Error("Could not sample metrics");
                root.consume(JSON.parse(output));
            } catch (e) {
                root.status = "Metrics unavailable";
                root.previous = null;
            }
        }
    }
    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown)
                contentY = Math.min(Math.max(0, contentHeight - height), contentY + 50);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp)
                contentY = Math.max(0, contentY - 50);
            else
                return;
            event.accepted = true;
        }
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "System monitor"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 5
                    height: 5
                    radius: 3
                    color: root.status.startsWith("Live") ? Theme.accent : Theme.muted
                }
                Text {
                    text: root.status
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width >= 560 ? 2 : 1
                        columnSpacing: 12
                        rowSpacing: 12
                        PerformanceHero {
                            Layout.fillWidth: true
                            title: "CPU"
                            glyph: "\uf2db"
                            subtitle: root.metrics.cpu ? root.metrics.cpu.name : "Processor"
                            value: root.cpu
                            temperature: root.metrics.cpu && root.metrics.cpu.temperature !== null ? root.metrics.cpu.temperature : -1
                            history: root.cpuHistory
                            status: root.cpu < 0 ? "Sampling" : "Load"
                        }
                        PerformanceHero {
                            Layout.fillWidth: true
                            title: "GPU"
                            glyph: "\uf108"
                            subtitle: root.metrics.gpu ? root.metrics.gpu.name : "Graphics"
                            value: root.metrics.gpu && root.metrics.gpu.usage !== null ? root.metrics.gpu.usage : -1
                            temperature: root.metrics.gpu && root.metrics.gpu.temperature !== null ? root.metrics.gpu.temperature : -1
                            history: root.gpuHistory
                            status: value < 0 ? root.metrics.gpu ? root.metrics.gpu.state : "Sampling" : "Load"
                            accent: Theme.secondary
                        }
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width >= 560 ? 3 : 1
                        columnSpacing: 12
                        rowSpacing: 12
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 162
                            radius: 20
                            color: Theme.surface
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 4
                                StatTitle {
                                    label: "Memory"
                                    glyph: "\uf2db"
                                }
                                UsageGauge {
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 82
                                    implicitHeight: 82
                                    value: root.memory
                                    accent: Theme.secondary
                                }
                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.metrics.memory ? root.bytes(root.metrics.memory.used) + " / " + root.bytes(root.metrics.memory.total) : "—"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 162
                            radius: 20
                            color: Theme.surface
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8
                                StatTitle {
                                    label: "Storage"
                                    glyph: "\uf0a0"
                                }
                                Text {
                                    text: root.storage < 0 ? "—" : Math.round(root.storage) + "%"
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: Theme.track
                                    Rectangle {
                                        width: parent.width * Math.max(0, root.storage) / 100
                                        height: parent.height
                                        radius: 3
                                        color: Theme.accent
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.metrics.storage ? root.bytes(root.metrics.storage.free) + " free" : "—"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Home filesystem"
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 162
                            radius: 20
                            color: Theme.surface
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 7
                                StatTitle {
                                    label: "Network"
                                    glyph: "\uf0ec"
                                }
                                Sparkline {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 24
                                    values: root.networkHistory
                                    maximum: Math.max(1024, ...root.networkHistory)
                                }
                                Text {
                                    text: "↓  " + root.rate(root.download)
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: "↑  " + root.rate(root.upload)
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
                BatteryMeter {
                    Layout.fillHeight: true
                    visible: root.wide
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Icon {
                    glyph: "\uf017"
                    size: 12
                    tint: Theme.muted
                }
                Text {
                    text: "Uptime " + root.uptime(root.metrics.uptime)
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Item {
                    Layout.fillWidth: true
                }
                Icon {
                    glyph: Services.System.powerProfile === 0 ? "\uf06c" : "\uf0e7"
                    size: 12
                    tint: Theme.muted
                }
                Text {
                    text: Services.System.powerProfileText
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }
    }
    component StatTitle: RowLayout {
        property string label: ""
        property string glyph: ""
        spacing: 7
        Icon {
            glyph: parent.glyph
            size: 14
            tint: Theme.accent
        }
        Text {
            text: parent.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }
}
