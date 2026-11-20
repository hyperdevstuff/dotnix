import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "components" as Components
import "flyouts"
import "services" as Services
import "vendor/dux" as Dux

// One centered spring-driven surface for the pill, live activities, hub
// and authentication. Details are hosted in the center of the expanded hub.
Item {
    id: root

    // Injected
    property var state: null
    property var polkitFlow: null
    property var screen: null
    signal wallpapersRequested

    // Style
    property bool notchMode: Theme.notchMode

    readonly property string mode: state ? state.mode : "idle"
    readonly property bool interactive: state ? state.interactive : false
    readonly property bool flyoutOpen: mode === "flyout"
    readonly property bool mediaOpen: mode === "media"
    readonly property bool authOpen: mode === "auth"
    readonly property bool pillLike: mode === "idle" || mode === "osd"

    // A live activity only earns space in the pill, never an automatic
    // expansion. The compact indicator is passive: it updates in place and
    // opens the expanded media card only when clicked.
    readonly property bool mediaActive: Services.Media.hasPlayer

    // Corner system. The hub and flyout share one continuous edge: when the
    // flyout is open the hub's right corners and the flyout's left corners are
    // square, so the pair reads as a single surface instead of two cards.
    readonly property real targetRadius: pillLike ? Theme.radiusPill : Theme.radius
    readonly property real surfaceRadius: shapeMotion.currentBottomLeftRadius
    readonly property bool squareTop: notchMode && mode !== "auth"
    readonly property real maskTopLeft: shapeMotion.currentTopLeftRadius
    readonly property real maskTopRight: shapeMotion.currentTopRightRadius
    readonly property real maskBottomLeft: shapeMotion.currentBottomLeftRadius
    readonly property real maskBottomRight: shapeMotion.currentBottomRightRadius
    readonly property real mask2TopLeft: flyoutOpen ? 0 : Theme.radius
    readonly property real mask2TopRight: flyoutOpen ? (notchMode ? 0 : Theme.radius) : Theme.radius
    readonly property real mask2BottomLeft: flyoutOpen ? 0 : Theme.radius
    readonly property real mask2BottomRight: Theme.radius

    // Geometry. The item is always hub-centred; shell.qml positions it with
    // x = (screenWidth - hubW) / 2 so the hub does not move when a flyout
    // opens. Theme.hubW is a floor: the surface grows when the chip values or
    // a visible now-playing chip need more room, so nothing ever clips.
    readonly property real minHubW: hubSurface ? hubSurface.requiredWidth : Theme.hubW
    readonly property int hubW: Math.max(1, Math.min(Math.ceil(Math.max(Theme.hubW, minHubW)), screen ? screen.width - 20 : 980))
    readonly property int hubH: Math.max(1, Math.min(Theme.hubH, screen ? screen.height - Theme.topGap - 10 : 440))
    readonly property int flyoutW: Theme.flyoutW
    readonly property int flyoutH: Theme.flyoutH
    readonly property int mediaW: Theme.mediaW
    readonly property int mediaH: Theme.mediaH

    // The flyout is flush with the hub's right edge; media is the only surface
    // that grows downward, with a small gap.
    readonly property int mediaGap: Theme.gap

    width: hubW
    height: {
        const mediaHeight = hubH;
        const flyoutHeight = hubH;
        const authHeight = mode === "auth" ? Theme.authH : hubH;
        return Math.max(hubH, mediaHeight, flyoutHeight, authHeight);
    }

    Behavior on width {
        NumberAnimation {
            duration: Motion.glide
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Motion.glide
            easing.type: Easing.OutCubic
        }
    }

    // ----------------------------------------------------------- main surface
    readonly property real targetW: {
        if (mode === "idle")
            return Theme.pillW + (mediaActive ? Theme.pillMediaExtra : 0);
        if (mode === "osd")
            return state && state.osdKind === "workspace" ? 160 : Theme.osdW;
        if (mode === "auth")
            return Theme.authW;
        return hubW;
    }
    readonly property real targetH: {
        if (mode === "idle")
            return Theme.pillH;
        if (mode === "osd")
            return Theme.osdH;
        if (mode === "auth")
            return Theme.authH;
        return hubH;
    }
    readonly property real targetX: (hubW - targetW) / 2

    readonly property real surfaceW: shapeMotion.currentWidth
    readonly property real surfaceH: shapeMotion.currentHeight
    readonly property real surfaceX: (hubW - surfaceW) / 2
    readonly property bool surfaceMoving: shapeMotion.running
    // The fixed-size hub is clipped by the surface; its reveal follows geometry
    // in both directions, including interrupted transitions.
    readonly property real hubReveal: Math.max(0, Math.min(1,
        (surfaceH - Theme.osdH) / Math.max(1, hubH - Theme.osdH)))
    readonly property var shapeTarget: ({
        width: targetW, height: targetH, offsetAlong: 0, offsetCross: 0,
        topLeftRadius: squareTop ? 0 : targetRadius,
        topRightRadius: squareTop ? 0 : targetRadius,
        bottomLeftRadius: targetRadius, bottomRightRadius: targetRadius
    })
    property bool shapeReady: false
    onShapeTargetChanged: {
        if (shapeReady)
            shapeMotion.setTarget(shapeTarget);
    }
    Component.onCompleted: {
        shapeMotion.snapTo(shapeTarget);
        shapeReady = true;
    }
    Dux.VectorSpringMotion {
        id: shapeMotion
        stiffness: 900
        damping: 60
        reducedMotion: Motion.reduceMotion
    }

    // ---------------------------------------------------------- mask geometry
    readonly property bool flyoutMaskOn: false
    readonly property bool mediaMaskOn: false

    readonly property real maskX: surface.x
    readonly property real maskY: surface.y
    readonly property real maskW: surface.width
    readonly property real maskH: surface.height

    readonly property real mask2X: flyoutMaskOn ? flyoutItem.x : 0
    readonly property real mask2Y: flyoutMaskOn ? flyoutItem.y : 0
    readonly property real mask2W: flyoutMaskOn ? flyoutItem.width : 0
    readonly property real mask2H: flyoutMaskOn ? flyoutItem.height : 0

    // ---------------------------------------------------------------- surface
    Item {
        id: surface
        x: root.surfaceX
        y: 0
        width: root.surfaceW
        height: root.surfaceH
        clip: false

        Components.Panel {
            anchors.fill: parent
            visible: root.mode !== "auth"
            panelRadius: root.surfaceRadius
            cornerTopLeft: root.maskTopLeft
            cornerTopRight: root.maskTopRight
            cornerBottomLeft: root.maskBottomLeft
            cornerBottomRight: root.maskBottomRight
        }

        Item {
            id: surfaceContent
            anchors.fill: parent
            clip: true

            // Idle / OSD share the same compact surface.
            Item {
                anchors.fill: parent
                opacity: root.mode === "idle" ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.fast
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.state && root.state.mode === "idle")
                        root.state.openHub()
                    onWheel: wheel => {
                        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        Services.System.setVolume(Services.System.volume + step);
                        if (root.state)
                            root.state.showOsd("volume");
                    }
                }

                // Compact live activity: one album-art tile (or a glyph when
                // the player has no art) plus a playing dot. It never changes
                // mode or requests focus on its own; a click opens the
                // expanded media card, which is the only media surface with
                // keyboard and transport controls.
                Item {
                    id: mediaPill
                    width: 18
                    height: 18
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    visible: opacity > 0.001
                    opacity: root.mediaActive ? 1 : 0
                    z: 1
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.fast
                        }
                    }

                    Components.Artwork {
                        anchors.fill: parent
                        artUrl: Services.Media.artUrl
                        cornerRadius: 4
                        placeholderIconSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -3
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root.state)
                            root.state.openMedia()
                    }
                }
            }

            Row {
                id: equalizer
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                visible: opacity > 0.001
                opacity: root.mode === "idle" && root.mediaActive ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 100 } }
                property int phase: 0
                Timer {
                    interval: 240
                    repeat: true
                    running: equalizer.visible && Services.Media.playing
                    onTriggered: equalizer.phase++
                }
                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        width: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        height: Services.Media.playing ? 4 + ((equalizer.phase + index * 3) % 5) * 2 : 3
                        color: Theme.accent
                        Behavior on height {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            Components.OsdSurface {
                anchors.fill: parent
                screen: root.screen
                state: root.state
                opacity: root.mode === "osd" ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.fast
                    }
                }
            }

            Components.HubSurface {
                id: hubSurface
                enabled: root.interactive && root.mode !== "auth"
                width: root.hubW
                height: root.hubH
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                state: root.state
                onWallpapersRequested: root.wallpapersRequested()
                opacity: root.mode === "auth" ? 0 : root.hubReveal
                visible: opacity > 0.001
            }

            Item {
                anchors.fill: parent
                opacity: root.mode === "auth" ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.fast
                    }
                }

                Components.AuthCard {
                    anchors.fill: parent
                    flow: root.polkitFlow
                }
            }
        }

        // Persistent centred clock. This lives on the surface, not inside any
        // mode, so the time keeps the exact same x from the pill through the
        // hub and into a side flyout. The date fades in only when there is
        // room for it; the time itself never shifts.
        Item {
            id: clockLayer
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 0
            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation {
                    duration: Motion.glide
                    easing.type: Easing.OutCubic
                }
            }
            width: Math.max(timeText.implicitWidth, dateText.implicitWidth)
            height: timeText.implicitHeight
            // In the pill only the time exists, so centre it. Once the date is
            // shown, centre the whole time+date block instead of centring the
            // time and hanging the date below it (which left a large top gap).
            property real lift: 0
            anchors.verticalCenterOffset: lift
            Behavior on lift {
                NumberAnimation {
                    duration: Motion.glide
                    easing.type: Easing.OutCubic
                }
            }
            visible: opacity > 0.001
            opacity: root.mode === "idle" ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.fast
                }
            }

            Text {
                id: timeText
                anchors.centerIn: parent
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.fg
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontDisplay
                font.weight: Font.Medium
            }

            Text {
                id: dateText
                anchors.top: timeText.bottom
                anchors.topMargin: -1
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "ddd d MMM")
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontLabel
                font.weight: Font.Medium
                opacity: root.mode === "idle" ? 0 : 1
                visible: opacity > 0.001
                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.fast
                    }
                }
            }
        }
    }

    // Concave ears for the notch style. They sit outside the surface, so they
    // are drawn without affecting the mask.
    Shape {
        visible: root.notchMode && root.mode !== "auth"
        x: surface.x - Theme.earSize
        y: 0
        width: Theme.earSize
        height: Theme.earSize
        ShapePath {
            fillColor: Theme.panel
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: Theme.earSize
                y: 0
            }
            PathLine {
                x: Theme.earSize
                y: Theme.earSize
            }
            PathArc {
                x: 0
                y: 0
                radiusX: Theme.earSize
                radiusY: Theme.earSize
                direction: PathArc.Clockwise
            }
        }
    }

    Shape {
        visible: root.notchMode && root.mode !== "auth"
        x: surface.x + surface.width
        y: 0
        width: Theme.earSize
        height: Theme.earSize
        ShapePath {
            fillColor: Theme.panel
            strokeColor: "transparent"
            startX: 0
            startY: 0
            PathLine {
                x: Theme.earSize
                y: 0
            }
            PathArc {
                x: 0
                y: Theme.earSize
                radiusX: Theme.earSize
                radiusY: Theme.earSize
                direction: PathArc.Clockwise
            }
            PathLine {
                x: 0
                y: 0
            }
        }
    }

    // ----------------------------------------------------------------- flyout
    property string lastFlyoutKind: "wifi"

    function rememberFlyout() {
        if (root.state && root.state.mode === "flyout" && root.state.flyoutKind.length > 0)
            lastFlyoutKind = root.state.flyoutKind;
    }
    onModeChanged: rememberFlyout()
    Connections {
        target: root.state
        function onFlyoutKindChanged() {
            root.rememberFlyout();
        }
    }

    Item {
        id: flyoutItem
        x: Math.round((root.hubW - width) / 2)
        y: 0
        width: Math.max(1, Math.min(root.flyoutW, root.hubW * 0.46))
        height: root.hubH
        z: 5
        opacity: root.flyoutOpen ? 1 : 0
        visible: opacity > 0.001
        scale: root.flyoutOpen ? 1 : 0.99
        transformOrigin: Item.Left

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Flickable {
            id: detailScroll
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, root.flyoutH)
            Loader {
                id: flyoutLoader
                width: parent.width
                height: detailScroll.contentHeight
                active: root.flyoutOpen || flyoutItem.opacity > 0.02
                sourceComponent: {
                    switch (root.lastFlyoutKind) {
                    case "bluetooth":
                        return bluetoothComponent;
                    case "audio":
                        return audioComponent;
                    case "battery":
                        return batteryComponent;
                    case "display":
                        return displayComponent;
                    case "session":
                        return sessionComponent;
                    case "settings":
                        return settingsComponent;
                    default:
                        return wifiComponent;
                    }
                }
                onLoaded: {
                    if (item && item.back)
                        item.back.connect(function () {
                            if (root.state)
                                root.state.back();
                        });
                }
            }
        }
    }

    Component {
        id: wifiComponent
        WifiFlyout {}
    }
    Component {
        id: bluetoothComponent
        BluetoothFlyout {}
    }
    Component {
        id: audioComponent
        AudioFlyout {}
    }
    Component {
        id: batteryComponent
        BatteryFlyout {}
    }
    Component {
        id: displayComponent
        DisplayFlyout {}
    }
    Component {
        id: sessionComponent
        SessionFlyout {}
    }
    Component {
        id: settingsComponent
        SettingsFlyout {}
    }

    // ---------------------------------------------------------------- clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // --------------------------------------------------------------- keyboard
    focus: root.state ? root.state.keyboardInteractive : false

    Keys.onEscapePressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "auth") {
            if (root.polkitFlow)
                root.polkitFlow.cancelAuthenticationRequest();
            else
                root.state.back();
        } else {
            root.state.back();
        }
        event.accepted = true;
    }

    Keys.onLeftPressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "hub" && root.state.hubTab === "Controls") {
            root.state.moveHubFocus(-1, 0);
            event.accepted = true;
        } else if (root.state.mode === "media") {
            Services.Media.previous();
            event.accepted = true;
        }
    }
    Keys.onRightPressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "hub" && root.state.hubTab === "Controls") {
            root.state.moveHubFocus(1, 0);
            event.accepted = true;
        } else if (root.state.mode === "media") {
            Services.Media.next();
            event.accepted = true;
        }
    }
    Keys.onUpPressed: event => {
        if (root.state && root.state.mode === "hub" && root.state.hubTab === "Controls") {
            event.accepted = true;
        }
    }
    Keys.onDownPressed: event => {
        if (root.state && root.state.mode === "hub" && root.state.hubTab === "Controls") {
            event.accepted = true;
        }
    }
    Keys.onReturnPressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "hub" && root.state.hubTab === "Controls") {
            root.state.activateHubIndex(root.state.hubIndex);
            event.accepted = true;
        } else if (root.state.mode === "media") {
            Services.Media.playPause();
            event.accepted = true;
        }
    }
    Keys.onEnterPressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "hub" && root.state.hubTab === "Controls") {
            root.state.activateHubIndex(root.state.hubIndex);
            event.accepted = true;
        } else if (root.state.mode === "media") {
            Services.Media.playPause();
            event.accepted = true;
        }
    }
    Keys.onSpacePressed: event => {
        if (root.state && root.state.mode === "media") {
            Services.Media.playPause();
            event.accepted = true;
        }
    }
    Keys.onPressed: event => {
        if (!root.state)
            return;
        if (root.state.mode === "hub") {
            if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                const tabs = ["Controls", "Performance", "Limits", "Clipboard"];
                const delta = (event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1;
                root.state.hubTab = tabs[(tabs.indexOf(root.state.hubTab) + delta + tabs.length) % tabs.length];
                event.accepted = true;
                return;
            }
            if (root.state.hubTab !== "Controls")
                return;
            const n = parseInt(event.text);
            if (!isNaN(n) && n >= 1 && n <= root.state.hubCount) {
                root.state.activateHubIndex(n - 1);
                event.accepted = true;
                return;
            }
            if (event.text === "m" && Services.Media.hasPlayer) {
                root.state.openMedia();
                event.accepted = true;
            } else if (event.text === "s") {
                root.state.openFlyout("settings");
                event.accepted = true;
            }
        } else if (root.state.mode === "media" && event.text === "m") {
            root.state.back();
            event.accepted = true;
        }
    }
}
