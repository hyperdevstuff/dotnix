import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Rectangle {
    id: root
    property var state: null
    radius: Theme.radius
    color: "transparent"
    clip: true
    property int phase: 0
    Timer {
        interval: 300
        repeat: true
        running: root.visible && Services.Media.playing
        onTriggered: root.phase++
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.width - 24, 180)
            Layout.preferredHeight: width
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.surface
                border.width: 3
                border.color: Theme.accent
            }
            Artwork {
                anchors.fill: parent
                anchors.margins: 7
                artUrl: Services.Media.artUrl
                cornerRadius: width / 2
                placeholderIconSize: 28
            }
        }
        Text {
            Layout.fillWidth: true
            text: Services.Media.hasPlayer ? (Services.Media.title || "Nothing playing") : "Nothing playing"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: Services.Media.hasPlayer ? (Services.Media.artist || "Unknown artist") : "Start a player to see it here"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 3
            radius: 2
            color: Theme.track
            Rectangle {
                height: parent.height
                width: Services.Media.length > 0 ? parent.width * Math.max(0, Math.min(1, Services.Media.position / Services.Media.length)) : 0
                radius: 2
                color: Theme.accent
                Behavior on width {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: root.timeText(Services.Media.position)
                color: Theme.muted
                font.pixelSize: 10
            }
            Item {
                Layout.fillWidth: true
            }
            Text {
                text: root.timeText(Services.Media.length)
                color: Theme.muted
                font.pixelSize: 10
            }
        }
        Item {
            Layout.fillHeight: true
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            MediaTransportButton {
                glyph: "\uf048"
                label: "Previous track"
                enabled: Services.Media.hasPlayer && Services.Media.canPrev
                onClicked: Services.Media.previous()
            }
            MediaTransportButton {
                primary: true
                glyph: Services.Media.playing ? "\uf04c" : "\uf04b"
                label: Services.Media.playing ? "Pause" : "Play"
                enabled: Services.Media.hasPlayer && (Services.Media.playing ? Services.Media.canPause : Services.Media.canPlay)
                onClicked: Services.Media.playPause()
            }
            MediaTransportButton {
                glyph: "\uf051"
                label: "Next track"
                enabled: Services.Media.hasPlayer && Services.Media.canNext
                onClicked: Services.Media.next()
            }
            Row {
                spacing: 2
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 2
                        height: Services.Media.playing ? 4 + ((root.phase + index * 2) % 4) * 2 : 3
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 1
                        color: Theme.muted
                        Behavior on height {
                            NumberAnimation {
                                duration: 250
                            }
                        }
                    }
                }
            }
        }
    }
    function timeText(seconds) {
        const s = Math.max(0, Math.floor(Number(seconds) || 0));
        return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60;
    }
}
