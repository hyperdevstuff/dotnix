import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import ".."

Item {
    id: root
    implicitWidth: 440
    implicitHeight: 350
    property var state: null
    property var entries: []
    property var filtered: []
    property int selected: 0
    property string status: "Loading clipboard…"
    property string previewText: ""
    property string previewImage: ""
    property string previewId: ""
    property string pendingPreview: ""
    signal closeRequested

    function refresh() {
        status = "Loading clipboard…";
        if (!listProc.running)
            listProc.running = true;
    }
    function filter() {
        const query = search.text.toLowerCase();
        filtered = entries.filter(e => e.label.toLowerCase().includes(query));
        selected = 0;
        updatePreview();
    }
    function updatePreview() {
        previewText = "";
        previewImage = "";
        pendingPreview = filtered.length ? filtered[selected].id : "";
        if (!previewProc.running && pendingPreview) {
            previewId = pendingPreview;
            pendingPreview = "";
            previewProc.running = true;
        }
    }
    function move(delta) {
        if (!filtered.length)
            return;
        selected = Math.max(0, Math.min(filtered.length - 1, selected + delta));
        list.positionViewAtIndex(selected, ListView.Contain);
        updatePreview();
    }
    function perform(action) {
        if (!filtered.length || actionProc.running)
            return;
        actionProc.command = ["notchd-clipboard", action, filtered[selected].id];
        actionProc.running = true;
    }
    onActiveFocusChanged: if (activeFocus)
        search.forceActiveFocus()
    onVisibleChanged: if (visible) {
        refresh();
        search.forceActiveFocus();
    }

    Process {
        id: listProc
        command: ["notchd-clipboard", "list"]
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: listProc.output = text
        }
        onExited: code => {
            if (code !== 0) {
                root.status = "Could not load clipboard history";
                return;
            }
            try {
                root.entries = JSON.parse(output);
                root.status = root.entries.length ? "" : "Clipboard history is empty";
                root.filter();
            } catch (e) {
                root.status = "Could not read clipboard history";
            }
        }
    }
    Process {
        id: previewProc
        command: ["notchd-clipboard", "preview", root.previewId]
        property string output: ""
        stdout: StdioCollector {
            onStreamFinished: previewProc.output = text
        }
        onExited: code => {
            if (!root.pendingPreview && root.filtered.length && root.filtered[root.selected].id === root.previewId) {
                if (code === 0) {
                    try {
                        const result = JSON.parse(output);
                        root.previewText = result.text || "";
                        root.previewImage = result.image || "";
                    } catch (e) {
                        root.previewText = "Preview unavailable";
                    }
                } else
                    root.previewText = "Preview unavailable";
            }
            if (root.pendingPreview) {
                root.previewId = root.pendingPreview;
                root.pendingPreview = "";
                previewProc.running = true;
            }
        }
    }
    Process {
        id: actionProc
        onExited: code => {
            if (code !== 0) {
                root.status = "Clipboard action failed";
                return;
            }
            if (command[1] === "copy")
                root.closeRequested();
            else
                root.refresh();
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        Text {
            text: "Clipboard"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: Theme.radiusSmall
            color: Theme.surface
            border.color: search.activeFocus ? Theme.muted : Theme.hairline
            TextInput {
                id: search
                anchors.fill: parent
                anchors.margins: 9
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 12
                clip: true
                selectByMouse: true
                Accessible.name: "Search clipboard"
                onTextChanged: root.filter()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Down)
                        root.move(1);
                    else if (event.key === Qt.Key_Up)
                        root.move(-1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.perform("copy");
                    else if (event.key === Qt.Key_Escape)
                        root.closeRequested();
                    else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ControlModifier))
                        root.perform("delete");
                    else
                        return;
                    event.accepted = true;
                }
                Text {
                    anchors.fill: parent
                    visible: !search.text
                    text: "Search history"
                    color: Theme.muted
                    font: search.font
                }
            }
        }
        Text {
            visible: root.status !== "" || !root.filtered.length
            text: root.status || "No matching clips"
            color: Theme.muted
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ListView {
                id: list
                width: Math.floor((parent.width - 8) * 0.48)
                height: parent.height
                clip: true
                spacing: 4
                model: root.filtered
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 44
                    radius: Theme.radiusSmall
                    border.width: index === root.selected ? 1 : 0
                    border.color: Theme.muted
                    color: mouse.pressed ? Theme.surfacePress : (mouse.containsMouse || index === root.selected ? Theme.surfaceHover : Theme.surface)
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.label
                    Accessible.onPressAction: {
                        root.selected = index;
                        root.perform("copy");
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 8
                        textFormat: Text.PlainText
                        text: modelData.label
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }
                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.selected = index;
                            root.updatePreview();
                            search.forceActiveFocus();
                        }
                        onDoubleClicked: { root.selected = index; root.perform("copy"); }
                    }
                }
            }
            Rectangle {
                x: list.width + 8
                width: Math.max(0, parent.width - x)
                height: parent.height
                radius: Theme.radiusSmall
                color: Theme.surface
                clip: true
                Image {
                    anchors.fill: parent
                    anchors.margins: 8
                    source: root.previewImage
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: source !== ""
                }
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    contentHeight: preview.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    visible: !root.previewImage
                    Text {
                        id: preview
                        width: parent.width
                        textFormat: Text.PlainText
                        text: root.previewText
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: "↑ ↓ Preview   Enter Copy   Ctrl+Delete Remove   Esc Close"
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
