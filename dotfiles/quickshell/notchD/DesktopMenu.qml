import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Right-click menu for the empty desktop.
//
// A transparent bottom-layer surface catches right-clicks over the wallpaper.
// Windows and other layer surfaces stay above it, so right-clicking a window
// behaves normally. While the menu is open a full-screen overlay (with the
// menu card punched out of its input mask) dismisses it on any click.
Item {
    id: root

    required property var screen

    property bool menuOpen: false
    property bool favoriteCurrent: false
    property real anchorX: 0
    property real anchorY: 0

    readonly property int cardWidth: 240
    readonly property int rowHeight: 36
    readonly property int separatorGap: 9

    readonly property var entries: [
        { label: "Random wallpaper",  cmd: ["wp", "random"] },
        { label: "Gruvbox",           cmd: ["wp", "gruvbox"] },
        { label: "Black & white",     cmd: ["wp", "bw"] },
        { label: "Manga",             cmd: ["wp", "manga"] },
        { label: "Random favorite",   cmd: ["wp", "fav"] },
        { label: root.favoriteCurrent ? "★ Unfavorite current" : "☆ Favorite current",
          cmd: ["wp", "fav", "toggle"], separatorBefore: true },
        { label: "Choose wallpaper…", cmd: ["wp-pick"], separatorBefore: true },
        { label: "Reload theme",      cmd: ["wp", "refresh"] },
        { label: "Light theme",       cmd: ["wp", "theme", "light"], separatorBefore: true },
        { label: "Dark theme",        cmd: ["wp", "theme", "dark"] },
        { label: "Auto theme",        cmd: ["wp", "theme", "auto"] }
    ]

    readonly property int menuW: cardWidth
    readonly property int menuH: {
        let h = 12;
        for (let i = 0; i < entries.length; ++i)
            h += rowHeight + (entries[i].separatorBefore ? separatorGap : 0);
        return h;
    }
    readonly property real menuX: Math.max(8, Math.min(anchorX, (screen ? screen.width : 1920) - menuW - 8))
    readonly property real menuY: Math.max(8, Math.min(anchorY, (screen ? screen.height : 1080) - menuH - 8))

    // Refresh the ★ state whenever the menu opens.
    Process {
        id: favCheck
        command: ["bash", "-c", "p=$(awww query 2>/dev/null | head -1 | sed 's/.*: //'); f=\"${XDG_CONFIG_HOME:-$HOME/.config}/wallpapers/favorites\"; [ -n \"$p\" ] && grep -qxF -- \"$p\" \"$f\" 2>/dev/null && echo yes || echo no"]
        stdout: SplitParser {
            onRead: (line) => root.favoriteCurrent = String(line).trim() === "yes"
        }
    }

    onMenuOpenChanged: {
        if (menuOpen)
            favCheck.running = true;
    }

    function activate(cmd) {
        menuOpen = false;
        Quickshell.execDetached(cmd);
    }

    function close() {
        menuOpen = false;
    }

    // Click catcher over the wallpaper.
    PanelWindow {
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        focusable: false
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "notchD-desktop"

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onPressed: (mouse) => {
                root.anchorX = mouse.x;
                root.anchorY = mouse.y;
                root.menuOpen = true;
            }
        }
    }

    // Dismiss layer: everything except the card closes the menu.
    PanelWindow {
        id: dismissWin
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        focusable: false
        exclusiveZone: 0
        visible: root.menuOpen
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-menu-dismiss"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            width: dismissWin.width
            height: dismissWin.height
            Region {
                x: root.menuX
                y: root.menuY
                width: root.menuW
                height: root.menuH
                intersection: Intersection.Subtract
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // The menu itself.
    PanelWindow {
        id: menuWin
        screen: root.screen
        visible: root.menuOpen
        color: "transparent"
        focusable: true
        exclusiveZone: 0
        anchors { top: true; left: true }
        margins { top: root.menuY; left: root.menuX }
        implicitWidth: root.menuW
        implicitHeight: root.menuH
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-menu"
        WlrLayershell.keyboardFocus: root.menuOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.bgElev
            border.width: 1
            border.color: Theme.hairline
            focus: root.menuOpen
            Keys.onEscapePressed: root.close()

            Column {
                id: column
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 }
                spacing: 0

                Repeater {
                    model: root.entries

                    delegate: Item {
                        id: slot
                        required property var modelData
                        width: column.width
                        height: root.rowHeight + (modelData.separatorBefore ? root.separatorGap : 0)

                        Rectangle {
                            visible: slot.modelData.separatorBefore === true
                            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
                            height: 1
                            color: Theme.hairline
                        }

                        Rectangle {
                            id: row
                            anchors {
                                top: parent.top
                                topMargin: slot.modelData.separatorBefore ? root.separatorGap : 0
                                left: parent.left
                                right: parent.right
                            }
                            height: root.rowHeight
                            radius: Theme.radiusControl
                            color: hover.hovered ? Theme.hairline : "transparent"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: slot.modelData.label
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }

                            HoverHandler {
                                id: hover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.activate(slot.modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
