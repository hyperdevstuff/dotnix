import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

Item {
    id: root
    property var state: null
    signal wallpapersRequested
    readonly property real requiredWidth: 980
    readonly property string tab: state ? state.hubTab : "Dashboard"
    readonly property var tabs: state ? state.mainTabs : ["Dashboard", "Media", "Performance"]
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10
        HubHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            state: root.state
        }
        Item {
            id: tabsBar
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            Row {
                id: tabRow
                anchors.fill: parent
                Repeater {
                    id: tabRepeater
                    model: root.tabs
                    delegate: Item {
                        required property string modelData
                        required property int index
                        width: tabRow.width / root.tabs.length
                        height: tabRow.height
                        activeFocusOnTab: true
                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.tab === modelData ? Theme.accent : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "transparent"
                            border.color: parent.activeFocus ? Theme.accent : "transparent"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.state)
                                    root.state.selectTab(modelData, true);
                                parent.forceActiveFocus();
                            }
                        }
                        Keys.onLeftPressed: event => {
                            if (root.state)
                                root.state.stepTab(-1);
                            tabRepeater.itemAt((index + root.tabs.length - 1) % root.tabs.length).forceActiveFocus();
                            event.accepted = true;
                        }
                        Keys.onRightPressed: event => {
                            if (root.state)
                                root.state.stepTab(1);
                            tabRepeater.itemAt((index + 1) % root.tabs.length).forceActiveFocus();
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: event => {
                            if (root.state)
                                root.state.selectTab(modelData);
                            event.accepted = true;
                        }
                    }
                }
            }
            // One shared indicator tracks the selected tab, as in Caelestia's dashboard.
            Rectangle {
                width: Math.min(72, tabsBar.width / root.tabs.length - 8)
                height: 3
                radius: 2
                x: Math.max(0, root.tabs.indexOf(root.tab)) * tabsBar.width / root.tabs.length + (tabsBar.width / root.tabs.length - width) / 2
                anchors.bottom: parent.bottom
                color: Theme.accent
                Behavior on x {
                    enabled: root.state && root.state.animateTabChange && !Motion.reduceMotion
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on width {
                    enabled: root.state && root.state.animateTabChange && !Motion.reduceMotion
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            Row {
                id: dashboardRow
                anchors.fill: parent
                spacing: 16
                visible: root.tab === "Dashboard"
                readonly property bool showSides: width >= 760
                readonly property real mediaWidth: Math.floor((width - 32) * 0.30)
                readonly property real controlsWidth: Math.floor((width - 32) * 0.35)
                readonly property real notificationsWidth: width - mediaWidth - controlsWidth - 32
                MediaSurface {
                    visible: parent.showSides
                    width: parent.mediaWidth
                    height: parent.height
                    state: root.state
                }
                Flickable {
                    width: parent.showSides ? parent.controlsWidth : parent.width
                    height: parent.height
                    clip: true
                    contentWidth: width
                    contentHeight: controlsColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    Column {
                        id: controlsColumn
                        width: parent.width
                        spacing: 8
                        NotchSlider {
                            width: parent.width
                            height: 38
                            label: "Volume"
                            glyph: Services.System.volumeMuted ? "\uf026" : "\uf028"
                            value: Services.System.volume
                            muted: Services.System.volumeMuted
                            onMoved: v => Services.System.setVolume(v)
                            canToggle: true
                            onToggled: Services.System.toggleMute()
                        }
                        NotchSlider {
                            width: parent.width
                            height: 38
                            label: "Brightness"
                            glyph: "\uf185"
                            value: Services.System.brightness
                            canToggle: false
                            onMoved: v => Services.System.setBrightness(v)
                        }
                        Flow {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: Modules.enabledManifests
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    readonly property bool active: modelData.id === "wifi" ? Services.Network.connected : modelData.id === "bluetooth" ? Services.Bluetooth.enabled : false
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: String(modelData.title)
                                    function activate() {
                                        if (root.state) {
                                            root.state.hubIndex = index;
                                            root.state.openFlyout(modelData.id);
                                        }
                                    }
                                    Keys.onReturnPressed: activate()
                                    Keys.onSpacePressed: activate()
                                    border.color: activeFocus ? Theme.accent : "transparent"
                                    width: (parent.width - 16) / 3
                                    height: 58
                                    radius: 14
                                    color: active ? Theme.accentContainer : controlMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                    scale: controlMouse.pressed ? 0.97 : 1
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 110
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }
                                    }
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 7
                                        Icon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            glyph: String(modelData.icon)
                                            size: 17
                                            tint: active ? Theme.accentContainerInk : Theme.fg
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: String(modelData.title)
                                            color: active ? Theme.accentContainerInk : Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                    MouseArea {
                                        id: controlMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.activate()
                                    }
                                }
                            }
                        }
                        Row {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: [
                                    {
                                        title: "Settings",
                                        icon: "\uf013",
                                        kind: "settings"
                                    },
                                    {
                                        title: "Wallpaper",
                                        icon: "\uf03e",
                                        kind: "wallpaper"
                                    }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (controlsColumn.width - 8) / 2
                                    height: 34
                                    radius: 10
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.title
                                    function activate() {
                                        if (modelData.kind === "wallpaper")
                                            root.wallpapersRequested();
                                        else if (root.state)
                                            root.state.openFlyout("settings");
                                    }
                                    Keys.onReturnPressed: activate()
                                    Keys.onSpacePressed: activate()
                                    color: utilityMouse.pressed ? Theme.surfacePress : utilityMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                                    border.color: activeFocus ? Theme.accent : "transparent"
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Icon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            glyph: modelData.icon
                                            size: 12
                                            tint: Theme.muted
                                        }
                                        Text {
                                            text: modelData.title
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
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
                        Row {
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: ["Launcher", "Limits", "Clipboard"]
                                delegate: Rectangle {
                                    required property string modelData
                                    width: (controlsColumn.width - 16) / 3
                                    height: 34
                                    radius: 10
                                    color: Theme.surface
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "  ›"
                                        color: Theme.fg
                                        font.pixelSize: 11
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (!root.state)
                                                return;
                                            if (modelData === "Launcher")
                                                root.state.openRunner();
                                            else
                                                root.state.hubTab = modelData;
                                        }
                                    }
                                }
                            }
                        }
                        MediaSurface {
                            visible: !dashboardRow.showSides
                            width: parent.width
                            height: visible ? 320 : 0
                            state: root.state
                        }
                        Loader {
                            visible: !dashboardRow.showSides
                            width: parent.width
                            height: visible ? 320 : 0
                            active: visible && root.tab === "Dashboard"
                            source: "NotificationCenter.qml"
                            onLoaded: if (item && item.state !== undefined)
                                item.state = root.state
                        }
                        Row {
                            width: parent.width
                            spacing: 12
                            Repeater {
                                model: [
                                    {
                                        icon: Services.System.batteryIcon,
                                        label: Services.System.batteryReady ? "Battery " + Services.System.batteryPercent + "%" : "AC power"
                                    },
                                    {
                                        icon: Services.System.powerProfile === 0 ? "\uf06c" : Services.System.powerProfile === 2 ? "\uf0e7" : "\uf24e",
                                        label: Services.System.powerProfileText
                                    }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: statusRow.implicitWidth + 12
                                    height: 28
                                    radius: 8
                                    color: statusMouse.containsMouse || activeFocus ? Theme.surfaceHover : "transparent"
                                    activeFocusOnTab: true
                                    Accessible.role: Accessible.Button
                                    Accessible.name: modelData.label + ", power details"
                                    function activate() {
                                        if (root.state)
                                            root.state.openFlyout("battery");
                                    }
                                    Keys.onReturnPressed: activate()
                                    Keys.onSpacePressed: activate()
                                    Row {
                                        id: statusRow
                                        anchors.centerIn: parent
                                        spacing: 7
                                        Icon {
                                            glyph: modelData.icon
                                            size: 12
                                            tint: Theme.muted
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.label
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                    MouseArea {
                                        id: statusMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: parent.activate()
                                    }
                                }
                            }
                        }
                    }
                }
                Loader {
                    visible: parent.showSides
                    width: parent.notificationsWidth
                    height: parent.height
                    active: root.tab === "Dashboard" && visible
                    source: "NotificationCenter.qml"
                    onLoaded: if (item && item.state !== undefined)
                        item.state = root.state
                }
            }
            Loader {
                id: page
                anchors.fill: parent
                active: root.tab !== "Dashboard"
                source: root.tab === "Media" ? "MediaPage.qml" : root.tab === "Performance" ? "PerformanceSurface.qml" : root.tab === "Limits" ? "UsageSurface.qml" : root.tab === "Clipboard" ? "ClipboardSurface.qml" : root.tab === "Calendar" ? "CalendarSurface.qml" : root.tab === "Tray" ? "TraySurface.qml" : ""
                onLoaded: {
                    if (item && item.state !== undefined)
                        item.state = root.state;
                    if (item && item.refresh)
                        item.refresh();
                    if (item && (root.tab === "Clipboard" || root.tab === "Calendar"))
                        item.forceActiveFocus();
                    if (item && item.closeRequested)
                        item.closeRequested.connect(function () {
                            if (root.state)
                                root.state.collapse();
                        });
                }
            }
            Rectangle {
                visible: root.tab === "Limits" || root.tab === "Clipboard" || root.tab === "Calendar" || root.tab === "Tray"
                anchors.right: parent.right
                anchors.top: parent.top
                width: 65
                // Fit the page's title row without covering its search field.
                height: 22
                radius: 8
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Back to dashboard"
                color: backMouse.pressed ? Theme.surfacePress : backMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                border.color: activeFocus ? Theme.accent : "transparent"
                function goBack() {
                    if (root.state)
                        root.state.selectTab("Dashboard");
                }
                Keys.onReturnPressed: goBack()
                Keys.onSpacePressed: goBack()
                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    color: Theme.fg
                }
                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.goBack()
                }
            }
        }
    }
}
