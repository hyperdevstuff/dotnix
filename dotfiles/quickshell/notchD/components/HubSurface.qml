import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

// Horizontal hub: clock, one compact chip per enabled module, an optional
// now-playing chip and the module settings button. All detail opens sideways
// as a flyout; music is the only surface that grows downward.
Item {
    id: root

    property var state: null
    readonly property string screenName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 6

        // ------------------------------------------------------------- clock
        Item {
            Layout.preferredWidth: 44
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: -1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDate(clock.date, "ddd")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            color: Theme.hairlineSoft
        }

        // ------------------------------------------------------------- chips
        Repeater {
            model: Modules.enabledManifests

            delegate: HubChip {
                required property var modelData
                required property int index

                manifest: modelData
                focused: root.state && root.state.mode === "hub"
                    && root.state.hubIndex === index
                onHoveredChanged: if (hovered && root.state) root.state.hubIndex = index
                onActivated: if (root.state) {
                    root.state.hubIndex = index;
                    root.state.openFlyout(modelData.id);
                }
            }
        }

        // Nothing enabled: the hub still has to explain itself.
        Text {
            Layout.fillWidth: true
            visible: Modules.enabledIds.length === 0
            text: "No modules enabled"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }

        // ------------------------------------------------------- now playing
        Rectangle {
            id: mediaChip
            visible: Services.Media.hasPlayer
            Layout.preferredWidth: visible ? 32 : 0
            Layout.fillHeight: true
            radius: Theme.radiusSmall
            color: mediaMouse.containsMouse ? Theme.surfaceHover : "transparent"
            border.width: root.state && root.state.mode === "media" ? 1 : 0
            border.color: Theme.fg

            Behavior on color { ColorAnimation { duration: 110 } }

            Icon {
                anchors.centerIn: parent
                glyph: Services.Media.playing ? "\uf04c" : "\uf04b"
                size: 11
                tint: Services.Media.playing ? Theme.ok : Theme.muted
            }

            MouseArea {
                id: mediaMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.state) root.state.openMedia()
            }
        }

        // -------------------------------------------------------- settings
        Rectangle {
            id: settingsChip
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            radius: Theme.radiusSmall
            color: settingsMouse.containsMouse ? Theme.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 110 } }

            Icon {
                anchors.centerIn: parent
                glyph: "\uf013"
                size: 12
                tint: root.state && root.state.flyoutKind === "settings" ? Theme.fg : Theme.muted
            }

            MouseArea {
                id: settingsMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.state) root.state.openFlyout("settings")
            }
        }
    }

    // ------------------------------------------------------------- chip view
    component HubChip: Rectangle {
        id: chip

        property var manifest: null
        property bool focused: false
        property bool hovered: false

        signal activated()

        readonly property string id: manifest ? String(manifest.id) : ""

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Theme.radiusSmall
        color: chip.hovered || chip.focused ? Theme.surfaceHover : Theme.surface
        border.width: chip.focused ? 1 : 0
        border.color: Theme.fg
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 110 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 7

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.035)

                Icon {
                    anchors.centerIn: parent
                    glyph: chip.manifest ? String(chip.manifest.icon) : "\uf128"
                    size: 11
                    tint: root.iconTint(chip.id)
                }

                Rectangle {
                    width: 5
                    height: 5
                    radius: 3
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 2
                    anchors.topMargin: 2
                    color: root.statusColor(chip.id)
                    visible: color.a > 0
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: -1

                Text {
                    width: parent.width
                    text: chip.manifest ? String(chip.manifest.title) : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.valueFor(chip.id)
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: chip.hovered = true
            onExited: chip.hovered = false
            onClicked: chip.activated()
        }
    }

    // ------------------------------------------------------------------ data
    function iconTint(id) {
        switch (id) {
        case "wifi": return Services.Network.connected ? Theme.ok : Theme.fg;
        case "bluetooth": return Services.Bluetooth.connectedCount > 0 ? Theme.ok : Theme.fg;
        case "audio": return Services.System.volumeMuted ? Theme.muted : Theme.fg;
        case "battery": return Services.System.batteryCharging ? Theme.ok : Theme.fg;
        case "display": return Services.System.nightLight ? Theme.info : Theme.fg;
        default: return Theme.fg;
        }
    }

    function statusColor(id) {
        switch (id) {
        case "wifi":
            return Services.Network.connected ? Theme.ok
                : (Services.Network.wifiEnabled ? Theme.warn : Theme.muted);
        case "bluetooth":
            return Services.Bluetooth.connectedCount > 0 ? Theme.ok
                : (Services.Bluetooth.enabled ? Theme.info : Theme.muted);
        case "audio":
            return Services.System.volumeMuted ? Theme.warn : Theme.ok;
        case "battery":
            if (!Services.System.batteryReady) return "transparent";
            return Services.System.batteryCharging ? Theme.ok
                : (Services.System.batteryPercent <= 15 ? Theme.danger : Theme.muted);
        case "display":
            return Services.System.nightLight ? Theme.info : "transparent";
        default:
            return "transparent";
        }
    }

    function valueFor(id) {
        switch (id) {
        case "wifi":
            return Services.Network.connected
                ? (Services.Network.currentSsid || "Connected")
                : (Services.Network.wifiEnabled ? "Not connected" : "Off");
        case "bluetooth": {
            if (!Services.Bluetooth.available) return "Unavailable";
            if (!Services.Bluetooth.enabled) return "Off";
            const n = Services.Bluetooth.connectedCount;
            return n > 0 ? (n + " connected") : "On";
        }
        case "audio":
            return Services.System.volumeMuted
                ? "Muted" : (Math.round(Services.System.volume * 100) + "%");
        case "battery":
            return Services.System.batteryReady
                ? (Services.System.batteryPercent + "%")
                : "AC power";
        case "display":
            return Math.round(Services.System.brightness * 100) + "%"
                + (Services.System.nightLight ? " · Night" : "");
        case "session":
            return Services.System.powerProfileText;
        default:
            return "";
        }
    }
}
