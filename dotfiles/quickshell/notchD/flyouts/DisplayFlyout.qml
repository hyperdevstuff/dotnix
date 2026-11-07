import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Display flyout: backlight, night-light Kelvin control, monitor power.
FlyoutFrame {
    id: root

    title: "Display"

    readonly property bool nightOn: Services.System.nightLight
    readonly property real kelvinPos: {
        const min = Services.System.nightLightMin;
        const max = Services.System.nightLightMax;
        return (Services.System.nightLightTemp - min) / (max - min);
    }

    function kelvinAt(x, width) {
        const min = Services.System.nightLightMin;
        const max = Services.System.nightLightMax;
        const p = Math.max(0, Math.min(1, x / Math.max(1, width)));
        return Math.round(min + p * (max - min));
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

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
            spacing: 6

            Repeater {
                model: [25, 50, 75, 100]
                delegate: Rectangle {
                    required property int modelData
                    Layout.fillWidth: true
                    height: 30
                    radius: Theme.radiusControl
                    color: presetMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                    border.width: 1
                    border.color: Theme.hairlineSoft
                    Text {
                        anchors.centerIn: parent
                        text: modelData + "%"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
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

        // ------------------------------------------------------- night light
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Icon {
                    glyph: "\uf186"
                    size: 15
                    tint: root.nightOn ? Theme.warn : Theme.muted
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Night light"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                        font.weight: Font.Medium
                    }
                    Text {
                        text: Services.System.nightLightText
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                    }
                }

                Toggle {
                    checked: root.nightOn
                    onToggled: Services.System.toggleNightLight()
                }
            }

            Item {
                id: kelvinArea
                Layout.fillWidth: true
                height: 26
                opacity: root.nightOn ? 1.0 : 0.45

                Behavior on opacity { NumberAnimation { duration: 140 } }

                Rectangle {
                    id: kelvinTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ffb066" }
                        GradientStop { position: 0.55; color: "#ffd9b3" }
                        GradientStop { position: 1.0; color: "#cfe0ff" }
                    }
                }

                Rectangle {
                    id: kelvinKnob
                    width: 16
                    height: 16
                    radius: 8
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * root.kelvinPos - width / 2))
                    color: Theme.fg
                    border.width: 2
                    border.color: Theme.panelSolid
                    Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (mouse) => Services.System.setNightLightTemp(root.kelvinAt(mouse.x, width))
                    onPositionChanged: (mouse) => {
                        if (pressed)
                            Services.System.setNightLightTemp(root.kelvinAt(mouse.x, width));
                    }
                    onWheel: (wheel) => Services.System.stepNightLightTemp(wheel.angleDelta.y > 0 ? -100 : 100)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Warm " + Services.System.nightLightMin + "K"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Cool " + Services.System.nightLightMax + "K"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [2700, 3400, 4500, 5500]
                    delegate: Rectangle {
                        required property int modelData
                        readonly property bool active: Services.System.nightLightTemp === modelData
                        Layout.fillWidth: true
                        height: 30
                        radius: Theme.radiusControl
                        color: active ? Theme.surfaceHover
                                      : (presetKelvinMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
                        border.width: 1
                        border.color: active ? Theme.fg : Theme.hairlineSoft
                        opacity: root.nightOn ? 1.0 : 0.45
                        Text {
                            anchors.centerIn: parent
                            text: modelData + "K"
                            color: active ? Theme.fg : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.weight: active ? Font.Medium : Font.Normal
                        }
                        MouseArea {
                            id: presetKelvinMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.System.setNightLightTemp(modelData)
                        }
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
            height: 40
            radius: Theme.radiusControl
            color: powerMouse.containsMouse ? Theme.surfaceHover : Theme.surface
            border.width: 1
            border.color: Theme.hairlineSoft

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                Icon { glyph: "\uf108"; size: 13; tint: Theme.muted }
                Text {
                    Layout.fillWidth: true
                    text: "Power off displays"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
                Icon { glyph: "\uf054"; size: 10; tint: Theme.hairline }
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
            text: "This GPU exposes no gamma control, so night light is a warm screen tint rather than a calibrated colour shift."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            wrapMode: Text.WordWrap
            opacity: 0.9
        }

        Item { Layout.fillHeight: true }
    }
}
