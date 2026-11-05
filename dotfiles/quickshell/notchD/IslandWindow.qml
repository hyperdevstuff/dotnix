import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-width transparent overlay window with an input mask that tracks the
// capsule. Owns a second "dismiss" window used to collapse on outside click.
Item {
    id: root

    required property var screen

    // Geometry of the capsule, updated by the hosted content.
    property real capsuleX: 0
    property real capsuleY: 0
    property real capsuleW: 0
    property real capsuleH: 0
    property bool notchMode: true

    property bool dismissVisible: false
    signal clickedOutside()

    default property Item content

    // Main overlay surface
    PanelWindow {
        id: win
        screen: root.screen
        anchors { top: true; left: true; right: true }
        implicitHeight: 400
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            x: root.capsuleX
            y: root.capsuleY
            width: root.capsuleW
            height: root.capsuleH
        }

        // Host the capsule
        Item {
            id: host
            anchors.fill: parent
        }
    }

    // Dismiss layer: full-screen, mask subtracts the capsule so clicks on the
    // capsule reach the main window; clicks anywhere else collapse.
    PanelWindow {
        id: dismissWin
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        visible: root.dismissVisible
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-dismiss"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            // full screen base
            width: dismissWin.width
            height: dismissWin.height
            Region {
                x: root.capsuleX
                y: root.capsuleY
                width: root.capsuleW
                height: root.capsuleH
                intersection: Intersection.Subtract
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.clickedOutside()
        }
    }

    Component.onCompleted: {
        if (root.content) {
            root.content.parent = host;
        }
    }
}