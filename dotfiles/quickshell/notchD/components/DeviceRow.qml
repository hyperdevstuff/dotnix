import QtQuick
import ".."
import QtQuick.Layouts

// One line item for Wi-Fi networks, Bluetooth devices and audio devices.
// The row body activates; an optional trailing action is separate.
Item {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool busy: false
    property bool danger: false
    property bool actionVisible: false
    property string actionText: ""
    property string actionGlyph: ""
    property bool actionDanger: false
    property color iconTint: Theme.fg

    signal activated()
    signal actionClicked()

    implicitHeight: Theme.rowH
    implicitWidth: 250

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: rowMouse.containsMouse && !root.busy ? Theme.surfaceHover : "transparent"
        Behavior on color { ColorAnimation { duration: 110 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 6
        spacing: 9

        Item {
            width: 24
            height: 24
            Layout.alignment: Qt.AlignVCenter

            Icon {
                anchors.centerIn: parent
                visible: !root.busy
                glyph: root.icon
                size: 14
                tint: root.danger ? Theme.danger : root.iconTint
            }

            Icon {
                id: spinner
                anchors.centerIn: parent
                visible: root.busy
                glyph: "\uf110"
                size: 13
                tint: Theme.muted
                RotationAnimator on rotation {
                    running: root.busy
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 900
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                visible: root.subtitle.length > 0
            }
        }

        Icon {
            visible: root.selected && !root.actionVisible && !root.busy
            glyph: "\uf00c"
            size: 12
            tint: Theme.fg
        }

        Rectangle {
            visible: root.actionVisible
            width: actionLabel.implicitWidth + 14
            height: 24
            radius: 7
            color: actionMouse.containsMouse ? Theme.surfaceHover : "transparent"

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: root.actionGlyph.length > 0 ? root.actionGlyph : root.actionText
                color: root.actionDanger ? Theme.danger : Theme.muted
                font.family: root.actionGlyph.length > 0 ? Theme.iconFont : Theme.fontFamily
                font.pixelSize: root.actionGlyph.length > 0 ? 11 : 10
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        anchors.rightMargin: root.actionVisible ? 64 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
