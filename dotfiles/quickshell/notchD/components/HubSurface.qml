import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    signal wallpapersRequested()
    readonly property real requiredWidth: 980
    property string tab: state ? state.hubTab : "Controls"

    function statusFor(id) {
        switch (id) {
        case "wifi": return Services.Network.connected ? "Connected" : Services.Network.wifiEnabled ? "No connection" : "Off";
        case "bluetooth": return !Services.Bluetooth.available ? "Unavailable" : !Services.Bluetooth.enabled ? "Off" : Services.Bluetooth.connectedCount ? Services.Bluetooth.connectedCount + " connected" : "On";
        case "audio": return Services.System.volumeMuted ? "Muted" : Math.round(Services.System.volume * 100) + "%";
        case "display": return Math.round(Services.System.brightness * 100) + "% brightness";
        case "battery": return Services.System.batteryReady ? Services.System.batteryPercent + "%" : "AC power";
        case "session": return Services.System.powerProfileText;
        default: return "";
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        // The media card remains available even when no player is running.
        Item {
            Layout.preferredWidth: Math.max(120, parent.width * 0.27)
            transform: Translate { x: root.visible ? 0 : -14; Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Layout.fillHeight: true
            MediaSurface { anchors.fill: parent; state: root.state }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Repeater {
                    model: ["Controls", "Performance", "Limits", "Clipboard"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        height: 32
                        radius: 10
                        color: root.tab === modelData ? Theme.surfaceHover : Theme.surface
                        Text { anchors.centerIn: parent; text: modelData; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.state) { root.state.hubTab = modelData; if (modelData === "Controls") root.forceActiveFocus(); } }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    visible: root.tab === "Controls"
                    Repeater {
                        model: Modules.enabledManifests
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            border.width: root.state && root.state.hubIndex === index && root.tab === "Controls" ? 1 : 0
                            border.color: Theme.fg
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: 12
                            color: controlMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Icon { glyph: String(modelData.icon); size: 14; tint: Theme.fg }
                                Column {
                                    spacing: 2
                                    Text { text: String(modelData.title); color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: Theme.fontBody }
                                    Text { text: root.statusFor(modelData.id); color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: Theme.fontLabel }
                                }
                            }
                            MouseArea { id: controlMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.state) { root.state.hubIndex = index; root.state.openFlyout(modelData.id); } }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 48; radius: 12; color: settingsMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        Text { anchors.centerIn: parent; text: "Settings"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: if (root.state) root.state.openFlyout("settings") }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 48; radius: 12; color: wallMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        Text { anchors.centerIn: parent; text: "Wallpapers"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 12 }
                        MouseArea { id: wallMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.wallpapersRequested() }
                    }
                }
                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    active: root.tab !== "Controls"
                    source: root.tab === "Performance" ? "PerformanceSurface.qml" : root.tab === "Limits" ? "UsageSurface.qml" : root.tab === "Clipboard" ? "ClipboardSurface.qml" : ""
                    onLoaded: {
                        if (item && item.state !== undefined) item.state = root.state;
                        if (item && item.refresh) item.refresh();
                        if (item && root.tab === "Clipboard") item.forceActiveFocus();
                        if (item && item.closeRequested) item.closeRequested.connect(function() { if (root.state) root.state.collapse(); });
                    }
                }
            }
        }
        ColumnLayout {
            Layout.preferredWidth: Math.max(120, parent.width * 0.25)
            transform: Translate { x: root.visible ? 0 : 14; Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
            Layout.fillHeight: true
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: "Notifications"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 14; font.weight: Font.DemiBold }
                Text { text: "Clear"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; MouseArea { anchors.fill: parent; onClicked: Services.Notifications.dismissAll() } }
            }
            Text { visible: Services.Notifications.count === 0; text: "You're all caught up"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 12 }
            Flickable {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentHeight: notificationsColumn.implicitHeight
                Column {
                    id: notificationsColumn; width: parent.width; spacing: 8
                    Repeater {
                        model: Services.Notifications.items
                        delegate: NotificationCard {
                            required property var modelData
                            width: notificationsColumn.width
                            notification: modelData
                        }
                    }
                }
            }
        }
    }
}
