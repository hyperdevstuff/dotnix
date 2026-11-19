import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import ".."
import "../services" as Services

// One notification card. Cards are plain QML rectangles in the running shell;
// no extra process, no webview and no animation framework.
Rectangle {
    id: root

    required property var notification

    signal closed()

    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical

    readonly property var shownActions: {
        const out = []
        const list = notification && notification.actions ? notification.actions : []
        for (let i = 0; i < list.length && out.length < 2; i++)
            if (list[i] && list[i].text && list[i].text.length > 0) out.push(list[i])
        return out
    }

    // Seconds in Quickshell, milliseconds in QML. 0 = never; -1 = server default.
    readonly property int timeoutMs: {
        if (!notification) return 0
        if (critical) return 0
        if (notification.expireTimeout > 0) return Math.round(notification.expireTimeout * 1000)
        if (notification.expireTimeout === 0) return 0
        return 8000
    }

    readonly property string iconSource: {
        if (!notification) return ""
        if (notification.image && notification.image.length > 0) return notification.image
        const icon = notification.appIcon || ""
        if (icon.length === 0) return ""
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true)
    }

    implicitHeight: content.implicitHeight + 24
    radius: Theme.radius
    color: Theme.panelSolid
    border.width: 1
    border.color: critical ? Theme.danger : Theme.hairline
    antialiasing: true

    HoverHandler { id: hover }

    // Pause while the pointer is over the card so long messages can be read.
    Timer {
        id: expiry
        interval: root.timeoutMs
        running: root.timeoutMs > 0 && !hover.hovered && !Services.Notifications.paused
        onTriggered: if (root.notification) root.notification.expire()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: {
            if (!root.notification) return
            const actions = root.notification.actions || []
            // The first action is the spec's default action; invoking it also
            // dismisses the card when it is not resident.
            if (actions.length > 0) actions[0].invoke()
            else root.notification.dismiss()
        }
    }

    Connections {
        target: root.notification
        function onClosed() { root.closed() }
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 12
            rightMargin: 30 // leave room for the close button
            topMargin: 12
        }
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 34
            implicitHeight: 34
            radius: 9
            color: Theme.surface

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
                cache: false
                visible: source !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: !icon.visible
                text: "\uf0f3"
                color: Theme.muted
                font.family: Theme.iconFont
                font.pixelSize: 16
                textFormat: Text.PlainText
                renderType: Text.NativeRendering
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.notification ? (root.notification.appName || "Notification") : ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                elide: Text.ElideRight
                textFormat: Text.PlainText
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.notification ? (root.notification.summary || "") : ""
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
                text: root.notification ? (root.notification.body || "") : ""
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

                        implicitWidth: actionLabel.implicitWidth + 16
                        implicitHeight: 24
                        radius: Theme.radiusSmall
                        color: actionHover.hovered ? Theme.surfacePress : Theme.surface

                        HoverHandler { id: actionHover }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            textFormat: Text.PlainText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: closeButton
        width: 20
        height: 20
        radius: 10
        anchors {
            top: parent.top
            right: parent.right
            topMargin: 6
            rightMargin: 6
        }
        color: closeHover.hovered ? Theme.surfacePress : "transparent"

        HoverHandler { id: closeHover }

        Text {
            anchors.centerIn: parent
            text: "\uf00d"
            color: Theme.muted
            font.family: Theme.iconFont
            font.pixelSize: 11
            textFormat: Text.PlainText
            renderType: Text.NativeRendering
        }

        MouseArea {
            anchors.fill: parent
            onClicked: if (root.notification) root.notification.dismiss()
        }
    }
}
