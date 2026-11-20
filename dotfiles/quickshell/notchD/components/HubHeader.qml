import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

RowLayout {
    id: root
    property var state: null
    spacing: 12
    implicitHeight: 44
    Rectangle {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: 44
        radius: 10
        color: clockMouse.pressed ? Theme.surfacePress : clockMouse.containsMouse || activeFocus ? Theme.surfaceHover : "transparent"
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Services.Time.time + ", " + Services.Time.weekday + ", " + Services.Time.date + ". Open calendar."
        function activate() {
            if (root.state)
                root.state.selectTab("Calendar");
        }
        Keys.onReturnPressed: activate()
        Keys.onSpacePressed: activate()
        border.color: activeFocus ? Theme.accent : "transparent"
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            spacing: 12
            Text {
                text: Services.Time.time
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 28
                font.weight: Font.DemiBold
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: Services.Time.weekday
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: Services.Time.date
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
        MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activate()
        }
    }
    Row {
        Layout.preferredWidth: implicitWidth
        spacing: 4
        readonly property int capacity: Math.max(0, Math.min(5, Math.floor(root.width * 0.38 / 36) - 1))
        Repeater {
            model: Services.Tray.activeItems.slice(0, parent.capacity)
            delegate: TrayButton {
                required property var modelData
                item: modelData
                onActivated: if (root.state)
                    root.state.collapse()
            }
        }
        Rectangle {
            width: 36
            height: 32
            radius: 10
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Background apps, " + Services.Tray.count + " tray icons"
            function activate() {
                if (root.state)
                    root.state.selectTab("Tray");
            }
            Keys.onReturnPressed: activate()
            Keys.onSpacePressed: activate()
            border.color: activeFocus ? Theme.accent : "transparent"
            color: trayMouse.pressed ? Theme.surfacePress : trayMouse.containsMouse || activeFocus ? Theme.surfaceHover : Theme.surface
            Icon {
                anchors.centerIn: parent
                glyph: "\uf009"
                size: 15
                tint: Services.Tray.attentionCount ? Theme.accent : Theme.muted
            }
            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: parent.activate()
            }
        }
    }
}
