import QtQuick
import Quickshell
import "themes.js" as Theme

Item {
    id: root

    // Minimal Dynamic Island-style pill: only the time.
    property string themeName: "vercel"
    property bool hidden: false

    signal themeChangeRequested(string themeName)

    readonly property var theme: Theme.resolve(root.themeName)

    // Small pill: fit "HH:mm" plus a bit of breathing room.
    readonly property int targetWidth: 76
    readonly property int targetHeight: 30

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: pill

        anchors.top: parent.top
        width: root.targetWidth
        height: root.targetHeight
        radius: height / 2
        color: root.theme.bg
        border.width: 1
        border.color: root.theme.hairline

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: root.theme.fg
            font.family: "Roboto"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            renderType: Text.QtRendering
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggle()
        }
    }

    function toggle() {
        root.hidden = !root.hidden;
    }

    function hide() {
        root.hidden = true;
    }

    function show() {
        root.hidden = false;
    }

    function setTheme(name) {
        var normalized = String(name || "").toLowerCase();
        if (!Theme.has(normalized))
            return false;

        root.themeName = normalized;
        root.themeChangeRequested(normalized);
        return true;
    }

    function cycleTheme() {
        var names = Theme.names();
        var index = names.indexOf(root.themeName);
        if (index < 0)
            index = 0;
        root.setTheme(names[(index + 1) % names.length]);
    }
}
