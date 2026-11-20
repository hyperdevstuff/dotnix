// SPDX-License-Identifier: GPL-3.0-only
// Adapted from caelestia-dots; see notification-attribution/README.md.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "components" as Components
import "services" as Services

Item {
    id: root
    required property var screen
    property bool suppressed: false

    PanelWindow {
        id: win
        screen: root.screen
        anchors { top: true; right: true }
        margins { top: 12; right: 12 }
        implicitWidth: Math.max(1, Math.min(360, root.screen.width - 24))
        implicitHeight: Math.max(1, Math.min(list.contentHeight, root.screen.height - 24))
        color: "transparent"
        aboveWindows: true; focusable: false; exclusiveZone: 0
        visible: !root.suppressed && !Services.Notifications.dnd && list.count > 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-notifications"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {
            Region { item: { const revision = list.count + list.contentHeight; return list.itemAtIndex(0) } }
            Region { item: { const revision = list.count + list.contentHeight; return list.itemAtIndex(1) } }
            Region { item: { const revision = list.count + list.contentHeight; return list.itemAtIndex(2) } }
            Region { item: { const revision = list.count + list.contentHeight; return list.itemAtIndex(3) } }
        }
        ListView {
            id: list
            anchors.fill: parent; spacing: 8; clip: true
            model: Services.Notifications.popups
            delegate: Components.NotificationCard {
                required property var modelData
                width: list.width; notification: modelData; popup: true
            }
            add: Transition { NumberAnimation { property: "x"; from: list.width; to: 0; duration: 240; easing.type: Easing.OutCubic } NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
            remove: Transition { NumberAnimation { property: "x"; to: list.width; duration: 180; easing.type: Easing.OutCubic } NumberAnimation { property: "opacity"; to: 0; duration: 160 } }
            displaced: Transition { NumberAnimation { property: "y"; duration: 200; easing.type: Easing.OutCubic } }
        }
    }
}
