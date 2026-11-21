import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root
    property string title: ""
    property string subtitle: ""
    property string symbol: "settings"
    property bool checked: false
    property bool toggleable: false
    signal triggered
    signal detailsRequested
    implicitHeight: 68
    radius: primaryMouse.pressed ? 16 : 22
    color: checked ? Theme.accentContainer : primaryMouse.containsMouse || primary.activeFocus ? Theme.surfaceHover : Theme.surface
    readonly property color ink: checked ? Theme.accentContainerInk : Theme.fg
    Behavior on radius {
        NumberAnimation {
            duration: Motion.reduceMotion ? 0 : 120
            easing.type: Easing.OutCubic
        }
    }
    Item {
        id: primary
        width: parent.width - 30
        height: parent.height
        activeFocusOnTab: true
        Accessible.role: root.toggleable ? Accessible.CheckBox : Accessible.Button
        Accessible.name: root.title + ", " + root.subtitle
        Accessible.checked: root.checked
        Keys.onReturnPressed: root.triggered()
        Keys.onSpacePressed: root.triggered()
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 18
            color: "transparent"
            border.color: parent.activeFocus ? Theme.accent : "transparent"
        }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 2
            spacing: 8
            Symbol {
                name: root.symbol
                size: 20
                tint: root.ink
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 3
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: root.ink
                    font.family: Theme.fontFamily
                    font.pixelSize: 12 * Theme.textScale
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: root.checked ? Theme.accentContainerInk : Theme.muted
                    opacity: 0.85
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }
        }
        MouseArea {
            id: primaryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.triggered()
        }
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 48
        radius: 12
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.title + " details"
        color: detailMouse.containsMouse || activeFocus ? Theme.surfacePress : "transparent"
        border.color: activeFocus ? Theme.accent : "transparent"
        Keys.onReturnPressed: root.detailsRequested()
        Keys.onSpacePressed: root.detailsRequested()
        Symbol {
            anchors.centerIn: parent
            name: "keyboard_arrow_right"
            size: 18
            tint: root.ink
        }
        MouseArea {
            id: detailMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailsRequested()
        }
    }
}
