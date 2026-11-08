import QtQuick
import Quickshell
import Quickshell.Wayland
import "components" as Components
import "services" as Services

// Notification cards: one layer-shell window in the top-right corner. The
// window is exactly as tall as the stack, so it only takes pointer input over
// the cards themselves.
Item {
    id: root

    required property var screen
    // Hide while the island's side flyout is open: both live on the right and
    // would overlap. Cards that arrive meanwhile stay tracked and appear when
    // the flyout closes.
    property bool suppressed: false

    PanelWindow {
        id: win
        screen: root.screen
        anchors {
            top: true
            right: true
        }
        margins {
            top: 12
            right: 12
        }
        implicitWidth: 360
        implicitHeight: list.contentHeight
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        visible: !root.suppressed && Services.Notifications.count > 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-notifications"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        ListView {
            id: list
            width: parent.width
            height: contentHeight
            spacing: 8
            interactive: false
            clip: false
            model: Services.Notifications.items

            delegate: Components.NotificationCard {
                required property var modelData

                width: list.width
                notification: modelData
                onClosed: Services.Notifications.remove(modelData)
            }

            add: Transition {
                NumberAnimation {
                    properties: "opacity,scale"
                    from: 0
                    to: 1
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            remove: Transition {
                NumberAnimation {
                    properties: "opacity,scale"
                    to: 0
                    duration: 120
                    easing.type: Easing.InCubic
                }
            }

            displaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
