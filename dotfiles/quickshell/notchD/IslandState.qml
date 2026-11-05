import QtQuick
import Quickshell

// State machine for the island. Drives NotchD.qml.
// States: hidden | idle | expanded | peek
Item {
    id: root

    property bool hidden: false
    property bool expanded: false          // pinned by click
    property bool hoverExpanded: false      // transient by hover
    property bool pointerInside: false
    property string surface: "idle"        // idle | media | osd | workspace
    property string peekSurface: ""        // non-empty while peeking
    property int peekTimeoutMs: 2500

    readonly property bool shown: !hidden
    readonly property bool active: expanded || hoverExpanded || peekSurface !== ""

    // Priority: osd > media > workspace > idle
    function peek(surf, ms) {
        if (expanded) return;               // never clobber a pin
        peekSurface = surf;
        surface = surf;
        peekTimer.interval = ms > 0 ? ms : peekTimeoutMs;
        peekTimer.restart();
    }

    function collapse() {
        expanded = false;
        hoverExpanded = false;
        peekSurface = "";
        surface = "idle";
        peekTimer.stop();
    }

    function toggleExpanded() {
        if (expanded) collapse();
        else { expanded = true; hoverExpanded = false; peekSurface = ""; }
    }

    Timer {
        id: peekTimer
        onTriggered: {
            root.peekSurface = "";
            root.surface = "idle";
        }
    }
}