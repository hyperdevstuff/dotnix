import QtQuick
import ".."
import QtQuick.Layouts

// Side flyout shell. It docks flush to the right edge of the hub: the inner
// corners are square so the hub and flyout read as one surface, while the
// outer corners keep the card radius. Content is supplied by the flyout pages.
Item {
    id: root

    property string title: ""
    property bool showBack: false
    property bool showPanel: true
    property alias rightContent: rightSlot.data
    default property alias bodyContent: body.data

    signal back

    implicitWidth: Theme.flyoutW
    implicitHeight: Theme.flyoutH

    Panel {
        visible: root.showPanel
        anchors.fill: parent
        panelRadius: Theme.radius
        cornerTopLeft: 0
        cornerBottomLeft: 0
        cornerTopRight: Theme.notchMode ? 0 : Theme.radius
        cornerBottomRight: Theme.radius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: 10

        Item {
            Layout.fillWidth: true
            height: Theme.headerH

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    width: 28
                    height: 28
                    radius: Theme.radiusControl
                    visible: root.showBack
                    color: backMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        glyph: "\uf053"
                        size: 12
                        tint: Theme.fg
                    }
                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.back()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                RowLayout {
                    id: rightSlot
                    spacing: 8
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
