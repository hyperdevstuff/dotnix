import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    clip: true
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 76
            Layout.maximumHeight: 186
            Layout.preferredHeight: 180
            Artwork {
                anchors.centerIn: parent
                width: Math.max(1, Math.min(parent.width - 24, parent.height))
                height: width
                artUrl: Services.Media.artUrl
                cornerRadius: 22
                placeholderIconSize: 32
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: Services.Media.hasPlayer ? (Services.Media.title || "Untitled track") : "Nothing playing"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: Services.Media.hasPlayer ? (Services.Media.artist || Services.Media.playerName) : "Open a music player to start listening"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }
        MediaSeekbar {
            Layout.fillWidth: true
        }
        MediaControls {
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
