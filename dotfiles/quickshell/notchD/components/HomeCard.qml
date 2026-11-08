import QtQuick
import QtQuick.Layouts
import ".."

// Small square stat tile for the desktop home widgets.
// Values are plain properties so the caller can bind them to live services
// without rebuilding a model.
Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string detail: ""

    implicitWidth: 128
    implicitHeight: 128
    radius: Theme.radiusControl
    color: Theme.surface
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 2

        Text {
            text: root.title
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.6
        }

        Item { Layout.fillHeight: true }

        Text {
            text: root.value
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.Medium
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.detail
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
    }
}
