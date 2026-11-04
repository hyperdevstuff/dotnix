import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "themes.js" as Theme

Item {
    id: root

    // Set by the shell: machine-readable output name, e.g. "eDP-1".
    property string outputName: ""
    property string themeName: "vercel"

    signal themeChangeRequested(string themeName)

    readonly property var theme: Theme.resolve(root.themeName)
    readonly property bool effectiveExpanded: !root.hidden && (root.expanded || root.workspaceHold)

    readonly property int targetWidth: root.hidden ? 112 : (root.effectiveExpanded ? 438 : 112)
    readonly property int targetHeight: root.hidden ? 6 : (root.effectiveExpanded ? 212 : 38)

    property bool expanded: false
    property bool hidden: false
    property bool workspaceHold: false

    property var workspaces: []
    property var windowMap: ({})
    property int currentWorkspaceId: 0
    property int currentWorkspaceIdx: 0
    property bool workspaceKnown: false
    property int batteryPercent: -1
    property int volumePercent: -1

    readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string batteryText: root.batteryPercent >= 0 ? root.batteryPercent + "%" : "--"
    readonly property string volumeText: root.volumePercent >= 0 ? root.volumePercent + "%" : "--"

    clip: true

    // Click expands/collapses the panel; `toggle()` is a total hide/show.
    function toggleExpand() {
        root.expanded = !root.expanded;
        root.workspaceHold = false;
    }

    // toggle() is a total hide/show, not an expand/collapse.
    function toggle() {
        if (root.hidden) {
            root.hidden = false;
        } else {
            root.hidden = true;
            root.expanded = false;
            root.workspaceHold = false;
        }
    }

    function expand() {
        root.hidden = false;
        root.expanded = true;
        root.workspaceHold = false;
    }

    function collapse() {
        root.expanded = false;
        root.workspaceHold = false;
    }

    function hide() {
        root.hidden = true;
        root.expanded = false;
        root.workspaceHold = false;
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

    function triggerWorkspaceExpansion() {
        if (root.hidden)
            return;

        root.workspaceHold = true;
        workspaceTimer.restart();
    }

    function workspaceOutput(workspace) {
        return workspace && workspace.output ? workspace.output : "";
    }

    function workspaceMatchesOutput(workspace) {
        if (!workspace)
            return false;
        if (!root.outputName)
            return true;
        return workspace.output === root.outputName;
    }

    function setWorkspaces(list) {
        var items = Array.isArray(list) ? list.slice(0) : [];
        items = items.filter(workspaceMatchesOutput);
        items.sort(function (a, b) {
            return (a.idx || 0) - (b.idx || 0);
        });

        root.workspaces = items;
        root.workspaceKnown = true;
        updateWorkspaceDerived();
    }

    function updateWorkspaceDerived() {
        var counts = {};
        for (var key in root.windowMap) {
            var window = root.windowMap[key];
            if (!window)
                continue;
            var workspaceId = window.workspace_id;
            if (workspaceId === null || workspaceId === undefined)
                continue;
            counts[workspaceId] = (counts[workspaceId] || 0) + 1;
        }

        var enriched = root.workspaces.map(function (workspace) {
            var item = {};
            for (var key in workspace)
                item[key] = workspace[key];
            item.occupied = (counts[workspace.id] || 0) > 0
                || (workspace.active_window_id !== null && workspace.active_window_id !== undefined);
            return item;
        });

        var current = null;
        for (var i = 0; i < enriched.length; ++i) {
            if (enriched[i].is_focused) {
                current = enriched[i];
                break;
            }
        }

        if (!current) {
            for (var j = 0; j < enriched.length; ++j) {
                if (enriched[j].is_active) {
                    current = enriched[j];
                    break;
                }
            }
        }

        root.workspaces = enriched;
        root.currentWorkspaceId = current ? current.id : 0;
        root.currentWorkspaceIdx = current ? (current.idx || 0) : 0;
    }

    function updateWindowMap(windows) {
        var next = {};
        var list = Array.isArray(windows) ? windows : [];
        for (var i = 0; i < list.length; ++i) {
            var window = list[i];
            if (!window || window.id === undefined || window.id === null)
                continue;
            next[window.id] = window;
        }

        root.windowMap = next;
        updateWorkspaceDerived();
    }

    function updateWindow(window) {
        if (!window || window.id === undefined || window.id === null)
            return;

        var next = {};
        for (var key in root.windowMap)
            next[key] = root.windowMap[key];

        next[window.id] = window;
        root.windowMap = next;
        updateWorkspaceDerived();
    }

    function removeWindow(id) {
        var next = {};
        for (var key in root.windowMap) {
            if (String(key) !== String(id))
                next[key] = root.windowMap[key];
        }

        root.windowMap = next;
        updateWorkspaceDerived();
    }

    function setWorkspaceActive(id, focused) {
        var target = null;
        var targetOutput = "";

        for (var i = 0; i < root.workspaces.length; ++i) {
            if (root.workspaces[i].id === id) {
                target = root.workspaces[i];
                targetOutput = workspaceOutput(target);
                break;
            }
        }

        if (target === null)
            return;

        root.workspaces = root.workspaces.map(function (workspace) {
            var item = {};
            for (var key in workspace)
                item[key] = workspace[key];

            var sameOutput = workspaceOutput(item) === targetOutput;
            if (sameOutput) {
                item.is_active = item.id === id;
                if (focused)
                    item.is_focused = item.id === id;
            }
            return item;
        });

        updateWorkspaceDerived();

        if (focused)
            root.triggerWorkspaceExpansion();
    }

    function setWorkspaceActiveWindow(workspaceId, activeWindowId) {
        root.workspaces = root.workspaces.map(function (workspace) {
            if (workspace.id !== workspaceId)
                return workspace;

            var item = {};
            for (var key in workspace)
                item[key] = workspace[key];
            item.active_window_id = activeWindowId;
            return item;
        });

        updateWorkspaceDerived();
    }

    function parseNiriLine(line) {
        var trimmed = String(line || "").trim();
        if (!trimmed)
            return;

        try {
            var event = JSON.parse(trimmed);

            if (event.WorkspacesChanged) {
                root.setWorkspaces(event.WorkspacesChanged.workspaces || []);
                return;
            }

            if (event.WorkspaceActivated) {
                var activated = event.WorkspaceActivated;
                root.setWorkspaceActive(activated.id, activated.focused === true);
                return;
            }

            if (event.WorkspaceActiveWindowChanged) {
                var activeWindow = event.WorkspaceActiveWindowChanged;
                root.setWorkspaceActiveWindow(activeWindow.workspace_id, activeWindow.active_window_id ?? null);
                return;
            }

            if (event.WindowsChanged) {
                root.updateWindowMap(event.WindowsChanged.windows || []);
                return;
            }

            if (event.WindowOpenedOrChanged && event.WindowOpenedOrChanged.window) {
                root.updateWindow(event.WindowOpenedOrChanged.window);
                return;
            }

            if (event.WindowClosed && event.WindowClosed.id !== undefined) {
                root.removeWindow(event.WindowClosed.id);
            }
        } catch (error) {
            console.warn("notchD: failed to parse niri event:", error);
        }
    }

    function parseBatteryLine(line) {
        var value = parseInt(String(line || "").trim(), 10);
        if (!isNaN(value))
            root.batteryPercent = Math.max(0, Math.min(100, value));
    }

    function parseVolumeLine(line) {
        var text = String(line || "");
        var match = text.match(/Volume:\s*([0-9]+(?:\.[0-9]+)?)/);
        if (!match)
            return;

        root.volumePercent = Math.round(parseFloat(match[1]) * 100);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        id: workspaceTimer
        interval: 1800
        repeat: false
        onTriggered: root.workspaceHold = false
    }

    Process {
        id: niriEvents
        running: true
        command: ["niri", "msg", "--json", "event-stream"]

        stdout: SplitParser {
            onRead: function(line) {
                root.parseNiriLine(line);
            }
        }

        stderr: SplitParser {
            onRead: function(line) {
                if (String(line || "").trim())
                    console.warn("notchD: niri stderr:", line);
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("notchD: niri event-stream exited with code", exitCode);
        }
    }

    Process {
        id: niriWorkspaceSeed
        running: true
        command: ["niri", "msg", "--json", "workspaces"]

        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = String(line || "").trim();
                if (!trimmed)
                    return;

                try {
                    var parsed = JSON.parse(trimmed);
                    root.setWorkspaces(parsed);
                } catch (error) {
                    console.warn("notchD: failed to parse niri workspaces seed:", error);
                }
            }
        }
    }

    Process {
        id: niriWindowSeed
        running: true
        command: ["niri", "msg", "--json", "windows"]

        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = String(line || "").trim();
                if (!trimmed)
                    return;

                try {
                    var parsed = JSON.parse(trimmed);
                    root.updateWindowMap(parsed);
                } catch (error) {
                    console.warn("notchD: failed to parse niri windows seed:", error);
                }
            }
        }
    }

    Process {
        id: niriOutputSeed
        running: true
        command: ["niri", "msg", "--json", "outputs"]

        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = String(line || "").trim();
                if (trimmed)
                    console.log("notchD: niri outputs seed received", trimmed.length, "bytes");
            }
        }
    }

    Process {
        id: batteryPoll
        running: true
        command: [
            "/bin/sh",
            "-c",
            "while true; do " +
                "for f in /sys/class/power_supply/BAT*; do " +
                    "if [ -r \"$f/capacity\" ]; then " +
                        "cat \"$f/capacity\"; " +
                        "break; " +
                    "fi; " +
                "done; " +
                "sleep 30; " +
            "done"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                root.parseBatteryLine(line);
            }
        }
    }

    Process {
        id: volumePoll
        running: true
        command: [
            "/bin/sh",
            "-c",
            "while true; do " +
                "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true; " +
                "sleep 10; " +
            "done"
        ]

        stdout: SplitParser {
            onRead: function(line) {
                root.parseVolumeLine(line);
            }
        }
    }

    Rectangle {
        id: shadow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.hidden ? 1 : 8
        width: pill.width
        height: pill.height
        radius: pill.radius
        color: root.theme.shadow
        opacity: root.hidden ? 0.0 : 0.36

        Behavior on width {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 240
            }
        }
    }

    Rectangle {
        id: pill

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.targetWidth
        height: root.targetHeight
        radius: root.hidden ? 2 : (root.effectiveExpanded ? 26 : height / 2)
        color: root.theme.bg
        border.width: root.hidden ? 0 : 1
        border.color: root.theme.hairline

        Behavior on width {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: 340
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 260
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 260
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: true
            hoverEnabled: true
            onClicked: root.toggleExpand()
        }

        Item {
            id: collapsedLayer
            anchors.fill: parent
            opacity: root.hidden || root.effectiveExpanded ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.timeText
                color: root.theme.fg
                font.family: "Roboto"
                font.pixelSize: 17
                font.weight: Font.DemiBold
                renderType: Text.QtRendering
            }
        }

        Item {
            id: expandedLayer
            anchors.fill: parent
            opacity: root.effectiveExpanded ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        text: root.timeText
                        color: root.theme.fg
                        font.family: "Roboto"
                        font.pixelSize: 46
                        font.weight: Font.DemiBold
                        lineHeight: 0.95
                        renderType: Text.QtRendering
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignTop

                        Text {
                            text: "BAT " + root.batteryText
                            color: root.batteryPercent >= 0 && root.batteryPercent <= 20
                                ? root.theme.red
                                : root.theme.fg
                            font.family: "Roboto"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                            renderType: Text.QtRendering
                        }

                        Text {
                            text: "VOL " + root.volumeText
                            color: root.theme.muted
                            font.family: "Roboto"
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                            renderType: Text.QtRendering
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.theme.hairline
                    opacity: 0.9
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "WORKSPACE"
                            color: root.theme.muted
                            font.family: "Roboto"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.4
                            renderType: Text.QtRendering
                        }

                        Text {
                            text: root.currentWorkspaceIdx > 0 ? String(root.currentWorkspaceIdx) : "--"
                            color: root.theme.accent
                            font.family: "Roboto"
                            font.pixelSize: 38
                            font.weight: Font.DemiBold
                            lineHeight: 0.9
                            renderType: Text.QtRendering
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Workspaces {
                        theme: root.theme
                        workspaces: root.workspaces
                        currentId: root.currentWorkspaceId
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 28
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "THEME"
                        color: root.theme.muted
                        font.family: "Roboto"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                        renderType: Text.QtRendering
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: Theme.names()

                        delegate: Rectangle {
                            id: dot

                            required property string modelData

                            readonly property bool selected: root.themeName === modelData
                            readonly property var dotTheme: Theme.resolve(modelData)

                            width: 14
                            height: 14
                            radius: 7
                            color: dotTheme.elevated
                            border.width: selected ? 2 : 1
                            border.color: selected ? dotTheme.accent : dotTheme.border

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 180
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 180
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                onClicked: root.setTheme(dot.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
