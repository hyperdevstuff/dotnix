import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Display flyout: backlight, night light, brightness presets.
FlyoutFrame {
    id: root

    title: "Display"

    rightContent: Toggle {
        checked: Services.System.nightLight
        onToggled: Services.System.toggleNightLight()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        SliderCard {
            Layout.fillWidth: true
            title: "Brightness"
            subtitle: Services.System.brightnessText + " · backlight"
            icon: "\uf185"
            showMute: false
            value: Services.System.brightness
            onMoved: (v) => Services.System.setBrightness(v)
            onCommitted: (v) => Services.System.setBrightness(v)
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: [25, 50, 75, 100]
                delegate: Rectangle {
                    required property int modelData
                    Layout.fillWidth: true
                    height: 26
                    radius: 8
                    color: presetMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.width: 1
                    border.color: Theme.hairlineSoft
                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Services.System.setBrightness(modelData / 100)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Rectangle {
            Layout.fillWidth: true
            height: 54
            radius: Theme.radiusSmall
            color: Theme.surface
            border.width: 1
            border.color: Theme.hairlineSoft

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 9

                Rectangle {
                    width: 26
                    height: 26
                    radius: 8
                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                    Icon {
                        anchors.centerIn: parent
                        glyph: "\uf186"
                        size: 13
                        tint: Services.System.nightLight ? Theme.info : Theme.fg
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "Night light"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                    Text {
                        text: Services.System.nightLight
                            ? "On · " + Services.System.nightLightTemp + "K"
                            : "Off · reduce blue light"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                    }
                }

                Toggle {
                    checked: Services.System.nightLight
                    onToggled: Services.System.toggleNightLight()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: Theme.radiusSmall
            color: powerMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.width: 1
            border.color: Theme.hairlineSoft

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                Icon { glyph: "\uf108"; size: 12; tint: Theme.muted }
                Text {
                    Layout.fillWidth: true
                    text: "Power off displays"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
                Icon { glyph: "\uf054"; size: 9; tint: Theme.hairline }
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Session.powerOffMonitors()
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: "Night light uses gammastep. Brightness uses brightnessctl, so it works without compositor support."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 8
            wrapMode: Text.WordWrap
            opacity: 0.8
        }

        Item { Layout.fillHeight: true }
    }
}
