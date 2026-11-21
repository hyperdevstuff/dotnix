import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    signal wallpapersRequested
    signal settingRequested(string key, real value)
    readonly property real requiredWidth: 980
    readonly property string tab: state ? state.hubTab : "Dashboard"
    readonly property bool secondary: ["Calendar", "Tray", "Appearance", "Activity", "Limits", "Clipboard"].indexOf(tab) >= 0
    readonly property real calendarContentHeight: tab === "Calendar" && page.item ? page.item.implicitHeight : 295
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        HubHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            state: root.state
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            Row {
                id: dashboard
                anchors.fill: parent
                spacing: 16
                visible: root.tab === "Dashboard"
                readonly property bool wide: width >= 760
                readonly property real mediaWidth: Math.floor((width - 32) * 0.30)
                readonly property real controlsWidth: Math.floor((width - 32) * 0.35)
                MediaSurface {
                    visible: dashboard.wide
                    width: dashboard.mediaWidth
                    height: parent.height
                    state: root.state
                }
                Flickable {
                    width: dashboard.wide ? dashboard.controlsWidth : dashboard.width
                    height: parent.height
                    contentWidth: width
                    contentHeight: controls.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: controls
                        width: parent.width
                        spacing: 10
                        NotchSlider {
                            width: parent.width
                            label: "Volume"
                            glyph: Services.System.volumeMuted ? "\uf026" : "\uf028"
                            value: Services.System.volume
                            muted: Services.System.volumeMuted
                            canToggle: true
                            onMoved: value => Services.System.setVolume(value)
                            onToggled: Services.System.toggleMute()
                        }
                        NotchSlider {
                            width: parent.width
                            label: "Brightness"
                            glyph: "\uf185"
                            value: Services.System.brightness
                            onMoved: value => Services.System.setBrightness(value)
                        }
                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 8
                            Repeater {
                                model: Modules.enabledManifests.filter(m => ["wifi", "bluetooth", "audio", "display"].indexOf(m.id) >= 0)
                                delegate: QuickSetting {
                                    required property var modelData
                                    width: (controls.width - 8) / 2
                                    title: modelData.id === "display" ? "Night light" : modelData.title
                                    subtitle: modelData.id === "wifi" ? Services.Network.statusText : modelData.id === "bluetooth" ? Services.Bluetooth.statusText : modelData.id === "audio" ? (Services.System.volumeMuted ? "Muted" : Services.System.sinkName) : Services.System.nightLight ? "Tint enabled" : "Off"
                                    symbol: modelData.id === "wifi" ? Services.Network.wifiEnabled ? "wifi" : "wifi_off" : modelData.id === "bluetooth" ? "bluetooth" : modelData.id === "audio" ? Services.System.volumeMuted ? "volume_off" : "volume_up" : "dark_mode"
                                    checked: modelData.id === "wifi" ? Services.Network.wifiEnabled : modelData.id === "bluetooth" ? Services.Bluetooth.enabled : modelData.id === "audio" ? !Services.System.volumeMuted : Services.System.nightLight
                                    toggleable: true
                                    onTriggered: {
                                        if (modelData.id === "wifi")
                                            Services.Network.toggleWifi();
                                        else if (modelData.id === "bluetooth")
                                            Services.Bluetooth.toggle();
                                        else if (modelData.id === "audio")
                                            Services.System.toggleMute();
                                        else
                                            Services.System.setNightLight(!Services.System.nightLight);
                                    }
                                    onDetailsRequested: if (root.state)
                                        root.state.openFlyout(modelData.id)
                                }
                            }
                        }
                        Grid {
                            width: parent.width
                            columns: 3
                            spacing: 6
                            Repeater {
                                model: [
                                    {
                                        name: "Wallpaper",
                                        symbol: "wallpaper",
                                        action: "walls"
                                    },
                                    {
                                        name: "Clipboard",
                                        symbol: "content_paste",
                                        action: "Clipboard"
                                    },
                                    {
                                        name: "Capture",
                                        symbol: "photo_camera",
                                        action: "capture"
                                    },
                                    {
                                        name: "Keep awake",
                                        symbol: "coffee",
                                        action: "Activity"
                                    },
                                    {
                                        name: "Power",
                                        symbol: "power_settings_new",
                                        action: "session"
                                    },
                                    {
                                        name: "Settings",
                                        symbol: "settings",
                                        action: "Appearance"
                                    }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (controls.width - 12) / 3
                                    height: 54
                                    radius: 16
                                    color: utilityMouse.pressed ? Theme.surfacePress : utilityMouse.containsMouse || activeFocus ? Theme.surfaceHover : "transparent"
                                    border.color: activeFocus ? Theme.accent : "transparent"
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.name
                                    function activate() {
                                        if (!root.state)
                                            return;
                                        if (modelData.action === "walls")
                                            root.wallpapersRequested();
                                        else if (modelData.action === "capture") {
                                            root.state.collapse();
                                            Quickshell.execDetached(["notchd-screenshot"]);
                                        } else if (modelData.action === "session")
                                            root.state.openFlyout("session");
                                        else
                                            root.state.selectTab(modelData.action);
                                    }
                                    Keys.onReturnPressed: activate()
                                    Keys.onSpacePressed: activate()
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Symbol {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            name: modelData.symbol
                                            size: 18
                                            tint: modelData.action === "Activity" && Services.KeepAwake.active ? Theme.accent : Theme.muted
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.name
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11 * Theme.textScale
                                        }
                                    }
                                    MouseArea {
                                        id: utilityMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.activate()
                                    }
                                }
                            }
                        }
                        MediaSurface {
                            visible: !dashboard.wide
                            width: parent.width
                            height: visible ? 340 : 0
                            state: root.state
                        }
                        Loader {
                            visible: !dashboard.wide
                            active: visible && root.tab === "Dashboard"
                            width: parent.width
                            height: visible ? 300 : 0
                            source: "NotificationCenter.qml"
                        }
                    }
                }
                Loader {
                    visible: dashboard.wide
                    active: visible && root.tab === "Dashboard"
                    width: dashboard.width - dashboard.mediaWidth - dashboard.controlsWidth - 32
                    height: parent.height
                    source: "NotificationCenter.qml"
                }
            }
            Loader {
                id: page
                anchors.fill: parent
                active: root.tab !== "Dashboard"
                source: root.tab === "Media" ? "MediaPage.qml" : root.tab === "Performance" ? "PerformanceSurface.qml" : root.tab === "Calendar" ? "CalendarSurface.qml" : root.tab === "Tray" ? "TraySurface.qml" : root.tab === "Appearance" ? "AppearanceSurface.qml" : root.tab === "Activity" ? "ActivitySurface.qml" : root.tab === "Clipboard" ? "ClipboardSurface.qml" : root.tab === "Limits" ? "UsageSurface.qml" : ""
                onLoaded: {
                    if (item && item.state !== undefined)
                        item.state = root.state;
                    if (item && item.refresh)
                        item.refresh();
                    if (item && ["Calendar", "Clipboard", "Appearance", "Activity", "Tray"].indexOf(root.tab) >= 0)
                        item.forceActiveFocus();
                    if (item && item.closeRequested)
                        item.closeRequested.connect(function () {
                            if (root.state)
                                root.state.collapse();
                        });
                    if (item && item.settingRequested)
                        item.settingRequested.connect(function (key, value) {
                            root.settingRequested(key, value);
                        });
                }
            }
            ActionButton {
                visible: root.secondary
                x: 0
                y: 0
                implicitWidth: 36
                implicitHeight: 36
                symbol: "arrow_back"
                Accessible.name: "Back to dashboard"
                onClicked: if (root.state)
                    root.state.back()
            }
        }
    }
}
