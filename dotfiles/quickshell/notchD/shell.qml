import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

ShellRoot {
    id: shell

    PersistentProperties {
        id: persisted
        reloadableId: "notchD-settings"
        property string style: "pill"   // pill | notch
        property bool hidden: false
    }

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    IslandState {
        id: islandState
        hidden: persisted.hidden
        onHiddenChanged: persisted.hidden = hidden
    }

    // Right-click on the empty desktop: wallpaper actions.
    DesktopMenu {
        id: desktopMenu
        screen: shell.primaryScreen
    }

    // Overlay window (full width, fixed height)
    PanelWindow {
        id: win
        screen: shell.primaryScreen
        anchors { top: true; left: true; right: true }
        implicitHeight: 400
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        visible: !islandState.hidden
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            x: notch.x
            y: notch.y
            width: notch.width
            height: notch.height
        }

        NotchD {
            id: notch
            state: islandState
            notchMode: persisted.style === "notch"
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Dismiss layer
    PanelWindow {
        id: dismissWin
        screen: shell.primaryScreen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        aboveWindows: true
        focusable: true
        exclusiveZone: 0
        visible: islandState.active
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-dismiss"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            width: dismissWin.width
            height: dismissWin.height
            Region {
                x: notch.x
                y: notch.y
                width: notch.width
                height: notch.height
                intersection: Intersection.Subtract
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: islandState.collapse()
        }

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: islandState.collapse()
        }
    }

    IpcHandler {
        target: "notchD"
        function toggle() { islandState.hidden = !islandState.hidden; }
        function hide()   { islandState.hidden = true; }
        function show()   { islandState.hidden = false; }
        function expand() { islandState.expanded = true; }
        function collapse() { islandState.collapse(); }
        function peek(s: string) { islandState.peek(s, 0); }
        function showVolume() { islandState.peek("osd", 2000); }
        function showBrightness() { islandState.peek("osd", 2000); }
        function toggleStyle() {
            persisted.style = (persisted.style === "notch") ? "pill" : "notch";
        }
        function setStyle(s: string) {
            if (s === "pill" || s === "notch") persisted.style = s;
        }
        function openDesktopMenu() { desktopMenu.menuOpen = true; }
        function closeDesktopMenu() { desktopMenu.menuOpen = false; }
        function status(): string {
            return JSON.stringify({
                style: persisted.style,
                hidden: islandState.hidden,
                expanded: islandState.expanded,
                surface: islandState.surface,
                desktopMenu: desktopMenu.menuOpen
            });
        }
    }
}