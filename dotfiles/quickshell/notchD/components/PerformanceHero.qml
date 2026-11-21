// SPDX-License-Identifier: GPL-3.0-only
// Caelestia-inspired resource card; see performance-attribution/README.md.
import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property string glyph: ""
    property real value: -1
    property real temperature: -1
    property string status: "Load"
    property var history: []
    property color accent: Theme.accent
    implicitHeight: 174
    radius: 20
    color: Theme.surface
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 8
                RowLayout {
                    Icon {
                        glyph: root.glyph
                        size: 17
                        tint: root.accent
                    }
                    Text {
                        text: root.title
                        color: root.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 15 * Theme.textScale
                        font.weight: Font.DemiBold
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    textFormat: Text.PlainText
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    elide: Text.ElideRight
                }
                RowLayout {
                    Icon {
                        glyph: "\uf2c9"
                        size: 12
                        tint: root.temperature > 90 ? Theme.danger : Theme.muted
                    }
                    Text {
                        text: root.temperature >= 0 ? Math.round(root.temperature) + "°C" : "No sensor"
                        color: root.temperature > 90 ? Theme.danger : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12 * Theme.textScale
                    }
                }
            }
            UsageGauge {
                value: root.value
                caption: root.status
                accent: root.accent
            }
        }
        Sparkline {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 24
            values: root.history
            accent: root.accent
        }
    }
}
