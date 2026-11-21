import QtQuick
import QtQuick.Layouts
import ".."
import "../components"
import "../services" as Services

// Session and power flyout. Destructive actions are armed by the first click
// and executed by the second within three seconds.
FlyoutFrame {
    id: root

    title: "Session"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Icon { glyph: "\uf007"; size: 12; tint: Theme.muted }
            Text {
                Layout.fillWidth: true
                text: Services.System.powerProfileText + " profile"
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
            }
            Text {
                text: Services.Session.sessionId.length > 0 ? ("session " + Services.Session.sessionId) : ""
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 6
            rowSpacing: 6

            SessionButton {
                Layout.fillWidth: true
                label: "Lock"
                hint: "notchD lock screen"
                glyph: "\uf023"
                onActivated: Services.Session.lock()
            }

            SessionButton {
                Layout.fillWidth: true
                label: "Suspend"
                hint: "systemctl sleep"
                glyph: "\uf186"
                onActivated: Services.Session.suspend()
            }

            SessionButton {
                Layout.fillWidth: true
                label: "Log out"
                hint: "end the session"
                glyph: "\uf08b"
                confirmRequired: true
                onActivated: Services.Session.logout()
            }

            SessionButton {
                Layout.fillWidth: true
                label: "Reboot"
                hint: "restart the machine"
                glyph: "\uf01e"
                confirmRequired: true
                danger: true
                onActivated: Services.Session.reboot()
            }

            SessionButton {
                Layout.fillWidth: true
                label: "Shut down"
                hint: "power off"
                glyph: "\uf011"
                confirmRequired: true
                danger: true
                onActivated: Services.Session.poweroff()
            }

            SessionButton {
                Layout.fillWidth: true
                label: "Monitors off"
                hint: "blank displays"
                glyph: "\uf108"
                onActivated: Services.Session.powerOffMonitors()
            }
        }

        Item { Layout.fillHeight: true }

        Text {
            Layout.fillWidth: true
            text: "Lock uses the native Quickshell lock screen. Suspend, reboot and shutdown use logind; polkit prompts appear in notchD."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            wrapMode: Text.WordWrap
            opacity: 0.8
        }
    }

    component SessionButton: Rectangle {
        id: button

        property string label: ""
        property string hint: ""
        property string glyph: ""
        property bool danger: false
        property bool confirmRequired: false
        property bool armed: false

        signal activated()

        height: 70
        radius: Theme.radiusSmall
        color: button.armed ? (Theme.dark ? Qt.rgba(0.97, 0.44, 0.44, 0.16) : Qt.rgba(0.86, 0.15, 0.15, 0.08))
            : (buttonMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
        border.width: 1
        border.color: button.armed ? Theme.danger : Theme.hairlineSoft

        Behavior on color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 0

            RowLayout {
                spacing: 7
                Icon {
                    glyph: button.glyph
                    size: 12
                    tint: button.armed ? Theme.danger : (button.danger ? Theme.danger : Theme.fg)
                }
                Text {
                    Layout.fillWidth: true
                    text: button.armed ? "Confirm" : button.label
                    color: button.armed ? Theme.danger : Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11 * Theme.textScale
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: button.armed ? "tap again" : button.hint
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
                elide: Text.ElideRight
            }
        }

        Timer {
            id: armTimer
            interval: 3000
            onTriggered: button.armed = false
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (button.confirmRequired && !button.armed) {
                    button.armed = true;
                    armTimer.restart();
                    return;
                }
                button.armed = false;
                armTimer.stop();
                button.activated();
            }
        }
    }
}
