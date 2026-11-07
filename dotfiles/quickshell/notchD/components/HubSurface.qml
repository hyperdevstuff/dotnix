import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

// Horizontal hub. The clock is owned by NotchD.qml and stays at the exact
// centre of the surface in both the pill and hub shapes. This file only lays
// out the module chips around that centre gap: enabled modules are split
// evenly left and right, now-playing sits immediately left of the clock, and
// the Modules gear sits at the right edge.
Item {
    id: root

    property var state: null
    readonly property string screenName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""

    readonly property int chipH: 44
    // Space reserved for the centred clock. Must match the clock in NotchD.qml.
    readonly property int centerGap: 96
    readonly property int leftCount: Math.ceil(Modules.enabledIds.length / 2)

    // Smallest surface that contains the wider side plus the clock gap. The
    // clock stays at the centre, so the wider group is the limiting one.
    // NotchD.qml uses this as a floor for hubW: values such as "Balanced",
    // "Unavailable" or a visible now-playing chip must never clip the panel.
    readonly property real requiredWidth: Math.max(leftGroup.width, rightGroup.width) * 2
        + centerGap + 2 * Theme.hubSidePad

    // ------------------------------------------------------------ left side
    Row {
        id: leftGroup
        anchors.right: parent.horizontalCenter
        anchors.rightMargin: root.centerGap / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: root.leftCount

            delegate: HubChip {
                required property int index
                manifest: Modules.enabledManifests[index]
                focused: root.state && root.state.mode === "hub"
                    && root.state.hubIndex === index
                onHoveredChanged: if (hovered && root.state) root.state.hubIndex = index
                onActivated: if (root.state) {
                    root.state.hubIndex = index;
                    if (manifest) root.state.openFlyout(manifest.id);
                }
            }
        }

        // Now playing is last so it sits next to the clock, not at the edge.
        Rectangle {
            id: mediaChip
            visible: Services.Media.hasPlayer
            width: visible ? 108 : 0
            height: root.chipH
            radius: Theme.radiusControl
            color: mediaMouse.containsMouse ? Theme.surfaceHover : "transparent"
            border.width: root.state && root.state.mode === "media" ? 1 : 0
            border.color: Theme.fg

            Behavior on color { ColorAnimation { duration: 110 } }

            Row {
                anchors.centerIn: parent
                spacing: 6
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Services.Media.playing ? "\uf04c" : "\uf04b"
                    size: 12
                    tint: Services.Media.playing ? Theme.ok : Theme.muted
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, mediaChip.width - 44)
                    text: Services.Media.title.length > 0 ? Services.Media.title : "Now playing"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: mediaMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.state) root.state.openMedia()
            }
        }
    }

    // ----------------------------------------------------------- right side
    Row {
        id: rightGroup
        anchors.left: parent.horizontalCenter
        anchors.leftMargin: root.centerGap / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: Modules.enabledIds.length - root.leftCount

            delegate: HubChip {
                required property int index
                readonly property int hubPosition: root.leftCount + index
                manifest: Modules.enabledManifests[hubPosition]
                focused: root.state && root.state.mode === "hub"
                    && root.state.hubIndex === hubPosition
                onHoveredChanged: if (hovered && root.state) root.state.hubIndex = hubPosition
                onActivated: if (root.state) {
                    root.state.hubIndex = hubPosition;
                    if (manifest) root.state.openFlyout(manifest.id);
                }
            }
        }

        // Modules settings. Kept at the outer edge so it never crowds the
        // state chips next to the clock.
        Rectangle {
            id: settingsChip
            width: 34
            height: root.chipH
            radius: Theme.radiusControl
            color: settingsMouse.containsMouse ? Theme.surfaceHover : "transparent"

            Behavior on color { ColorAnimation { duration: 110 } }

            Icon {
                anchors.centerIn: parent
                glyph: "\uf013"
                size: 14
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

    // --------------------------------------------------------------- chips
    component HubChip: Rectangle {
        id: chip

        property var manifest: null
        property bool focused: false
        property bool hovered: false

        signal activated()

        readonly property string id: manifest ? String(manifest.id) : ""

        width: Math.max(64, chipContent.implicitWidth + 22)
        height: root.chipH
        radius: Theme.radiusControl
        color: chip.hovered || chip.focused ? Theme.surfaceHover : "transparent"
        border.width: chip.focused ? 1 : 0
        border.color: Theme.fg
        antialiasing: true

        Behavior on color { ColorAnimation { duration: 110 } }

        Row {
            id: chipContent
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                glyph: chip.manifest ? String(chip.manifest.icon) : "\uf128"
                size: 14
                tint: root.iconTint(chip.id)
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 96)
                text: root.valueFor(chip.id)
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 5
                height: 5
                radius: 3
                color: root.statusColor(chip.id)
                visible: color.a > 0
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
            return Services.System.volumeMuted ? Theme.warn : "transparent";
        case "battery":
            if (!Services.System.batteryReady) return "transparent";
            return Services.System.batteryCharging ? Theme.ok
                : (Services.System.batteryPercent <= 15 ? Theme.danger : "transparent");
        case "display":
            return Services.System.nightLight ? Theme.info : "transparent";
        default:
            return "transparent";
        }
    }

    function valueFor(id) {
        switch (id) {
        case "wifi":
            // The chip is deliberately short: the status dot carries the
            // connection state and the flyout shows the SSID. A long SSID here
            // would elide to something like "Manage…", which says nothing.
            return Services.Network.connected
                ? "On"
                : (Services.Network.wifiEnabled ? "No link" : "Off");
        case "bluetooth": {
            if (!Services.Bluetooth.available) return "Unavailable";
            if (!Services.Bluetooth.enabled) return "Off";
            const n = Services.Bluetooth.connectedCount;
            return n > 0 ? (n + " on") : "On";
        }
        case "audio":
            return Services.System.volumeMuted
                ? "Muted" : (Math.round(Services.System.volume * 100) + "%");
        case "battery":
            return Services.System.batteryReady
                ? (Services.System.batteryPercent + "%")
                : "AC";
        case "display":
            return Math.round(Services.System.brightness * 100) + "%";
        case "session":
            return Services.System.powerProfileText;
        default:
            return "";
        }
    }
}
