import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Bluetooth detail flyout.
FlyoutFrame {
    id: root

    title: "Bluetooth"

    rightContent: Toggle {
        checked: Services.Bluetooth.enabled
        enabled: Services.Bluetooth.available
        onToggled: Services.Bluetooth.toggle()
    }

    Component.onCompleted: {
        if (Services.Bluetooth.enabled) Services.Bluetooth.setDiscovering(true);
    }
    Component.onDestruction: Services.Bluetooth.setDiscovering(false)

    Connections {
        target: Services.Bluetooth
        function onEnabledChanged() {
            if (Services.Bluetooth.enabled) Services.Bluetooth.setDiscovering(true);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Icon {
                glyph: "\uf293"
                size: 12
                tint: Services.Bluetooth.enabled ? Theme.fg : Theme.muted
            }
            Text {
                Layout.fillWidth: true
                text: Services.Bluetooth.statusText
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
                elide: Text.ElideRight
            }
            Text {
                visible: Services.Bluetooth.discovering
                text: "Scanning…"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
            }
            Rectangle {
                width: 24
                height: 30
                radius: Theme.radiusControl
                color: scanMouse.containsMouse ? Theme.surfaceHover : "transparent"
                Icon {
                    anchors.centerIn: parent
                    glyph: Services.Bluetooth.discovering ? "\uf00d" : "\uf021"
                    size: 10
                    tint: Theme.muted
                }
                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Bluetooth.setDiscovering(!Services.Bluetooth.discovering)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: column.height

            Column {
                id: column
                width: flick.width
                spacing: 1

                Text {
                    width: parent.width
                    height: 18
                    verticalAlignment: Text.AlignBottom
                    text: "CONNECTED"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    font.letterSpacing: 0.8
                    visible: Services.Bluetooth.connectedDevices.length > 0
                }

                Repeater {
                    model: Services.Bluetooth.connectedDevices
                    delegate: DeviceRow {
                        required property var modelData
                        width: column.width
                        icon: root.deviceGlyph(modelData)
                        title: Services.Bluetooth.deviceLabel(modelData)
                        subtitle: root.deviceSubtitle(modelData)
                        busy: Services.Bluetooth.isBusy(modelData)
                        onActivated: Services.Bluetooth.pairOrConnect(modelData)
                    }
                }

                Text {
                    width: parent.width
                    height: 18
                    verticalAlignment: Text.AlignBottom
                    text: "PAIRED"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    font.letterSpacing: 0.8
                    visible: Services.Bluetooth.pairedDevices.length > 0
                    topPadding: 4
                }

                Repeater {
                    model: Services.Bluetooth.pairedDevices
                    delegate: DeviceRow {
                        required property var modelData
                        width: column.width
                        icon: root.deviceGlyph(modelData)
                        title: Services.Bluetooth.deviceLabel(modelData)
                        subtitle: root.deviceSubtitle(modelData)
                        busy: Services.Bluetooth.isBusy(modelData)
                        actionVisible: !Services.Bluetooth.isBusy(modelData)
                        actionText: "Forget"
                        actionDanger: true
                        onActivated: Services.Bluetooth.pairOrConnect(modelData)
                        onActionClicked: Services.Bluetooth.forget(modelData)
                    }
                }

                Text {
                    width: parent.width
                    height: 18
                    verticalAlignment: Text.AlignBottom
                    text: "AVAILABLE"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    font.letterSpacing: 0.8
                    visible: Services.Bluetooth.availableDevices.length > 0
                    topPadding: 4
                }

                Repeater {
                    model: Services.Bluetooth.availableDevices
                    delegate: DeviceRow {
                        required property var modelData
                        width: column.width
                        icon: root.deviceGlyph(modelData)
                        title: Services.Bluetooth.deviceLabel(modelData)
                        subtitle: root.deviceSubtitle(modelData)
                        busy: Services.Bluetooth.isBusy(modelData)
                        onActivated: Services.Bluetooth.pairOrConnect(modelData)
                    }
                }

                Text {
                    width: parent.width
                    visible: Services.Bluetooth.connectedDevices.length === 0
                        && Services.Bluetooth.pairedDevices.length === 0
                        && Services.Bluetooth.availableDevices.length === 0
                    text: Services.Bluetooth.enabled ? "No devices found" : "Bluetooth is off"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 40
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 30

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: Services.Bluetooth.errorMessage
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    elide: Text.ElideRight
                    visible: Services.Bluetooth.errorMessage.length > 0
                }

                Item { Layout.fillWidth: !Services.Bluetooth.errorMessage.length }

                Rectangle {
                    width: advancedLabel.implicitWidth + 16
                    height: 30
                    radius: Theme.radiusControl
                    color: advMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Row {
                        id: advancedLabel
                        anchors.centerIn: parent
                        spacing: 5
                        Icon { glyph: "\uf0ad"; size: 9; tint: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            text: "Passkey"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11 * Theme.textScale
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: advMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Bluetooth.openAdvanced()
                    }
                }
            }
        }
    }

    function deviceGlyph(device) {
        const n = String(device && (device.name || device.deviceName) || "").toLowerCase();
        if (n.indexOf("head") >= 0 || n.indexOf("bud") >= 0 || n.indexOf("airpod") >= 0 || n.indexOf("wh-") >= 0)
            return "\uf025";
        if (n.indexOf("keyboard") >= 0) return "\uf11c";
        if (n.indexOf("mouse") >= 0) return "\uf245";
        if (n.indexOf("speaker") >= 0 || n.indexOf("sound") >= 0) return "\uf028";
        if (n.indexOf("watch") >= 0) return "\uf017";
        if (n.indexOf("phone") >= 0) return "\uf10b";
        if (n.indexOf("gamepad") >= 0) return "\uf11b";
        return "\uf293";
    }

    function deviceSubtitle(device) {
        if (!device) return "";
        const parts = [];
        if (device.pairing) parts.push("Pairing…");
        else if (device.connected) parts.push("Connected");
        else if (device.paired || device.bonded) parts.push("Paired");
        else parts.push("Available");
        if (device.batteryAvailable) parts.push(Math.round(device.battery * 100) + "%");
        if (device.trusted && !device.connected) parts.push("Trusted");
        return parts.join(" · ");
    }
}
