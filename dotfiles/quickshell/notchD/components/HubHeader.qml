import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

RowLayout {
    id: root
    property var state: null
    readonly property var tabs: state ? state.mainTabs : ["Dashboard", "Media", "Performance"]
    spacing: 6
    implicitHeight: 40
    Rectangle {
        id: navigation
        Layout.preferredWidth: Math.min(352, root.width * 0.58)
        Layout.maximumWidth: 352
        Layout.minimumWidth: 170
        implicitHeight: 40
        radius: 18
        color: Theme.surface
        Rectangle {
            x: 3 + Math.max(0, root.tabs.indexOf(root.state ? root.state.hubTab : "Dashboard")) * (parent.width - 6) / 3
            y: 3
            width: (parent.width - 6) / 3
            height: 34
            radius: 15
            color: Theme.accentContainer
            Behavior on x {
                enabled: root.state && root.state.animateTabChange && !Motion.reduceMotion
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }
        Row {
            anchors.fill: parent
            anchors.margins: 3
            Repeater {
                id: tabButtons
                model: root.tabs
                delegate: Item {
                    required property string modelData
                    required property int index
                    width: (navigation.width - 6) / 3
                    height: 34
                    activeFocusOnTab: true
                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData
                    function select(animate) {
                        if (root.state)
                            root.state.selectTab(modelData, animate);
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: tabMouse.pressed ? Theme.surfacePress : "transparent"
                        border.color: parent.activeFocus ? Theme.accent : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        text: navigation.width < 250 ? (modelData === "Dashboard" ? "Home" : modelData === "Performance" ? "Stats" : modelData) : modelData
                        color: root.state && root.state.hubTab === modelData ? Theme.accentContainerInk : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 12 * Theme.textScale
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.select(true);
                            parent.forceActiveFocus();
                        }
                    }
                    Keys.onReturnPressed: select(false)
                    Keys.onSpacePressed: select(false)
                    Keys.onLeftPressed: {
                        if (root.state)
                            root.state.stepTab(-1);
                        tabButtons.itemAt((index + 2) % 3).forceActiveFocus();
                    }
                    Keys.onRightPressed: {
                        if (root.state)
                            root.state.stepTab(1);
                        tabButtons.itemAt((index + 1) % 3).forceActiveFocus();
                    }
                }
            }
        }
    }
    Item {
        Layout.fillWidth: true
        Layout.minimumWidth: 0
    }
    Row {
        spacing: 2
        ActionButton {
            visible: root.width < 720
            symbol: Services.Privacy.anyActive ? "shield" : "coffee"
            tonal: true
            implicitWidth: 32
            implicitHeight: 32
            Accessible.name: "Capture activity and keep awake"
            onClicked: if (root.state)
                root.state.selectTab("Activity")
        }
        visible: Services.Privacy.anyActive || Services.KeepAwake.active
        ActionButton {
            visible: root.width >= 720 && Services.Privacy.microphoneActive
            symbol: "mic"
            tonal: true
            implicitWidth: 32
            implicitHeight: 32
            Accessible.name: "Microphone in use"
            onClicked: if (root.state)
                root.state.selectTab("Activity")
        }
        ActionButton {
            visible: root.width >= 720 && Services.Privacy.cameraActive
            symbol: "videocam"
            tonal: true
            implicitWidth: 32
            implicitHeight: 32
            Accessible.name: "Camera in use"
            onClicked: if (root.state)
                root.state.selectTab("Activity")
        }
        ActionButton {
            visible: root.width >= 720 && Services.Privacy.screenActive
            symbol: "screen_share"
            tonal: true
            implicitWidth: 32
            implicitHeight: 32
            Accessible.name: "Screen sharing active"
            onClicked: if (root.state)
                root.state.selectTab("Activity")
        }
        ActionButton {
            visible: root.width >= 720 && Services.KeepAwake.active
            symbol: "coffee"
            tonal: true
            implicitWidth: 32
            implicitHeight: 32
            Accessible.name: "Keep awake, " + Services.KeepAwake.remainingText
            onClicked: if (root.state)
                root.state.selectTab("Activity")
        }
    }
    Rectangle {
        implicitWidth: timeLabel.implicitWidth + (root.width > 580 ? dateLabel.implicitWidth + 12 : 0) + 14
        implicitHeight: 36
        radius: 12
        color: clockMouse.pressed ? Theme.surfacePress : clockMouse.containsMouse || activeFocus ? Theme.surfaceHover : "transparent"
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: Services.Time.time + ", " + Services.Time.date + ". Open calendar."
        function activate() {
            if (root.state)
                root.state.selectTab("Calendar");
        }
        Keys.onReturnPressed: activate()
        Keys.onSpacePressed: activate()
        border.color: activeFocus ? Theme.accent : "transparent"
        Row {
            anchors.centerIn: parent
            spacing: 12
            Text {
                id: timeLabel
                text: Services.Time.time
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: 14 * Theme.textScale
                font.weight: Font.DemiBold
            }
            Text {
                id: dateLabel
                visible: root.width > 580
                text: Qt.formatDate(Services.Time.now, "ddd d")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12 * Theme.textScale
                anchors.verticalCenter: parent.verticalCenter
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
    ActionButton {
        symbol: "grid_view"
        implicitWidth: 36
        implicitHeight: 36
        Accessible.name: "Background apps, " + Services.Tray.count
        onClicked: if (root.state)
            root.state.selectTab("Tray")
    }
    ActionButton {
        visible: root.width > 440 && (root.width >= 720 || (!Services.Privacy.anyActive && !Services.KeepAwake.active))
        symbol: "settings"
        implicitWidth: 36
        implicitHeight: 36
        Accessible.name: "Appearance and settings"
        onClicked: if (root.state)
            root.state.selectTab("Appearance")
    }
}
