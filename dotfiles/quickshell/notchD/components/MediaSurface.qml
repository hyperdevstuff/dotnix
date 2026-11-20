import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Rectangle {
    id: root
    property var state: null
    radius: Theme.radius
    color: Theme.surface
    clip: true
    property int phase: 0
    Timer { interval: 300; repeat: true; running: root.visible && Services.Media.playing; onTriggered: root.phase++ }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 12; spacing: 6
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(40, Math.min(width, root.height - 170))
            radius: Theme.radiusSmall; color: Theme.track; clip: true
            Image { id: art; anchors.fill: parent; source: Services.Media.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
            Icon { anchors.centerIn: parent; visible: !art.visible; glyph: "\uf001"; size: 28; tint: Theme.muted }
        }
        Text { Layout.fillWidth: true; text: Services.Media.hasPlayer ? (Services.Media.title || "Nothing playing") : "Nothing playing"; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Text { Layout.fillWidth: true; text: Services.Media.hasPlayer ? (Services.Media.artist || "Unknown artist") : "Start a player to see it here"; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 11; elide: Text.ElideRight }
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 3; radius: 2; color: Theme.track
            Rectangle { height: parent.height; width: Services.Media.length > 0 ? parent.width * Math.max(0, Math.min(1, Services.Media.position / Services.Media.length)) : 0; radius: 2; color: Theme.fg; Behavior on width { NumberAnimation { duration: 200 } } }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { text: root.timeText(Services.Media.position); color: Theme.muted; font.pixelSize: 10 }
            Item { Layout.fillWidth: true }
            Text { text: root.timeText(Services.Media.length); color: Theme.muted; font.pixelSize: 10 }
        }
        Item { Layout.fillHeight: true }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter; spacing: 18
            Icon { glyph: "\uf048"; size: 13; tint: Services.Media.canPrev ? Theme.fg : Theme.muted; MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: Services.Media.canPrev; onClicked: Services.Media.previous() } }
            Rectangle { width: 36; height: 36; radius: 18; color: Theme.surfaceHover
                Icon { anchors.centerIn: parent; glyph: Services.Media.playing ? "\uf04c" : "\uf04b"; size: 13; tint: Theme.fg }
                MouseArea { anchors.fill: parent; onClicked: Services.Media.playPause() }
            }
            Icon { glyph: "\uf051"; size: 13; tint: Services.Media.canNext ? Theme.fg : Theme.muted; MouseArea { anchors.fill: parent; anchors.margins: -8; enabled: Services.Media.canNext; onClicked: Services.Media.next() } }
            Row { spacing: 2; Repeater { model: 3; Rectangle { required property int index; width: 2; height: Services.Media.playing ? 4 + ((root.phase + index * 2) % 4) * 2 : 3; anchors.verticalCenter: parent.verticalCenter; radius: 1; color: Theme.muted; Behavior on height { NumberAnimation { duration: 250 } } } } }
        }
    }
    function timeText(seconds) { const s = Math.max(0, Math.floor(Number(seconds) || 0)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + s % 60; }
}
