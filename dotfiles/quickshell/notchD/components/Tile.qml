import QtQuick
import ".."
import QtQuick.Layouts

// Hub tile: icon, label, live value, optional status dot.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string value: ""
    property color statusColor: "transparent"
    property bool showStatus: false
    property bool focused: false
    property bool hovered: false

    signal activated()

    implicitHeight: Theme.tileH
    implicitWidth: 160
    radius: Theme.radiusSmall
    color: root.hovered || root.focused ? Theme.surfaceHover : Theme.surface
    border.width: root.focused ? 1 : 0
    border.color: Theme.fg
    antialiasing: true

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 9

        Rectangle {
            width: 26
            height: 26
            radius: 8
            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
            Icon {
                anchors.centerIn: parent
                glyph: root.icon
                size: 13
                tint: Theme.fg
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                text: root.label
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.letterSpacing: 0.4
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.value
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: root.statusColor
            visible: root.showStatus
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onClicked: root.activated()
    }
}
