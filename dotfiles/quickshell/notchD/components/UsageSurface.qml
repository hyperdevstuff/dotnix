import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    property var state: null
    property var feed: ({})
    property string status: "Loading usage feed…"
    property real now: Date.now()
    readonly property string path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/notchD/usage.json"
    function refresh() {
        now = Date.now();
        file.reload();
    }
    function dateText(value) {
        const d = new Date(value);
        return isNaN(d.getTime()) ? "" : d.toLocaleString();
    }
    function cardStatus(entry) {
        if (!entry || typeof entry !== "object")
            return "Unavailable";
        if (entry.error)
            return "Error: " + String(entry.error);
        const time = new Date(entry.updatedAt || feed.updatedAt).getTime();
        if (isNaN(time))
            return "Unavailable · missing timestamp";
        if (now - time > 3600000 || time - now > 300000)
            return "Stale · " + dateText(entry.updatedAt || feed.updatedAt);
        return "Updated " + dateText(entry.updatedAt || feed.updatedAt);
    }
    function details(entry) {
        if (!entry || typeof entry !== "object")
            return "No usage data";
        const parts = [];
        for (const key of ["remaining", "used", "limit"]) {
            const v = entry[key];
            if (typeof v === "number" && isFinite(v) && v >= 0)
                parts.push(key.charAt(0).toUpperCase() + key.slice(1) + " " + v + (entry.unit ? " " + String(entry.unit) : ""));
        }
        return parts.length ? parts.join("  ·  ") : "No usage data";
    }
    FileView {
        id: file
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const value = JSON.parse(text());
                if (!value || typeof value !== "object" || Array.isArray(value) || !value.providers || typeof value.providers !== "object" || Array.isArray(value.providers))
                    throw new Error("Invalid feed");
                root.feed = value;
                root.status = "Usage feed";
                root.now = Date.now();
            } catch (e) {
                root.feed = ({});
                root.status = "Usage feed error · invalid JSON or schema";
            }
        }
        onLoadFailed: error => {
            root.feed = ({});
            root.status = error === FileViewError.FileNotFound ? "Usage feed unavailable" : "Usage feed could not be read";
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.now = Date.now()
    }
    Flickable {
        anchors.fill: parent
        activeFocusOnTab: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
                contentY = Math.min(Math.max(0, contentHeight - height), contentY + (event.key === Qt.Key_Down ? 40 : height));
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) {
                contentY = Math.max(0, contentY - (event.key === Qt.Key_Up ? 40 : height));
                event.accepted = true;
            }
        }
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ColumnLayout {
            id: content
            width: parent.width
            spacing: 10
            Text {
                text: "Usage"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
            Text {
                text: root.status
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
            Repeater {
                model: [
                    {
                        name: "Codex",
                        key: "codex"
                    },
                    {
                        name: "Claude",
                        key: "claude"
                    },
                    {
                        name: "OpenCode",
                        key: "opencode"
                    }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property var entry: root.feed.providers ? root.feed.providers[modelData.key] : null
                    Layout.fillWidth: true
                    implicitHeight: card.implicitHeight + 24
                    radius: Theme.radius
                    color: Theme.surface
                    ColumnLayout {
                        id: card
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 5
                        Text {
                            text: modelData.name
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.details(parent.parent.entry)
                            wrapMode: Text.Wrap
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.cardStatus(parent.parent.entry) + (parent.parent.entry && root.dateText(parent.parent.entry.resetAt) ? " · Reset " + root.dateText(parent.parent.entry.resetAt) : "")
                            wrapMode: Text.Wrap
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
