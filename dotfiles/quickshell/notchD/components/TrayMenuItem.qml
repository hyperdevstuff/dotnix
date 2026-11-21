import QtQuick
import QtQuick.Controls
import ".."

MenuItem {
    id: control
    property var entry: null
    text: entry ? entry.text : ""
    enabled: entry ? entry.enabled : true
    implicitWidth: Math.max(200, label.implicitWidth + 94)
    implicitHeight: 34
    padding: 0
    background: Rectangle {
        radius: 7
        color: control.down ? Theme.surfacePress : control.highlighted ? Theme.surfaceHover : "transparent"
        border.color: control.activeFocus ? Theme.accent : "transparent"
    }
    contentItem: Item {
        opacity: control.enabled ? 1 : 0.48
        Text {
            x: 10
            width: 18
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: control.entry && control.entry.buttonType !== 0 && control.entry.checkState !== Qt.Unchecked ? (control.entry.buttonType === 2 ? "●" : control.entry.checkState === Qt.PartiallyChecked ? "−" : "✓") : ""
            color: Theme.accent
            font.pixelSize: 13 * Theme.textScale
        }
        Image {
            x: 32
            width: 18
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            source: control.entry ? control.entry.icon : ""
            sourceSize: Qt.size(24, 24)
            fillMode: Image.PreserveAspectFit
        }
        Text {
            id: label
            anchors.left: parent.left
            anchors.leftMargin: 58
            anchors.right: parent.right
            anchors.rightMargin: 26
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: 12 * Theme.textScale
            color: Theme.fg
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: control.subMenu ? "›" : ""
            color: Theme.muted
            font.pixelSize: 18 * Theme.textScale
        }
    }
}
