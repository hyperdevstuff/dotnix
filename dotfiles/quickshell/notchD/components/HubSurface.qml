import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    signal wallpapersRequested
    readonly property real requiredWidth: 980
    property string tab: state ? state.hubTab : "Controls"

    function statusFor(id) {
        switch (id) {
        case "wifi":
            return Services.Network.connected ? "Connected" : Services.Network.wifiEnabled ? "No connection" : "Off";
        case "bluetooth":
            return !Services.Bluetooth.available ? "Unavailable" : !Services.Bluetooth.enabled ? "Off" : Services.Bluetooth.connectedCount ? Services.Bluetooth.connectedCount + " connected" : "On";
        case "audio":
            return Services.System.volumeMuted ? "Muted" : Math.round(Services.System.volume * 100) + "%";
        case "display":
            return Math.round(Services.System.brightness * 100) + "% brightness";
        case "battery":
            return Services.System.batteryReady ? Services.System.batteryPercent + "%" : "AC power";
        case "session":
            return Services.System.powerProfileText;
        default:
            return "";
        }
    }

    // Dividers belong to the shared panel, not to separate cards.
    Rectangle {
        visible: columns.showSides
        x: columns.x + columns.sideWidth + columns.spacing / 2
        y: columns.y
        width: 1
        height: columns.height
        color: Theme.hairline
    }
    Rectangle {
        visible: columns.showSides
        x: columns.x + columns.width - columns.sideWidth - columns.spacing / 2
        y: columns.y
        width: 1
        height: columns.height
        color: Theme.hairline
    }

    Row {
        id: columns
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        readonly property bool showSides: width >= 760
        readonly property real sideWidth: Math.min(220, width * 0.24)
        // The media card remains available even when no player is running.
        Item {
            visible: columns.showSides
            width: columns.sideWidth
            height: columns.height
            transform: Translate {
                x: root.visible ? 0 : -14
                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
            MediaSurface {
                anchors.fill: parent
                state: root.state
            }
        }
        ColumnLayout {
            width: columns.showSides ? columns.width - 2 * columns.sideWidth - 2 * columns.spacing : columns.width
            height: columns.height
            spacing: 10
            RowLayout {
                Layout.fillWidth: true
                visible: root.tab !== "Controls"
                Repeater {
                    model: ["Controls", "Performance", "Limits", "Clipboard"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        height: 32
                        radius: 10
                        color: root.tab === modelData ? Theme.accent : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            textFormat: Text.PlainText
                            color: root.tab === modelData ? Theme.accentInk : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.state) {
                                root.state.hubTab = modelData;
                                if (modelData === "Controls")
                                    root.forceActiveFocus();
                            }
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                Flickable {
                    anchors.fill: parent
                    visible: root.tab === "Controls"
                    contentHeight: controlsColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                    id: controlsColumn
                    width: parent.width
                    spacing: 8
                    NotchSlider {
                        width: parent.width
                        height: 38
                        label: "Volume"
                        glyph: Services.System.volumeMuted ? "\uf026" : "\uf028"
                        value: Services.System.volume
                        muted: Services.System.volumeMuted
                        onMoved: v => Services.System.setVolume(v)
                        canToggle: true
                        onToggled: Services.System.toggleMute()
                    }
                    NotchSlider {
                        width: parent.width
                        height: 38
                        label: "Brightness"
                        glyph: "\uf185"
                        value: Services.System.brightness
                        canToggle: false
                        onMoved: v => Services.System.setBrightness(v)
                    }
                    Flow {
                        width: parent.width
                        spacing: 8
                        Repeater {
                            model: Modules.enabledManifests
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                readonly property bool active: modelData.id === "wifi" ? Services.Network.connected : modelData.id === "bluetooth" ? Services.Bluetooth.enabled : false
                                width: Math.max(65, (parent.width - 24) / 4)
                                height: 70
                                radius: 18
                                color: active ? Theme.accentContainer : controlMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                scale: controlMouse.pressed ? 0.97 : 1
                                Behavior on scale { NumberAnimation { duration: 110 } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    Icon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        glyph: String(modelData.icon)
                                        size: 17
                                        tint: active ? Theme.accentContainerInk : Theme.fg
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(modelData.title)
                                        color: active ? Theme.accentContainerInk : Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }
                                MouseArea {
                                    id: controlMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.state) {
                                        root.state.hubIndex = index;
                                        root.state.openFlyout(modelData.id);
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: Math.max(65, (parent.width - 24) / 4)
                            height: 70
                            radius: 18
                            color: Theme.surface
                            Text {
                                anchors.centerIn: parent
                                text: "Settings"
                                color: Theme.fg
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.state)
                                    root.state.openFlyout("settings")
                            }
                        }
                        Rectangle {
                            width: Math.max(65, (parent.width - 24) / 4)
                            height: 70
                            radius: 18
                            color: Theme.surface
                            Text {
                                anchors.centerIn: parent
                                text: "Wallpaper"
                                color: Theme.fg
                                font.pixelSize: 11
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.wallpapersRequested()
                            }
                        }
                    }
                    Text {
                        width: parent.width
                        text: "System  ·  " + root.statusFor("battery") + "  ·  " + root.statusFor("session")
                        color: Theme.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
                }
                Loader {
                    id: tabLoader
                    anchors.fill: parent
                    active: root.tab !== "Controls"
                    source: root.tab === "Performance" ? "PerformanceSurface.qml" : root.tab === "Limits" ? "UsageSurface.qml" : root.tab === "Clipboard" ? "ClipboardSurface.qml" : ""
                    onLoaded: {
                        if (item && item.state !== undefined)
                            item.state = root.state;
                        if (item && item.refresh)
                            item.refresh();
                        if (item && root.tab === "Clipboard")
                            item.forceActiveFocus();
                        if (item && item.closeRequested)
                            item.closeRequested.connect(function () {
                                if (root.state)
                                    root.state.collapse();
                            });
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: root.tab === "Controls"
                spacing: 8
                Repeater {
                    model: ["Performance", "Limits", "Clipboard"]
                    delegate: Rectangle {
                        required property string modelData
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: Theme.radiusSmall
                        color: navMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        scale: navMouse.pressed ? 0.98 : 1
                        Behavior on scale { NumberAnimation { duration: 110 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData + "  ›"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                        }
                        MouseArea {
                            id: navMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.state) root.state.hubTab = modelData
                        }
                    }
                }
            }
        }
        ColumnLayout {
            visible: columns.showSides
            width: columns.sideWidth
            height: columns.height
            transform: Translate {
                x: root.visible ? 0 : 14
                Behavior on x {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }
            Layout.fillHeight: true
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Clear"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Services.Notifications.dismissAll()
                    }
                }
            }
            Text {
                visible: Services.Notifications.count === 0
                text: "You're all caught up"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: notificationsColumn.implicitHeight
                Column {
                    id: notificationsColumn
                    width: parent.width
                    spacing: 8
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
