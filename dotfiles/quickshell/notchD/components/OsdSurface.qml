import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

// Compact OSD shown inside the island for volume, mic, brightness, battery,
// workspace changes and theme/night-light feedback.
Item {
    id: root

    property var state: null
    readonly property string kind: state ? state.osdKind : "generic"

    readonly property string derivedIcon: {
        switch (kind) {
        case "volume": return Services.System.volumeMuted ? "\uf027" : "\uf028";
        case "mic": return Services.System.micMuted ? "\uf131" : "\uf130";
        case "brightness": return "\uf185";
        case "battery": return Services.System.batteryIcon;
        case "workspace": return "\uf009";
        case "nightlight": return "\uf186";
        case "theme": return Theme.dark ? "\uf186" : "\uf185";
        default: return "\uf05a";
        }
    }

    readonly property string derivedTitle: {
        switch (kind) {
        case "volume": return "Volume";
        case "mic": return "Microphone";
        case "brightness": return "Brightness";
        case "battery": return "Battery";
        case "workspace": return "Workspace";
        case "nightlight": return "Night light";
        case "theme": return "Theme";
        default: return (state && state.osdTitle.length > 0) ? state.osdTitle : "notchD";
        }
    }

    readonly property string derivedText: {
        switch (kind) {
        case "volume": return Services.System.sinkName;
        case "mic": return Services.System.sourceName;
        case "battery": return Services.System.batteryTimeText;
        case "workspace": return Services.Compositor.activeWorkspaceName(Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
        case "nightlight": return Services.System.nightLightText;
        case "theme": return Theme.dark ? "Dark" : "Light";
        default: return (state && state.osdText.length > 0) ? state.osdText : "";
        }
    }

    readonly property string derivedValue: {
        switch (kind) {
        case "volume": return Services.System.volumeMuted ? "Muted" : (Math.round(Services.System.volume * 100) + "%");
        case "mic": return Services.System.micMuted ? "Muted" : (Math.round(Services.System.micVolume * 100) + "%");
        case "brightness": return Math.round(Services.System.brightness * 100) + "%";
        case "battery": return Services.System.batteryReady ? (Services.System.batteryPercent + "%") : "--";
        default: return (state && state.osdValue.length > 0) ? state.osdValue : "";
        }
    }

    readonly property real derivedProgress: {
        switch (kind) {
        case "volume": return Services.System.volumeMuted ? 0 : Services.System.volume;
        case "mic": return Services.System.micMuted ? 0 : Services.System.micVolume;
        case "brightness": return Services.System.brightness;
        case "battery": return Services.System.batteryReady ? Services.System.batteryPercent / 100 : 0;
        default: return (state && state.osdProgress >= 0) ? state.osdProgress : -1;
        }
    }

    readonly property bool showProgress: derivedProgress >= 0

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 10

        Icon {
            glyph: root.derivedIcon
            size: 15
            tint: (kind === "volume" && Services.System.volumeMuted) || (kind === "mic" && Services.System.micMuted)
                ? Theme.muted : Theme.fg
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: root.derivedTitle
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.derivedValue.length > 0
                    text: root.derivedValue
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Item {
                Layout.fillWidth: true
                height: 3
                visible: root.showProgress

                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: Theme.track
                }
                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * root.derivedProgress))
                    height: parent.height
                    radius: 2
                    color: (kind === "volume" && Services.System.volumeMuted)
                        || (kind === "mic" && Services.System.micMuted)
                        ? Theme.muted
                        : (kind === "battery" && Services.System.batteryPercent <= 15 ? Theme.danger : Theme.fg)
                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
            }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 38
        anchors.rightMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        visible: !root.showProgress && root.derivedText.length > 0
        text: root.derivedText
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
    }
}
