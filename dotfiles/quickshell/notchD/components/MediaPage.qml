import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Flickable {
    id: root
    property var state: null
    readonly property bool wide: width >= 620
    clip: true
    contentWidth: width
    contentHeight: Math.max(height, layout.implicitHeight)
    boundsBehavior: Flickable.StopAtBounds
    GridLayout {
        id: layout
        width: root.width
        height: Math.max(root.height, implicitHeight)
        columns: root.wide ? 2 : 1
        columnSpacing: 28
        rowSpacing: 20
        Rectangle {
            Layout.fillWidth: !root.wide
            Layout.preferredWidth: root.wide ? 270 : root.width
            Layout.preferredHeight: root.wide ? 292 : 200
            radius: 24
            color: Theme.surface
            Artwork {
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, parent.height - 32)
                height: width
                artUrl: Services.Media.artUrl
                cornerRadius: 18
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Icon {
                    glyph: "\uf001"
                    size: 13
                    tint: Theme.accent
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.Media.hasPlayer ? Services.Media.playerName : "Your music"
                    color: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 12 * Theme.textScale
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
                Text {
                    text: Services.Media.hasPlayer ? (Services.Media.playing ? "Playing" : "Paused") : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                }
            }
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 4
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: Services.Media.hasPlayer ? Services.Media.title || "Untitled track" : "Nothing playing"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 28 * Theme.textScale
                    font.weight: Font.DemiBold
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.Media.hasPlayer ? Services.Media.artist || "Unknown artist" : "Start playback in an app to see it here."
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 15 * Theme.textScale
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: Services.Media.album
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12 * Theme.textScale
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }
            }
            MediaSeekbar {
                Layout.fillWidth: true
                Layout.topMargin: 4
            }
            MediaControls {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
            }
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 4
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Services.Media.players
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: modelData === Services.Media.activePlayer
                        width: Math.min(playerLabel.implicitWidth + 24, layout.width - (root.wide ? 298 : 0))
                        height: 30
                        radius: 15
                        color: selected ? Theme.accentContainer : playerMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        activeFocusOnTab: true
                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.identity
                        Accessible.checked: selected
                        Keys.onReturnPressed: Services.Media.selectPlayer(modelData)
                        Keys.onSpacePressed: Services.Media.selectPlayer(modelData)
                        border.color: activeFocus ? Theme.accent : "transparent"
                        Text {
                            id: playerLabel
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, parent.width - 24)
                            text: parent.modelData.identity
                            color: parent.selected ? Theme.accentContainerInk : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11 * Theme.textScale
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                        }
                        MouseArea {
                            id: playerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.Media.selectPlayer(parent.modelData)
                        }
                    }
                }
            }
        }
    }
}
