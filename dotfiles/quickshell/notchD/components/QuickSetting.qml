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
    color: checked ? Theme.accentContainer : Theme.surface
    readonly property color ink: checked ? Theme.accentContainerInk : Theme.fg
    Behavior on radius {
        NumberAnimation {
            duration: Motion.reduceMotion ? 0 : 120
            easing.type: Easing.OutCubic
        }
    }
    Item {
        id: primary
        width: Math.max(0, parent.width - 40)
        height: parent.height
        activeFocusOnTab: true
        Accessible.role: root.toggleable ? Accessible.CheckBox : Accessible.Button
        Accessible.name: root.title + ", " + root.subtitle
        Accessible.checked: root.checked
        Accessible.onPressAction: root.triggered()
        Keys.onReturnPressed: root.triggered()
        Keys.onSpacePressed: root.triggered()
        StateLayer {
            radius: root.radius
            ink: root.ink
            hovered: primaryMouse.containsMouse
            pressed: primaryMouse.pressed
            focused: primary.activeFocus
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
        id: details
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 48
        radius: 12
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.title + " details"
        Accessible.onPressAction: root.detailsRequested()
        color: "transparent"
        Keys.onReturnPressed: root.detailsRequested()
        Keys.onSpacePressed: root.detailsRequested()
        StateLayer {
            radius: details.radius
            ink: root.ink
            hovered: detailMouse.containsMouse
            pressed: detailMouse.pressed
            focused: details.activeFocus
        }
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
