import QtQuick
import ".."

// Nerd Font glyph. Kept separate so every icon uses the same family/metrics.
Text {
    id: root

    property string glyph: ""
    property int size: 15
    property color tint: Theme.fg

    text: glyph
    color: tint
    font.family: Theme.iconFont
    font.pixelSize: size
    font.weight: Font.Normal
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
}
