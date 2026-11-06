import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

// Downward media card. This is the only module that expands below the hub.
Item {
    id: root

    property var state: null

    implicitWidth: Theme.mediaW
    implicitHeight: Theme.mediaH

    Panel {
        anchors.fill: parent
        panelRadius: Theme.radius
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 11
        spacing: 11

        // ---------------------------------------------------------- album art
        Rectangle {
            Layout.preferredWidth: 66
            Layout.preferredHeight: 66
            Layout.alignment: Qt.AlignVCenter
            radius: Theme.radiusSmall
            color: Theme.surface
            clip: true
            border.width: 1
            border.color: Theme.hairlineSoft

            Image {
                id: art
                anchors.fill: parent
                source: Services.Media.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }

            Icon {
                anchors.centerIn: parent
                visible: !art.visible
                glyph: Services.Media.playing ? "\uf001" : "\uf04b"
                size: 22
                tint: Theme.muted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Services.Media.playPause()
            }
        }

        // -------------------------------------------------------- track body
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: Services.Media.hasPlayer ? (Services.Media.title || "Nothing playing") : "Nothing playing"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: Services.Media.hasPlayer
                    ? (Services.Media.artist || "Unknown artist")
                    : "Start a player to see it here"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            // ------------------------------------------------------- progress
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 10

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    radius: 2
                    color: Theme.track
                }

                Rectangle {
                    width: Services.Media.length > 0
                        ? Math.max(0, Math.min(parent.width,
                            parent.width * Services.Media.position / Services.Media.length))
                        : 0
                    height: 3
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.timeText(Services.Media.position)
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.timeText(Services.Media.length)
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                }
            }

            Item { Layout.fillHeight: true }
        }

        // --------------------------------------------------------- transport
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Icon {
                glyph: "\uf048"
                size: 11
                tint: Services.Media.canPrev ? Theme.fg : Theme.hairline
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    enabled: Services.Media.canPrev
                    onClicked: Services.Media.previous()
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 10
                color: playMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.width: 1
                border.color: Theme.hairlineSoft

                Icon {
                    anchors.centerIn: parent
                    glyph: Services.Media.playing ? "\uf04c" : "\uf04b"
                    size: 12
                    tint: Theme.fg
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
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
                    enabled: Services.Media.canNext
                    onClicked: Services.Media.next()
                }
            }
        }
    }

    function timeText(seconds) {
        const s = Math.max(0, Math.floor(Number(seconds) || 0));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }
}
