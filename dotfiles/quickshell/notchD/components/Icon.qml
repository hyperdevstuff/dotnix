import QtQuick
import QtQuick.Shapes
import ".."

// Fixed square metrics; Wi-Fi uses a symmetric vector rather than a font glyph.
Item {
    id: root
    property string glyph: ""
    property int size: 15
    property color tint: Theme.fg
    implicitWidth: glyph === "\uf1eb" ? size : Math.max(size, glyphText.implicitWidth)
    implicitHeight: Math.max(size, glyphText.implicitHeight)
    Text {
        id: glyphText
        anchors.centerIn: parent
        visible: root.glyph !== "\uf1eb"
        text: root.glyph
        color: root.tint
        font.family: Theme.iconFont
        font.pixelSize: root.size
        font.weight: Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        renderType: Text.NativeRendering
    }
    Shape {
        visible: root.glyph === "\uf1eb"
        anchors.centerIn: parent
        width: 24
        height: 24
        scale: root.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.tint
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: "M 2 8 Q 12 -0.5 22 8 M 5.5 12 Q 12 6.5 18.5 12 M 9 16 Q 12 13.5 15 16 M 12 20 L 12 20.1"
            }
        }
    }
}
