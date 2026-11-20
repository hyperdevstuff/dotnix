import QtQuick
import QtQuick.Layouts
import "../services" as Services

RowLayout {
    spacing: 20
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
}
