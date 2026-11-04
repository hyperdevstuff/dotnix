import QtQuick

Item {
    id: root

    property var workspaces: []
    property int currentId: 0
    property var theme: ({})

    readonly property int segmentHeight: 12

    implicitWidth: Math.max(180, row.childrenRect.width + 32)
    implicitHeight: 28

    function isOccupied(workspace) {
        if (!workspace)
            return false;
        if (workspace.occupied === true)
            return true;
        if (workspace.active_window_id !== null && workspace.active_window_id !== undefined)
            return true;
        return false;
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8
        height: root.implicitHeight

        Rectangle {
            width: 10
            height: root.segmentHeight
            anchors.verticalCenter: parent.verticalCenter
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: root.theme.muted || "#888888"
            opacity: 0.45
        }

        Item {
            width: 4
            height: root.segmentHeight
            anchors.verticalCenter: parent.verticalCenter
        }

        Repeater {
            model: root.workspaces

            delegate: Rectangle {
                id: segment

                required property var modelData

                readonly property bool active: modelData && modelData.id === root.currentId
                readonly property bool occupied: root.isOccupied(modelData)

                width: active ? 36 : (occupied ? 20 : 11)
                height: root.segmentHeight
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2

                color: active
                    ? (root.theme.accent || "#ffffff")
                    : (occupied ? (root.theme.accentDim || root.theme.accent || "#ffffff") : "transparent")
                border.width: active ? 0 : 1
                border.color: occupied
                    ? (root.theme.accentDim || root.theme.accent || "#ffffff")
                    : (root.theme.border || "#555555")
                opacity: active ? 1.0 : (occupied ? 0.82 : 0.55)

                Behavior on width {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
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

                Behavior on opacity {
                    NumberAnimation {
                        duration: 260
                    }
                }
            }
        }

        Item {
            width: 4
            height: root.segmentHeight
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 10
            height: root.segmentHeight
            anchors.verticalCenter: parent.verticalCenter
            radius: 6
            color: "transparent"
            border.width: 1
            border.color: root.theme.muted || "#888888"
            opacity: 0.45
        }
    }
}
