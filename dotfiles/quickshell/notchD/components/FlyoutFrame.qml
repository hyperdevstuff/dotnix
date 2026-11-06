import QtQuick
import ".."
import QtQuick.Layouts

// Side flyout shell: one full-height panel with a back header, body and
// optional right header actions. Content is supplied by the flyout pages.
Item {
    id: root

    property string title: ""
    property bool showBack: true
    property alias rightContent: rightSlot.data
    default property alias bodyContent: body.data

    signal back()

    implicitWidth: Theme.flyoutW
    implicitHeight: Theme.flyoutH

    Panel {
        anchors.fill: parent
        panelRadius: Theme.radius
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Item {
            Layout.fillWidth: true
            height: Theme.headerH

            RowLayout {
                anchors.fill: parent
                spacing: 6

                Rectangle {
                    width: 26
                    height: 26
                    radius: 8
                    visible: root.showBack
                    color: backMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Icon {
                        anchors.centerIn: parent
                        glyph: "\uf053"
                        size: 11
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
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                RowLayout {
                    id: rightSlot
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
