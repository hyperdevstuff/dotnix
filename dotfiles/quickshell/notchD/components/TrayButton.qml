import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import ".."

Rectangle {
    id: root
    required property var item
    property bool showLabel: false
    readonly property string title: item ? item.tooltipTitle || item.title || item.id || "Background app" : "Background app"
    readonly property bool menuVisible: contextMenu.visible
    signal activated
    implicitWidth: showLabel ? 180 : 32
    implicitHeight: showLabel ? 48 : 32
    radius: showLabel ? 12 : 10
    color: mouse.pressed ? Theme.surfacePress : mouse.containsMouse || activeFocus || menuVisible ? Theme.surfaceHover : "transparent"
    border.color: activeFocus ? Theme.accent : "transparent"
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: "Activate app. Press Menu or Shift+F10 for its menu."
    Accessible.onPressAction: activate()
    function activate() {
        if (!item)
            return;
        if (item.onlyMenu) {
            if (item.hasMenu)
                openMenu();
            return;
        }
        item.activate();
        activated();
    }
    function openMenu() {
        if (!item || !item.hasMenu || !item.menu)
            return;
        if (contextMenu.visible)
            contextMenu.close();
        else
            contextMenu.open();
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
            activate();
        else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier)))
            openMenu();
        else
            return;
        event.accepted = true;
    }
    onVisibleChanged: if (!visible && contextMenu.visible)
        contextMenu.close()
    Image {
        id: appIcon
        x: root.showLabel ? 12 : (parent.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 20
        height: 20
        source: root.item ? root.item.icon : ""
        sourceSize: Qt.size(32, 32)
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
    Icon {
        anchors.centerIn: appIcon
        glyph: "\uf009"
        size: 16
        tint: Theme.muted
        visible: appIcon.status !== Image.Ready
    }
    Text {
        visible: root.showLabel
        x: 44
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - x - 32)
        text: root.title
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12 * Theme.textScale
    }
    Rectangle {
        visible: root.item && root.item.status === Status.NeedsAttention
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 5
        width: 5
        height: 5
        radius: 3
        color: Theme.accent
    }
    Text {
        visible: root.showLabel && root.item && root.item.hasMenu
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "⋮"
        color: Theme.muted
        font.pixelSize: 18 * Theme.textScale
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onClicked: root.openMenu()
        }
    }
    TrayMenu {
        id: contextMenu
        menuHandle: root.item && root.item.hasMenu ? root.item.menu : null
        x: 0
        y: root.height
        onMenuHandleChanged: if (!menuHandle)
            close()
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            root.forceActiveFocus();
            if (event.button === Qt.RightButton)
                root.openMenu();
            else if (event.button === Qt.MiddleButton && root.item)
                root.item.secondaryActivate();
            else
                root.activate();
        }
        onWheel: event => {
            if (!root.item)
                return;
            const horizontal = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y);
            root.item.scroll(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
            event.accepted = true;
        }
    }
    ToolTip {
        id: tooltip
        visible: mouse.containsMouse && !root.showLabel && !contextMenu.visible
        delay: 500
        text: root.title + (root.item && root.item.tooltipDescription ? "\n" + root.item.tooltipDescription : "")
        contentItem: Text {
            text: tooltip.text
            textFormat: Text.PlainText
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
        }
        background: Rectangle {
            radius: 8
            color: Theme.bgElev
            border.color: Theme.hairline
        }
    }
}
