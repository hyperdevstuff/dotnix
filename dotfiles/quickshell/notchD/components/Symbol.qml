import QtQuick
import QtQuick.Shapes
import ".."
import "../icons/material/Paths.js" as Material

Item {
    id: root
    property string name: "info"
    property real size: 20
    property color tint: Theme.fg
    implicitWidth: size
    implicitHeight: size
    Shape {
        y: root.size
        width: 960
        height: 960
        transformOrigin: Item.TopLeft
        scale: root.size / 960
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.tint
            strokeColor: "transparent"
            PathSvg {
                path: Material.paths[root.name] || Material.paths.info || ""
            }
        }
    }
}
