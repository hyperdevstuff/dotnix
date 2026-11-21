// SPDX-License-Identifier: GPL-3.0-only
// Caelestia BatteryTank fill/reveal pattern; see performance-attribution/README.md.
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ".."
import "../services" as Services

ClippingRectangle {
    id: root
    radius: 20
    color: Theme.surface
    implicitWidth: 128
    implicitHeight: 336
    Contents {
        id: base
        anchors.fill: parent
        anchors.margins: 14
        ink: Theme.fg
        muted: Theme.muted
    }
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * (Services.System.batteryReady ? Services.System.batteryPercent / 100 : 0)
        color: Theme.accentContainer
        clip: true
        Contents {
            x: 14
            y: parent.height - root.height + 14
            width: root.width - 28
            height: root.height - 28
            ink: Theme.accentContainerInk
            muted: Theme.accentContainerInk
        }
    }
    component Contents: ColumnLayout {
        required property color ink
        required property color muted
        spacing: 8
        Icon {
            glyph: Services.System.batteryIcon
            size: 22
            tint: parent.ink
        }
        Text {
            text: "Battery"
            color: parent.ink
            font.family: Theme.fontFamily
            font.pixelSize: 13 * Theme.textScale
            font.weight: Font.DemiBold
        }
        Item {
            Layout.fillHeight: true
        }
        Text {
            Layout.fillWidth: true
            text: Services.System.batteryReady ? Services.System.batteryPercent + "%" : "AC"
            color: parent.ink
            font.family: Theme.fontFamily
            font.pixelSize: 29 * Theme.textScale
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            text: Services.System.batteryStateText
            color: parent.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            wrapMode: Text.Wrap
        }
        Text {
            Layout.fillWidth: true
            text: Services.System.batteryTimeText !== Services.System.batteryStateText ? Services.System.batteryTimeText : Services.System.batteryWatts > 0 ? Services.System.batteryWatts.toFixed(1) + " W" : ""
            visible: text.length > 0
            color: parent.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            wrapMode: Text.Wrap
        }
    }
}
