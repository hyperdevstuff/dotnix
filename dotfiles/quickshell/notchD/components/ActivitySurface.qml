import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Flickable {
    id: root
    property var state: null
    contentWidth: width
    contentHeight: content.implicitHeight
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) contentY = Math.min(Math.max(0, contentHeight - height), contentY + (event.key === Qt.Key_Down ? 40 : height));
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) contentY = Math.max(0, contentY - (event.key === Qt.Key_Up ? 40 : height));
        else return;
        event.accepted = true;
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ColumnLayout {
        id: content
        width: root.width
        spacing: 16
        Text {
            Layout.leftMargin: 46
            Layout.preferredHeight: 36
            text: "Activity & keep awake"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 20 * Theme.textScale
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: awake.implicitHeight + 32
            radius: 24
            color: Services.KeepAwake.active ? Theme.accentContainer : Theme.surface
            ColumnLayout {
                id: awake
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                RowLayout {
                    Symbol {
                        name: "coffee"
                        tint: Services.KeepAwake.active ? Theme.accentContainerInk : Theme.accent
                        size: 24
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Services.KeepAwake.active ? "Keeping awake · " + Services.KeepAwake.remainingText : "Keep the screen awake"
                        color: Services.KeepAwake.active ? Theme.accentContainerInk : Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 15 * Theme.textScale
                        font.weight: Font.DemiBold
                        wrapMode: Text.Wrap
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: "Temporarily pause idle dimming, automatic lock and idle sleep. Manual lock still works."
                    color: Services.KeepAwake.active ? Theme.accentContainerInk : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12 * Theme.textScale
                    wrapMode: Text.Wrap
                }
                RowLayout {
                    Repeater {
                        model: [15, 30, 60]
                        ActionButton {
                            required property int modelData
                            label: modelData + " min"
                            selected: Services.KeepAwake.active && Services.KeepAwake.durationMinutes === modelData
                            onClicked: Services.KeepAwake.start(modelData)
                        }
                    }
                    ActionButton {
                        visible: Services.KeepAwake.active
                        label: "Stop"
                        onClicked: Services.KeepAwake.stop()
                    }
                }
            }
        }
        Text {
            text: "Capture activity"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 15 * Theme.textScale
            font.weight: Font.DemiBold
        }
        Repeater {
            model: [
                {
                    name: "Microphone",
                    symbol: "mic",
                    active: Services.Privacy.microphoneActive,
                    apps: Services.Privacy.microphoneApps
                },
                {
                    name: "Camera",
                    symbol: "videocam",
                    active: Services.Privacy.cameraActive,
                    apps: Services.Privacy.cameraApps
                },
                {
                    name: "Screen sharing",
                    symbol: "screen_share",
                    active: Services.Privacy.screenActive,
                    apps: Services.Privacy.screenApps
                }
            ]
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 56
                radius: 16
                color: Theme.surface
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12
                    Symbol {
                        name: modelData.symbol
                        tint: modelData.active ? Theme.accent : Theme.muted
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12 * Theme.textScale
                    }
                    Text {
                        Layout.maximumWidth: root.width * 0.5
                        text: modelData.active ? (modelData.apps.length ? modelData.apps.join(", ") : "Active") : "Not detected"
                        color: modelData.active ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12 * Theme.textScale
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            text: "Indicators cover active PipeWire capture links and niri screen sharing. Camera access that bypasses PipeWire is not detected."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            wrapMode: Text.Wrap
        }
    }
}
