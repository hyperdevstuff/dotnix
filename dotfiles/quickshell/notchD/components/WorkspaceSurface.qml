import QtQuick
import ".."
import "../services" as Services

Flickable {
    id: root
    property var state: null
    clip: true
    contentWidth: width
    contentHeight: workspaceFlow.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    onActiveFocusChanged: if (activeFocus) {
        Qt.callLater(() => {
            const ws = Services.Compositor.workspacesData;
            let index = ws.findIndex(w => w.is_focused);
            const card = workspaceRepeater.itemAt(Math.max(0, index));
            if (card) card.forceActiveFocus();
        });
    }
    Flow {
        id: workspaceFlow
        width: root.width
        spacing: 10
        Repeater {
            id: workspaceRepeater
            model: Services.Compositor.workspacesData
            delegate: Rectangle {
                required property var modelData
                required property int index
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Workspace " + Services.Compositor.workspaceLabel(modelData)
                function activate() {
                    Services.Compositor.activateWorkspace({ idx: modelData.idx, name: Services.Compositor.workspaceLabel(modelData), raw: modelData });
                }
                Accessible.onPressAction: activate()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        activate(); event.accepted = true;
                    } else {
                        const cols = Math.max(1, Math.floor((workspaceFlow.width + 10) / (width + 10)));
                        const delta = event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Left ? -1 : event.key === Qt.Key_Down ? cols : event.key === Qt.Key_Up ? -cols : 0;
                        if (delta) {
                            const card = workspaceRepeater.itemAt(Math.max(0, Math.min(workspaceRepeater.count - 1, index + delta)));
                            if (card) { card.forceActiveFocus(); root.contentY = Math.max(0, Math.min(card.y, root.contentHeight - root.height)); }
                            event.accepted = true;
                        }
                    }
                }
                width: Math.max(120, Math.min(200, (workspaceFlow.width - 30) / 4))
                height: 82
                radius: 12
                color: modelData.is_focused || modelData.is_active ? Theme.accentContainer : Theme.surface
                border.width: activeFocus || modelData.is_focused ? 2 : 0
                border.color: Theme.accent
                Column {
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Services.Compositor.workspaceLabel(modelData)
                        color: Theme.fg
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.is_focused ? "Focused" : modelData.is_active ? "Active" : String(modelData.output || "")
                        color: Theme.muted
                        font.pixelSize: 11
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.activate()
                }
            }
        }
        Text {
            visible: Services.Compositor.workspacesData.length === 0
            text: "No workspaces available"
            color: Theme.muted
            font.pixelSize: 12
        }
    }
}
