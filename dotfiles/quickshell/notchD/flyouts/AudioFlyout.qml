import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../components"
import "../services" as Services

// Audio detail flyout: output, input, default-device chips and media controls.
FlyoutFrame {
    id: root

    title: "Audio"

    rightContent: Rectangle {
        width: mixerLabel.implicitWidth + 14
        height: 26
        radius: Theme.radiusControl
        color: mixerMouse.containsMouse ? Theme.surfaceHover : "transparent"
        Row {
            id: mixerLabel
            anchors.centerIn: parent
            spacing: 5
            Icon { glyph: "\uf0ad"; size: 9; tint: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
            Text {
                text: "Mixer"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            id: mixerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["pavucontrol"])
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Text {
            Layout.fillWidth: true
            text: "OUTPUT"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            font.letterSpacing: 0.8
        }

        SliderCard {
            Layout.fillWidth: true
            title: "Volume"
            subtitle: Services.System.sinkName
            icon: Services.System.volumeMuted ? "\uf027" : "\uf028"
            value: Services.System.volume
            muted: Services.System.volumeMuted
            onMoved: (v) => Services.System.setVolume(v)
            onCommitted: (v) => Services.System.setVolume(v)
            onMuteToggled: Services.System.toggleMute()
        }

        DeviceChips {
            Layout.fillWidth: true
            devices: Services.System.sinks
            current: Services.System.sink
            onPicked: (node) => Services.System.setDefaultSink(node)
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Text {
            Layout.fillWidth: true
            text: "INPUT"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            font.letterSpacing: 0.8
        }

        SliderCard {
            Layout.fillWidth: true
            title: "Microphone"
            subtitle: Services.System.sourceName
            icon: Services.System.micMuted ? "\uf131" : "\uf130"
            muteIconOn: "\uf130"
            muteIconOff: "\uf131"
            value: Services.System.micVolume
            muted: Services.System.micMuted
            onMoved: (v) => Services.System.setMicVolume(v)
            onCommitted: (v) => Services.System.setMicVolume(v)
            onMuteToggled: Services.System.toggleMicMute()
        }

        DeviceChips {
            Layout.fillWidth: true
            devices: Services.System.sources
            current: Services.System.source
            onPicked: (node) => Services.System.setDefaultSource(node)
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
            visible: Services.Media.hasPlayer
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Services.Media.hasPlayer
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: Services.Media.title || "Nothing playing"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.Media.artist
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    elide: Text.ElideRight
                }
            }

            Icon {
                glyph: "\uf048"
                size: 11
                tint: Services.Media.canPrev ? Theme.fg : Theme.hairline
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Media.previous()
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: Theme.radiusControl
                color: Theme.surface
                Icon {
                    anchors.centerIn: parent
                    glyph: Services.Media.playing ? "\uf04c" : "\uf04b"
                    size: 11
                    tint: Theme.fg
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Media.playPause()
                }
            }

            Icon {
                glyph: "\uf051"
                size: 11
                tint: Services.Media.canNext ? Theme.fg : Theme.hairline
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.Media.next()
                }
            }
        }
    }

    // Reusable horizontal default-device selector.
    component DeviceChips: Flickable {
        id: chips

        property var devices: []
        property var current: null
        signal picked(var node)

        Layout.fillWidth: true
        height: 28
        contentWidth: chipRow.width
        contentHeight: height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.HorizontalFlick

        Row {
            id: chipRow
            spacing: 4
            Repeater {
                model: chips.devices
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: chips.current === modelData
                    width: chipText.implicitWidth + 16
                    height: 26
                    radius: Theme.radiusControl
                    color: selected ? Theme.fg : (chipMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
                    border.width: 1
                    border.color: selected ? Theme.fg : Theme.hairlineSoft
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: Services.System.nodeLabel(modelData)
                        color: selected ? Theme.accentInk : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11 * Theme.textScale
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 150)
                    }
                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: chips.picked(modelData)
                    }
                }
            }
        }
    }
}
