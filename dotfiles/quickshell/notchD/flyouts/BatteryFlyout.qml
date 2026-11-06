import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Battery and power-profile flyout.
FlyoutFrame {
    id: root

    title: "Battery"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ------------------------------------------------------------- hero
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: 13
                color: Theme.surface
                border.width: 1
                border.color: Theme.hairlineSoft
                Icon {
                    anchors.centerIn: parent
                    glyph: Services.System.batteryIcon
                    size: 20
                    tint: Services.System.batteryCharging ? Theme.ok
                        : (Services.System.batteryPercent <= 15 && Services.System.batteryReady ? Theme.danger : Theme.fg)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: Services.System.batteryReady ? (Services.System.batteryPercent + "%") : "No battery"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.System.batteryReady ? Services.System.batteryTimeText : "This device is on AC power"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 8

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Theme.track
            }
            Rectangle {
                width: Services.System.batteryReady
                    ? Math.max(0, Math.min(parent.width, parent.width * Services.System.batteryPercent / 100))
                    : 0
                height: parent.height
                radius: 4
                color: Services.System.batteryCharging ? Theme.ok
                    : (Services.System.batteryPercent <= 15 ? Theme.danger : Theme.fg)
                Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            }
        }

        Text {
            Layout.fillWidth: true
            text: Services.System.batteryStateText + " · " + Services.System.powerProfileText
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        // ---------------------------------------------------------- details
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 5

            DetailLabel { text: "Health" }
            DetailValue {
                text: Services.System.batteryHealthSupported
                    ? (Math.round(Services.System.batteryHealth) + "%")
                    : "—"
            }

            DetailLabel { text: "Power draw" }
            DetailValue {
                text: Services.System.batteryReady
                    ? (Services.System.batteryWatts.toFixed(1) + " W")
                    : "—"
            }

            DetailLabel { text: "Energy" }
            DetailValue {
                text: Services.System.batteryReady && Services.System.batteryCapacity > 0
                    ? (Services.System.batteryEnergy.toFixed(1) + " / " + Services.System.batteryCapacity.toFixed(1) + " Wh")
                    : "—"
            }

            DetailLabel { text: "Power source" }
            DetailValue {
                text: Services.System.batteryCharging ? "AC · charging"
                    : (Services.System.batteryReady ? "Battery" : "AC")
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        // ---------------------------------------------------------- profiles
        Text {
            Layout.fillWidth: true
            text: "POWER PROFILE"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
            font.letterSpacing: 0.8
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            ProfileButton {
                Layout.fillWidth: true
                label: "Saver"
                glyph: "\uf06c"
                selected: Services.System.powerProfile === 0
                onPicked: Services.System.setPowerProfile(0)
            }
            ProfileButton {
                Layout.fillWidth: true
                label: "Balanced"
                glyph: "\uf24e"
                selected: Services.System.powerProfile === 1
                onPicked: Services.System.setPowerProfile(1)
            }
            ProfileButton {
                Layout.fillWidth: true
                label: "Performance"
                glyph: "\uf0e7"
                selected: Services.System.powerProfile === 2
                enabled: Services.System.hasPerformanceProfile
                onPicked: Services.System.setPowerProfile(2)
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: "Battery health and power draw come from UPower. Profiles come from power-profiles-daemon."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
            wrapMode: Text.WordWrap
            opacity: 0.8
        }

        Item { Layout.fillHeight: true }
    }

    component DetailLabel: Text {
        text: ""
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
        Layout.fillWidth: true
    }

    component DetailValue: Text {
        text: ""
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignRight
    }

    component ProfileButton: Rectangle {
        id: button
        property string label: ""
        property string glyph: ""
        property bool selected: false
        signal picked()

        height: 34
        radius: 9
        color: selected ? Theme.fg : (buttonMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
        border.width: 1
        border.color: selected ? Theme.fg : Theme.hairlineSoft
        opacity: enabled ? 1.0 : 0.4

        Column {
            anchors.centerIn: parent
            spacing: 0
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                glyph: button.glyph
                size: 10
                tint: button.selected ? Theme.accentInk : Theme.muted
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: button.label
                color: button.selected ? Theme.accentInk : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 8
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.picked()
        }
    }
}
