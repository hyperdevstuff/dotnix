// SPDX-License-Identifier: GPL-3.0-only
// Adapted from caelestia-dots; see notification-attribution/README.md.
import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    implicitWidth: 240
    implicitHeight: 360

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontDisplay
                font.weight: Font.DemiBold
            }
            Rectangle {
                activeFocusOnTab: true
                Accessible.role: Accessible.CheckBox
                Accessible.name: "Do not disturb"
                Accessible.checked: Services.Notifications.dnd
                Keys.onReturnPressed: Services.Notifications.dnd = !Services.Notifications.dnd
                Keys.onSpacePressed: Services.Notifications.dnd = !Services.Notifications.dnd
                implicitWidth: dndLabel.implicitWidth + 16
                implicitHeight: 28
                radius: 14
                color: dndMouse.pressed ? Theme.surfacePress : dndHover.hovered ? Theme.surfaceHover : Theme.surface
                HoverHandler {
                    id: dndHover
                }
                Text {
                    id: dndLabel
                    anchors.centerIn: parent
                    text: Services.Notifications.dnd ? "DND on" : "DND off"
                    color: Services.Notifications.dnd ? Theme.accent : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    onClicked: Services.Notifications.dnd = !Services.Notifications.dnd
                }
            }
            Rectangle {
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Clear notification history"
                Keys.onReturnPressed: Services.Notifications.clearHistory()
                Keys.onSpacePressed: Services.Notifications.clearHistory()
                implicitWidth: clearLabel.implicitWidth + 16
                implicitHeight: 28
                radius: 14
                visible: Services.Notifications.historyCount > 0
                color: clearMouse.pressed ? Theme.surfacePress : clearHover.hovered ? Theme.surfaceHover : "transparent"
                HoverHandler {
                    id: clearHover
                }
                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    onClicked: Services.Notifications.clearHistory()
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: Services.Notifications.historyCount === 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\uf0f3"
                    color: Theme.muted
                    font.family: Theme.iconFont
                    font.pixelSize: 22 * Theme.textScale
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "You're all caught up"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "New notifications will appear here"
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
            }
            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 8
                visible: Services.Notifications.historyCount > 0
                model: Services.Notifications.history
                delegate: Column {
                    required property var modelData
                    required property int index
                    width: list.width
                    spacing: 6
                    readonly property string day: new Date(modelData.time).toDateString()
                    readonly property string previousDay: index > 0 ? new Date(Services.Notifications.history[index - 1].time).toDateString() : ""
                    Text {
                        visible: parent.day !== parent.previousDay
                        text: parent.day === new Date().toDateString() ? "Today" : Qt.formatDate(new Date(parent.modelData.time), "ddd, MMM d")
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                    }
                    NotificationCard {
                        width: parent.width
                        snapshot: parent.modelData
                        notification: {
                            const update = Services.Notifications.entries;
                            return Services.Notifications.liveForKey(snapshot.key);
                        }
                    }
                }
            }
        }
    }
}
