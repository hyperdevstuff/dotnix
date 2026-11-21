// SPDX-License-Identifier: GPL-3.0-only
// Adapted from caelestia-dots; see notification-attribution/README.md.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../services" as Services

Rectangle {
    id: root
    property var notification: null
    property var snapshot: null
    property bool popup: false
    signal closed
    readonly property var cardData: snapshot || notification
    readonly property bool critical: cardData && cardData.urgency === NotificationUrgency.Critical
    readonly property var shownActions: {
        const result = [];
        const actions = notification && notification.actions ? notification.actions : [];
        for (let i = 0; i < actions.length && result.length < 2; i++)
            if (actions[i] && actions[i].text)
                result.push(actions[i]);
        return result;
    }
    readonly property string iconSource: {
        if (!cardData)
            return "";
        const icon = cardData.image || cardData.appIcon || "";
        if (!icon)
            return "";
        if (icon.startsWith("/"))
            return "file://" + icon;
        if (icon.indexOf("://") >= 0)
            return icon;
        return Quickshell.iconPath(icon, true);
    }
    readonly property real progress: {
        const update = Services.Notifications.progressRevision;
        return popup && notification ? Services.Notifications.progressFor(notification) : -1;
    }
    readonly property double timestamp: snapshot ? snapshot.time : notification ? Services.Notifications.timeFor(notification) : Date.now()
    implicitHeight: content.implicitHeight + 24 + (progress >= 0 ? 3 : 0)
    radius: Theme.radius
    color: critical ? Theme.accentContainer : Theme.surface
    border.width: 1
    border.color: critical ? Theme.danger : Theme.hairline
    antialiasing: true

    HoverHandler {
        id: hover
        onHoveredChanged: if (root.popup && root.notification)
            Services.Notifications.setHovered(root.notification, root, hovered)
    }
    Component.onDestruction: if (popup && notification)
        Services.Notifications.setHovered(notification, root, false)
    Connections {
        target: root.notification
        ignoreUnknownSignals: true
        function onClosed() {
            root.closed();
        }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            rightMargin: 32
        }
        spacing: 10
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 34
            implicitHeight: 34
            radius: 17
            color: Theme.accentContainer
            Image {
                id: icon
                anchors.centerIn: parent
                width: 22
                height: 22
                source: root.iconSource
                sourceSize.width: 44
                sourceSize.height: 44
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: source !== "" && status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !icon.visible
                text: "\uf0f3"
                color: Theme.accentContainerInk
                font.family: Theme.iconFont
                font.pixelSize: 16 * Theme.textScale
                textFormat: Text.PlainText
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Text {
                    Layout.fillWidth: true
                    text: root.cardData ? (root.cardData.appName || "Notification") : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Text {
                    text: Qt.formatTime(new Date(root.timestamp), "hh:mm")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontLabel
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.cardData ? (root.cardData.summary || "") : ""
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.cardData ? (root.cardData.body || "") : ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 6
                visible: root.shownActions.length > 0
                Repeater {
                    model: root.shownActions
                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: 30
                        radius: Theme.radiusSmall
                        color: actionMouse.pressed ? Theme.surfacePress : actionHover.hovered ? Theme.surfaceHover : Theme.panelSolid
                        scale: actionMouse.pressed ? 0.97 : 1
                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }
                        HoverHandler {
                            id: actionHover
                        }
                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.text
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                        }
                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        width: 24
        height: 24
        radius: 12
        anchors {
            top: parent.top
            right: parent.right
            margins: 6
        }
        color: closeMouse.pressed ? Theme.surfacePress : closeHover.hovered ? Theme.surfaceHover : "transparent"
        scale: closeMouse.pressed ? 0.95 : 1
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        HoverHandler {
            id: closeHover
        }
        Text {
            anchors.centerIn: parent
            text: "\uf00d"
            color: Theme.muted
            font.family: Theme.iconFont
            font.pixelSize: 11 * Theme.textScale
            textFormat: Text.PlainText
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            onClicked: {
                if (root.snapshot)
                    Services.Notifications.removeHistory(root.snapshot.key);
                else if (root.notification)
                    Services.Notifications.dismiss(root.notification);
            }
        }
    }
    Rectangle {
        visible: root.progress >= 0
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 12
            bottomMargin: 6
        }
        height: 2
        radius: 1
        color: Theme.track
        Rectangle {
            width: parent.width * Math.max(0, root.progress)
            height: parent.height
            radius: 1
            color: Theme.accent
        }
    }
}
