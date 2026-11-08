import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "services" as Services
import "components" as Components

// Auxiliary home surface: clock, live system stats, quick actions.
//
// It is a normal floating toplevel, not a layer shell, so it can be moved and
// resized like any app. niri floats it via the `title="^home$"` window rule.
// Toggle with:
//   quickshell ipc -c notchD call notchD toggleHome
FloatingWindow {
    id: root
    title: "home"
    implicitWidth: 980
    implicitHeight: 620
    visible: false

    property date now: new Date()
    property string memText: "—"
    property string memTotalText: "—"
    property string loadText: "—"
    property string uptimeText: "—"

    // ---------------------------------------------------------------- clock
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    // ---------------------------------------------------------------- stats
    // One cheap shell read every two seconds, and only while the window is
    // visible. /proc/meminfo is authoritative for "used" (total - available).
    Process {
        id: stats
        command: [
            "bash", "-c",
            "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f %.1f \", (t-a)/1048576, t/1048576}' /proc/meminfo; " +
            "awk '{printf \"%.2f \", $1}' /proc/loadavg; " +
            "awk '{printf \"%d\\n\", $1}' /proc/uptime"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                const p = String(line).trim().split(/\s+/);
                if (p.length < 4) return;
                root.memText = p[0];
                root.memTotalText = p[1];
                root.loadText = p[2];
                const secs = parseInt(p[3], 10);
                const d = Math.floor(secs / 86400);
                const h = Math.floor((secs % 86400) / 3600);
                const m = Math.floor((secs % 3600) / 60);
                root.uptimeText = (d > 0 ? d + "d " : "") + h + "h " + m + "m";
            }
        }
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        onTriggered: stats.running = true
    }

    onVisibleChanged: {
        if (visible) stats.running = true;
    }

    // --------------------------------------------------------------- surface
    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bgElev
        border.width: 1
        border.color: Theme.hairline
    }

    // Right-click on the empty surface opens the action menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onPressed: (mouse) => {
            contextMenu.x = Math.max(8, Math.min(mouse.x, root.width - contextMenu.width - 8));
            contextMenu.y = Math.max(8, Math.min(mouse.y, root.height - contextMenu.height - 8));
            contextMenu.visible = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 18

        // ------------------------------------------------------------ header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2

                Text {
                    text: "home"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }

                Text {
                    text: Qt.formatDateTime(root.now, "dddd, d MMMM")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.formatDateTime(root.now, "HH:mm")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 36
                font.weight: Font.Light
            }
        }

        // ------------------------------------------------------------ stats
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 12
            rowSpacing: 12

            Components.HomeCard {
                title: "memory"
                value: root.memText
                detail: "of " + root.memTotalText + " GB"
            }

            Components.HomeCard {
                title: "load"
                value: root.loadText
                detail: "1 min average"
            }

            Components.HomeCard {
                title: "uptime"
                value: root.uptimeText
                detail: "since boot"
            }

            Components.HomeCard {
                title: "battery"
                value: Services.System.batteryPercent + "%"
                detail: Services.System.batteryTimeText
            }

            Components.HomeCard {
                title: "audio"
                value: Math.round(Services.System.volume * 100) + "%"
                detail: Services.System.volumeMuted ? "muted" : Services.System.sinkName
            }

            Components.HomeCard {
                title: "power"
                value: Services.System.powerProfileText
                detail: "power profile"
            }
        }

        Item { Layout.fillHeight: true }

        // ----------------------------------------------------------- actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    { label: "Terminal", cmd: ["foot"] },
                    { label: "Browser", cmd: ["helium"] },
                    { label: "Files", cmd: ["dolphin"] },
                    { label: "Launcher", cmd: ["fuzzel"] }
                ]

                delegate: Rectangle {
                    required property var modelData

                    implicitWidth: 120
                    implicitHeight: 40
                    radius: Theme.radiusControl
                    color: actionHover.hovered ? Theme.surfaceHover : Theme.surface
                    border.width: 1
                    border.color: Theme.hairlineSoft

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    HoverHandler {
                        id: actionHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Quickshell.execDetached(modelData.cmd)
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "right-click for actions"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
            }
        }
    }

    // Click-away layer while the menu is open. Sits above the content but
    // below the menu card, so the menu rows still receive their taps.
    MouseArea {
        anchors.fill: parent
        visible: contextMenu.visible
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: contextMenu.visible = false
        z: 9
    }

    // ------------------------------------------------------------ action menu
    Rectangle {
        id: contextMenu
        visible: false
        width: 230
        height: menuColumn.implicitHeight + 12
        radius: Theme.radiusControl
        color: Theme.bgElev
        border.width: 1
        border.color: Theme.hairline
        z: 10

        Column {
            id: menuColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 6
            }
            spacing: 0

            Repeater {
                model: [
                    { label: "Terminal", cmd: ["foot"] },
                    { label: "Browser", cmd: ["helium"] },
                    { label: "Files", cmd: ["dolphin"] },
                    { label: "Launcher", cmd: ["fuzzel"], sep: true },
                    { label: "Random wallpaper", cmd: ["wp", "random"], sep: true },
                    { label: "Reload theme", cmd: ["wp", "refresh"] },
                    { label: "Light theme", cmd: ["wp", "theme", "light"], sep: true },
                    { label: "Dark theme", cmd: ["wp", "theme", "dark"] },
                    { label: "Auto theme", cmd: ["wp", "theme", "auto"] },
                    { label: "Lock", cmd: ["quickshell", "ipc", "-c", "notchD", "call", "notchD", "lock"], sep: true }
                ]

                delegate: Item {
                    required property var modelData

                    width: menuColumn.width
                    height: 34 + (modelData.sep ? 7 : 0)

                    Rectangle {
                        visible: modelData.sep === true
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            leftMargin: 8
                            rightMargin: 8
                        }
                        height: 1
                        color: Theme.hairline
                    }

                    Rectangle {
                        anchors {
                            top: parent.top
                            topMargin: modelData.sep ? 7 : 0
                            left: parent.left
                            right: parent.right
                        }
                        height: 34
                        radius: 8
                        color: rowHover.hovered ? Theme.surfaceHover : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.label
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                        }

                        HoverHandler {
                            id: rowHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: {
                                Quickshell.execDetached(modelData.cmd);
                                contextMenu.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (contextMenu.visible) contextMenu.visible = false;
            else root.visible = false;
        }
    }
}
