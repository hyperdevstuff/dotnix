import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services" as Services
import "components" as Components

// Desktop "home" widgets: small stat squares painted on the wallpaper.
//
// This is a bottom-layer surface with an empty input mask, so it never
// intercepts clicks. Right-click on the wallpaper still opens DesktopMenu,
// and normal windows draw above it. The surface is only mapped while the
// always-empty home workspace (position 1, Mod+0) is focused, so the spare
// empty workspace at the bottom stays plain wallpaper.
//
// Toggle with Mod+Alt+H or:
//   quickshell ipc -c notchD call notchD toggleHome
PanelWindow {
    id: root

    // User toggle. Visibility additionally follows the focused workspace.
    property bool enabled: true
    visible: enabled && Services.Compositor.homeFocused
    focusable: false

    anchors { top: true; left: true }
    margins { top: 28; left: 28 }
    implicitWidth: cluster.implicitWidth
    implicitHeight: cluster.implicitHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "notchD-home"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Click-through. The wallpaper right-click catcher lives on this layer too.
    mask: Region {}

    property int cpu: 0
    property string memText: "—"
    property string memTotalText: "—"
    property string uptimeText: "—"

    // One cheap sample every three seconds, and only while the widgets are
    // visible. CPU usage needs two /proc/stat reads; memory and uptime do not.
    Process {
        id: stats
        command: [
            "bash", "-c",
            "read -r _cpu a b c d e f g h rest < /proc/stat; " +
            "t1=$((a+b+c+d+e+f+g+h)); i1=$((d+e)); " +
            "sleep 0.25; " +
            "read -r _cpu a b c d e f g h rest < /proc/stat; " +
            "t2=$((a+b+c+d+e+f+g+h)); i2=$((d+e)); " +
            "cpu=$(awk -v t1=$t1 -v i1=$i1 -v t2=$t2 -v i2=$i2 " +
            "'BEGIN{d=t2-t1; if(d<=0){print 0; exit} printf \"%d\", 100*(d-(i2-i1))/d}'); " +
            "mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%.1f %.1f\", (t-a)/1048576, t/1048576}' /proc/meminfo); " +
            "up=$(awk '{printf \"%d\", $1}' /proc/uptime); " +
            "echo \"$cpu $mem $up\""
        ]
        stdout: SplitParser {
            onRead: (line) => {
                const p = String(line).trim().split(/\s+/);
                if (p.length < 4) return;
                root.cpu = parseInt(p[0], 10) || 0;
                root.memText = p[1];
                root.memTotalText = p[2];
                const secs = parseInt(p[3], 10) || 0;
                const d = Math.floor(secs / 86400);
                const h = Math.floor((secs % 86400) / 3600);
                const m = Math.floor((secs % 3600) / 60);
                root.uptimeText = d > 0 ? d + "d " + h + "h" : h + "h " + m + "m";
            }
        }
    }

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: stats.running = true
    }

    Column {
        id: cluster
        spacing: 12

        Row {
            spacing: 12

            Components.HomeCard {
                title: "cpu"
                value: root.cpu + "%"
                detail: "usage"
            }

            Components.HomeCard {
                title: "memory"
                value: root.memText
                detail: "of " + root.memTotalText + " GB"
            }
        }

        Row {
            spacing: 12

            Components.HomeCard {
                title: "uptime"
                value: root.uptimeText
                detail: "since boot"
            }

            Components.HomeCard {
                title: "battery"
                value: Services.System.batteryPercent + "%"
                detail: Services.System.batteryTimeText
            }
        }
    }
}
