import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Wi-Fi detail flyout.
FlyoutFrame {
    id: root

    property var state: null
    title: "Wi-Fi"

    rightContent: Toggle {
        checked: Services.Network.wifiEnabled
        enabled: Services.Network.available && Services.Network.hardwareEnabled
        onToggled: Services.Network.toggleWifi()
    }

    Component.onCompleted: Services.Network.setScanning(true)
    Component.onDestruction: Services.Network.setScanning(false)

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // ---------------------------------------------------------- status line
        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Icon {
                glyph: Services.Network.connected ? "\uf1eb" : "\uf071"
                size: 12
                tint: Services.Network.connected ? Theme.ok : Theme.muted
            }
            Text {
                Layout.fillWidth: true
                text: Services.Network.statusText
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }
            Text {
                visible: Services.Network.scanning
                text: "Scanning…"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Rectangle {
                width: 24
                height: 30
                radius: Theme.radiusControl
                color: scanMouse.containsMouse ? Theme.surfaceHover : "transparent"
                Icon {
                    anchors.centerIn: parent
                    glyph: "\uf021"
                    size: 10
                    tint: Theme.muted
                }
                MouseArea {
                    id: scanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Network.setScanning(true)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        // -------------------------------------------------------------- list
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 1
            model: Services.Network.networks
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            delegate: DeviceRow {
                required property var modelData
                width: ListView.view.width
                icon: modelData.connected ? "\uf1eb" : (modelData.known ? "\uf023" : "\uf1eb")
                title: String(modelData.name || "")
                subtitle: Services.Network.securityLabel(modelData.security)
                    + (modelData.known ? " · Saved" : "")
                    + (modelData.connected ? " · Connected" : "")
                selected: !!modelData.connected
                busy: Services.Network.busy && Services.Network.busyName === String(modelData.name || "")
                actionVisible: !!modelData.known && !modelData.connected && !modelData.stateChanging
                actionText: "Forget"
                actionDanger: true
                onActivated: Services.Network.connectTo(modelData)
                onActionClicked: Services.Network.forget(modelData)
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: Services.Network.available ? "No networks found" : "No Wi-Fi adapter"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        // ------------------------------------------------------------- footer
        Item {
            Layout.fillWidth: true
            height: 30

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: Services.Network.errorMessage
                    color: Theme.danger
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: Services.Network.errorMessage.length > 0
                }

                Item { Layout.fillWidth: !Services.Network.errorMessage.length }

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
                            text: "Advanced"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: advMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.Network.openAdvanced()
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- password card
    Rectangle {
        anchors.fill: parent
        visible: Services.Network.passwordPromptVisible
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.18)
        radius: Theme.radiusSmall

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 28
            height: 164
            radius: Theme.radiusSmall
            color: Theme.panelSolid
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: "Connect to " + (Services.Network.pendingNetwork ? Services.Network.pendingNetwork.name : "")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: Theme.radiusControl
                    color: Theme.surface
                    border.width: 1
                    border.color: pwd.activeFocus ? Theme.fg : Theme.hairline

                    TextInput {
                        id: pwd
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        echoMode: TextInput.Password
                        selectionColor: Theme.fg
                        selectedTextColor: Theme.bg
                        clip: true
                        focus: visible
                        onVisibleChanged: {
                            if (visible) { text = ""; forceActiveFocus(); }
                        }
                        onAccepted: Services.Network.submitPassword(text)
                        Keys.onEscapePressed: (event) => {
                            Services.Network.cancelPassword();
                            event.accepted = true;
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pwd.text.length === 0
                        text: "Password"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Cancel"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Network.cancelPassword()
                        }
                    }
                    Rectangle {
                        width: 74
                        height: 32
                        radius: Theme.radiusControl
                        color: Theme.fg
                        Text {
                            anchors.centerIn: parent
                            text: "Connect"
                            color: Theme.accentInk
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Network.submitPassword(pwd.text)
                        }
                    }
                }
            }
        }
    }
}
