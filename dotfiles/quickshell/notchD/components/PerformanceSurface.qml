import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    property string sample: ""
    property string status: "Loading system metrics…"
    property real cpu: -1
    property real memory: -1
    property string memoryText: "Unavailable"
    property string uptimeText: "Unavailable"
    property real previousTotal: 0
    property real previousIdle: 0
    function refresh() {
        if (visible && !proc.running)
            proc.running = true;
    }
    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
    Process {
        id: proc
        command: ["sh", "-c", "head -n 1 /proc/stat; cat /proc/meminfo; cat /proc/uptime"]
        stdout: StdioCollector {
            onTextChanged: root.sample = text
        }
        onExited: code => {
            if (code !== 0) {
                root.status = "System metrics unavailable";
                return;
            }
            const lines = root.sample.split("\n");
            const fields = lines[0].trim().split(/\s+/).slice(1).map(Number);
            if (fields.length < 4 || fields.some(isNaN)) {
                root.status = "Could not read system metrics";
                return;
            }
            // Guest time is already included in user/nice.
            const total = fields.slice(0, 8).reduce((a, b) => a + b, 0);
            const idle = fields[3] + (fields[4] || 0);
            if (root.previousTotal && total > root.previousTotal)
                root.cpu = Math.max(0, Math.min(100, 100 * (1 - (idle - root.previousIdle) / (total - root.previousTotal))));
            root.previousTotal = total;
            root.previousIdle = idle;
            const totalMatch = root.sample.match(/^MemTotal:\s+(\d+)/m);
            const availableMatch = root.sample.match(/^MemAvailable:\s+(\d+)/m);
            if (totalMatch && availableMatch && Number(totalMatch[1]) > 0) {
                const t = Number(totalMatch[1]), used = Math.max(0, t - Number(availableMatch[1]));
                root.memory = Math.min(100, 100 * used / t);
                root.memoryText = (used / 1048576).toFixed(1) + " / " + (t / 1048576).toFixed(1) + " GiB";
            }
            const up = lines[lines.length - 2].match(/^(\d+(?:\.\d+)?)/);
            if (up) {
                const mins = Math.floor(Number(up[1]) / 60);
                root.uptimeText = Math.floor(mins / 1440) + "d " + Math.floor(mins % 1440 / 60) + "h " + mins % 60 + "m";
            }
            root.status = "Live · updates every 5 seconds";
        }
    }
    Flickable {
        anchors.fill: parent
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                contentY = Math.min(Math.max(0, contentHeight - height), contentY + (event.key === Qt.Key_Down ? 40 : height));
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) {
                contentY = Math.max(0, contentY - (event.key === Qt.Key_Up ? 40 : height));
                event.accepted = true;
            }
        }
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 10
            Text {
                text: "Performance"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                text: root.status
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Repeater {
                model: [
                    {
                        title: "CPU",
                        value: root.cpu < 0 ? "Sampling…" : Math.round(root.cpu) + "%",
                        amount: root.cpu
                    },
                    {
                        title: "Memory",
                        value: root.memoryText,
                        amount: root.memory
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 75
                    radius: Theme.radius
                    color: Theme.surface
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.title
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.value
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 4
                            radius: 2
                            color: Theme.track
                            Rectangle {
                                width: parent.width * Math.max(0, modelData.amount) / 100
                                height: parent.height
                                radius: 2
                                color: Theme.fg
                            }
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                radius: Theme.radius
                color: Theme.surface
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Uptime"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Text {
                            text: root.uptimeText
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Power"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Services.System.powerProfileText + (Services.System.batteryReady ? " · " + Services.System.batteryPercent + "%" : "")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
