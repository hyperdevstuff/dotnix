import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Flickable {
    id: root
    property var state: null
    signal settingRequested(string key, real value)
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) contentY = Math.min(Math.max(0, contentHeight - height), contentY + (event.key === Qt.Key_Down ? 40 : height));
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) contentY = Math.max(0, contentY - (event.key === Qt.Key_Up ? 40 : height));
        else return;
        event.accepted = true;
    }
    clip: true
    contentWidth: width
    contentHeight: content.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    ColumnLayout {
        id: content
        width: root.width
        spacing: 16
        Text {
            Layout.leftMargin: 46
            Layout.preferredHeight: 36
            text: "Appearance"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 20 * Theme.textScale
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
        }
        SettingCard {
            title: "Color mode"
            description: "Use your matugen palette in light or dark."
            RowLayout {
                ActionButton {
                    label: "Light"
                    symbol: "light_mode"
                    selected: Theme.modePreference === "light"
                    onClicked: Quickshell.execDetached(["wp", "theme", "light"])
                }
                ActionButton {
                    label: "Dark"
                    symbol: "dark_mode"
                    selected: Theme.modePreference === "dark"
                    onClicked: Quickshell.execDetached(["wp", "theme", "dark"])
                }
                ActionButton {
                    label: "Auto"
                    selected: Theme.modePreference === "auto"
                    onClicked: Quickshell.execDetached(["wp", "theme", "auto"])
                }
            }
        }
        SettingCard {
            title: "Clock"
            description: "Choose how the time appears in the pill and header."
            RowLayout {
                ActionButton {
                    label: "24 hour"
                    selected: !Theme.use12HourClock
                    onClicked: root.settingRequested("clock12", 0)
                }
                ActionButton {
                    label: "12 hour"
                    selected: Theme.use12HourClock
                    onClicked: root.settingRequested("clock12", 1)
                }
            }
        }
        SettingCard {
            title: "Text size"
            description: "Scale labels without making controls harder to reach."
            RowLayout {
                Repeater {
                    model: [1, 1.1, 1.2]
                    ActionButton {
                        required property real modelData
                        label: Math.round(modelData * 100) + "%"
                        selected: Math.abs(Theme.textScale - modelData) < 0.01
                        onClicked: root.settingRequested("textScale", modelData)
                    }
                }
            }
        }
        SettingCard {
            title: "Motion"
            description: "Reduced motion keeps feedback while removing the spring and waveform motion."
            RowLayout {
                ActionButton {
                    label: "Full"
                    selected: !Motion.reduceMotion
                    onClicked: root.settingRequested("reduceMotion", 0)
                }
                ActionButton {
                    label: "Reduced"
                    selected: Motion.reduceMotion
                    onClicked: root.settingRequested("reduceMotion", 1)
                }
            }
        }
        SettingCard {
            title: "Surface"
            description: "Choose the island shape and panel opacity."
            RowLayout {
                ActionButton {
                    label: "Pill"
                    selected: !Theme.notchMode
                    onClicked: root.settingRequested("notch", 0)
                }
                ActionButton {
                    label: "Notch"
                    selected: Theme.notchMode
                    onClicked: root.settingRequested("notch", 1)
                }
            }
            NotchSlider {
                Layout.fillWidth: true
                label: "Panel opacity"
                glyph: "\uf013"
                value: (Theme.surfaceOpacity - 0.7) / 0.3
                displayValue: Theme.surfaceOpacity
                onMoved: value => root.settingRequested("opacity", 0.7 + value * 0.3)
            }
        }
        RowLayout {
            ActionButton {
                label: "Modules"
                symbol: "tune"
                tonal: true
                onClicked: if (root.state)
                    root.state.openFlyout("settings")
            }
            ActionButton {
                label: "Agent limits"
                symbol: "terminal"
                onClicked: if (root.state)
                    root.state.selectTab("Limits")
            }
        }
    }
    component SettingCard: Rectangle {
        property string title: ""
        property string description: ""
        default property alias content: inner.data
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight + 28
        radius: 20
        color: Theme.surface
        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12
            Text {
                text: parent.parent.title
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14 * Theme.textScale
                font.weight: Font.DemiBold
            }
            Text {
                Layout.fillWidth: true
                text: parent.parent.description
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12 * Theme.textScale
                wrapMode: Text.Wrap
            }
        }
    }
}
