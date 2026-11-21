// SPDX-License-Identifier: GPL-3.0-only
// Launcher flow adapted from Caelestia Shell; see ATTRIBUTION.md.
import QtQuick
import QtQuick.Controls
import Quickshell
import ".."

FocusScope {
    id: root
    property var state: null
    property string initialQuery: ""
    readonly property bool searchFocused: search.activeFocus
    function focusSearch() {
        search.forceActiveFocus();
    }
    onVisibleChanged: if (visible)
        Qt.callLater(focusSearch)
    signal actionRequested(string action, string value)
    signal closeRequested

    property int selectedIndex: 0
    property var results: []
    readonly property var actions: [
        {name: "Screenshot", detail: "Select an area, annotate, copy or save", key: "screenshot"},
        {name: "Appearance", detail: "Clock, text, motion and surface settings", key: "appearance"},
        {name: "Keep awake", detail: "Capture indicators and timed keep-awake", key: "activity"},
        {
            name: "Calendar",
            detail: "Open the clock and month calendar",
            key: "calendar"
        },
        {
            name: "Background apps",
            detail: "Show system tray icons",
            key: "tray"
        },
        {
            name: "Scheme",
            detail: "Choose a palette source",
            key: "scheme",
            nested: true
        },
        {
            name: "Wallpaper",
            detail: "Choose a wallpaper",
            key: "wallpaper"
        },
        {
            name: "Variant",
            detail: "Choose a Material color variant",
            key: "variant",
            nested: true
        },
        {
            name: "Transparency",
            detail: "Choose panel opacity",
            key: "transparency",
            nested: true
        },
        {
            name: "Mode",
            detail: "Light, dark, or automatic",
            key: "theme",
            nested: true
        },
        {
            name: "Lock",
            detail: "Lock the session",
            key: "lock"
        },
        {
            name: "Sleep",
            detail: "Suspend the session",
            key: "sleep"
        }
    ]
    readonly property var variants: ["content", "expressive", "fidelity", "fruit-salad", "monochrome", "neutral", "rainbow", "tonal-spot", "vibrant", "smart"]

    function context() {
        const match = search.text.match(/^>\s*(scheme|variant|transparency|mode|theme)\s+([\s\S]*)$/i);
        return match ? {
            key: match[1].toLowerCase() === "mode" ? "theme" : match[1].toLowerCase(),
            query: match[2]
        } : null;
    }
    function rank(name, detail, query) {
        const q = query.trim().toLowerCase();
        const n = name.toLowerCase();
        const d = (detail || "").toLowerCase();
        if (!q)
            return 1;
        if (n === q)
            return 1000;
        if (n.startsWith(q))
            return 800 - n.length;
        let i = n.indexOf(q);
        if (i >= 0)
            return 600 - i;
        if (d.indexOf(q) >= 0)
            return 400;
        let at = 0;
        for (let c of n)
            if (c === q[at])
                at++;
        return at === q.length ? 200 : -1;
    }
    function refresh() {
        const ctx = context();
        let candidates = [], query = search.text;
        if (ctx) {
            query = ctx.query;
            if (ctx.key === "scheme") {
                candidates = [
                    {
                        name: "Wallpaper-derived",
                        detail: "Extract the source color from the current wallpaper",
                        key: "scheme",
                        value: "wallpaper"
                    }
                ];
                if (/^#[0-9a-fA-F]{6}$/.test(query.trim()))
                    candidates.push({
                        name: "Use seed " + query.trim().toUpperCase(),
                        detail: "Generate a palette from this color",
                        key: "scheme",
                        value: query.trim()
                    });
            } else if (ctx.key === "variant") {
                candidates = [
                    {
                        name: "Automatic",
                        detail: "Use the wallpaper-aware default",
                        key: "variant",
                        value: "auto"
                    }
                ].concat(variants.map(v => ({
                            name: v.split("-").map(s => s.charAt(0).toUpperCase() + s.slice(1)).join(" "),
                            detail: "scheme-" + v,
                            key: "variant",
                            value: "scheme-" + v
                        })));
            } else if (ctx.key === "theme") {
                candidates = ["light", "dark", "auto"].map(v => ({
                            name: v.charAt(0).toUpperCase() + v.slice(1),
                            detail: v === "auto" ? "Follow the palette" : "Use " + v + " mode",
                            key: "theme",
                            value: v
                        }));
            } else {
                candidates = [
                    {
                        name: "Opaque",
                        key: "transparency",
                        value: "opaque"
                    },
                    {
                        name: "Translucent",
                        key: "transparency",
                        value: "translucent"
                    }
                ];
                const v = query.trim();
                if (/^(?:0(?:\.\d+)?|1(?:\.0+)?)$/.test(v) && Number(v) >= 0.7)
                    candidates.push({
                        name: "Opacity " + v,
                        detail: "Set a custom opacity",
                        key: "transparency",
                        value: v
                    });
            }
        } else if (query.startsWith(">")) {
            query = query.slice(1).trim();
            candidates = actions;
            if (["light", "dark", "auto"].indexOf(query.toLowerCase()) >= 0) {
                const mode = query.toLowerCase();
                candidates = [
                    {
                        name: mode.charAt(0).toUpperCase() + mode.slice(1),
                        detail: "Switch appearance mode",
                        key: "theme",
                        value: mode
                    }
                ];
            }
        } else {
            const entries = DesktopEntries.applications.values;
            candidates = entries.map(e => ({
                        name: e.name || e.id,
                        detail: e.comment || e.genericName || "Application",
                        entry: e,
                        icon: e.icon
                    }));
        }
        results = candidates.map((item, order) => ({
                    item: item,
                    score: rank(item.name, item.detail, query),
                    order: order
                })).filter(x => x.score >= 0).sort((a, b) => b.score - a.score || a.order - b.order).map(x => x.item);
        selectedIndex = 0;
        list.positionViewAtBeginning();
    }
    function activate(item) {
        if (!item)
            return;
        if (item.entry) {
            item.entry.execute();
            closeRequested();
        } else if (item.nested) {
            search.text = "> " + (item.key === "theme" ? "mode" : item.key) + " ";
            search.cursorPosition = search.length;
        } else {
            actionRequested(item.key, item.value || "");
        }
    }
    function back() {
        if (context()) {
            search.text = "> ";
            search.cursorPosition = search.length;
        } else {
            closeRequested();
        }
    }
    onActiveFocusChanged: if (activeFocus)
        search.forceActiveFocus()
    onInitialQueryChanged: {
        search.text = initialQuery;
        refresh();
    }
    Connections {
        target: DesktopEntries.applications
        ignoreUnknownSignals: true
        function onValuesChanged() {
            root.refresh();
        }
    }
    Component.onCompleted: {
        search.text = initialQuery;
        refresh();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        Row {
            width: parent.width
            height: 46
            spacing: 12
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.context() ? "‹" : "⌕"
                color: Theme.accent
                font.pixelSize: 25 * Theme.textScale
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.back()
                }
            }
            TextField {
                id: search
                focus: true
                width: parent.width - 45
                height: parent.height
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                placeholderText: "Search apps or type > for commands"
                placeholderTextColor: Theme.muted
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 16 * Theme.textScale
                selectByMouse: true
                background: Item {}
                onTextChanged: root.refresh()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        if (root.results.length) {
                            root.selectedIndex = (root.selectedIndex + (event.key === Qt.Key_Down ? 1 : -1) + root.results.length) % root.results.length;
                            list.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activate(root.results[root.selectedIndex]);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.back();
                        event.accepted = true;
                    }
                }
            }
        }
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hairline
        }
        Text {
            width: parent.width
            text: root.context() ? "COMMANDS  /  " + root.context().key.toUpperCase() : search.text.startsWith(">") ? "COMMANDS" : "APPLICATIONS"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            font.letterSpacing: 1
        }
        Item {
            width: parent.width
            height: Math.max(0, parent.height - 106)
            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 3
                model: root.results
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 54
                    radius: Theme.radiusSmall
                    color: index === root.selectedIndex ? Theme.surfaceHover : "transparent"
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12
                        Item {
                            width: 32
                            height: parent.height
                            Image {
                                anchors.centerIn: parent
                                width: 25
                                height: 25
                                visible: !!modelData.icon
                                source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                asynchronous: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !modelData.icon
                                text: modelData.entry ? "◈" : ">"
                                color: Theme.accent
                                font.pixelSize: 18 * Theme.textScale
                            }
                        }
                        Column {
                            width: parent.width - 80
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                width: parent.width
                                text: modelData.name
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 13 * Theme.textScale
                            }
                            Text {
                                width: parent.width
                                text: modelData.detail || ""
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: Theme.muted
                                font.family: Theme.fontFamily
                                font.pixelSize: 11 * Theme.textScale
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.nested ? "›" : index === root.selectedIndex ? "↵" : ""
                            color: Theme.muted
                            font.pixelSize: 16 * Theme.textScale
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = index
                        onClicked: root.activate(modelData)
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: root.context() && root.context().key === "scheme" && root.context().query.trim().startsWith("#") ? "Enter a six-digit hex color, e.g. #aabbcc" : root.context() && root.context().key === "transparency" ? "Choose Opaque, Translucent, or an opacity from 0.70 to 1.00" : "No results"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 13 * Theme.textScale
            }
        }
    }
}
