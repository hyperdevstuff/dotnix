import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "components" as Components
import "flyouts"
import "services" as Services

// The island. One morphing main surface (pill / OSD / hub / auth), a side
// flyout that opens to the right of the centered hub, and a media card that
// is the only surface allowed to grow downward.
Item {
    id: root

    // Injected
    property var state: null
    property var polkitFlow: null

    // Style
    property bool notchMode: Theme.notchMode

    readonly property string mode: state ? state.mode : "idle"
    readonly property bool interactive: state ? state.interactive : false
    readonly property bool flyoutOpen: mode === "flyout"
    readonly property bool mediaOpen: mode === "media"
    readonly property bool authOpen: mode === "auth"
    readonly property bool pillLike: mode === "idle" || mode === "osd"

    // Geometry. The item is always hub-centred; shell.qml positions it with
    // x = (screenWidth - Theme.hubW) / 2 so the hub does not move when a
    // flyout opens.
    readonly property int hubW: Theme.hubW
    readonly property int hubH: Theme.hubH
    readonly property int flyoutW: Theme.flyoutW
    readonly property int flyoutH: Theme.flyoutH
    readonly property int mediaW: Theme.mediaW
    readonly property int mediaH: Theme.mediaH
    readonly property int flyoutGap: Theme.gap

    width: hubW + (flyoutOpen ? flyoutGap + flyoutW : 0)
    height: {
        const mediaHeight = mediaOpen ? hubH + flyoutGap + mediaH : hubH;
        const flyoutHeight = flyoutOpen ? flyoutH : hubH;
        const authHeight = mode === "auth" ? Theme.authH : hubH;
        return Math.max(hubH, mediaHeight, flyoutHeight, authHeight);
    }

    Behavior on width { NumberAnimation { duration: Motion.glide; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: Motion.glide; easing.type: Easing.OutCubic } }

    // ----------------------------------------------------------- main surface
    readonly property real targetW: {
        if (mode === "idle") return Theme.pillW;
        if (mode === "osd") return Theme.osdW;
        if (mode === "auth") return Theme.authW;
        return hubW;
    }
    readonly property real targetH: {
        if (mode === "idle") return Theme.pillH;
        if (mode === "osd") return Theme.osdH;
        if (mode === "auth") return Theme.authH;
        return hubH;
    }
    readonly property real targetX: (hubW - targetW) / 2

    property real surfaceW: targetW
    property real surfaceH: targetH
    property real surfaceX: targetX

    Behavior on surfaceW { NumberAnimation { duration: Motion.glide; easing.type: Easing.OutCubic } }
    Behavior on surfaceH { NumberAnimation { duration: Motion.glide; easing.type: Easing.OutCubic } }
    Behavior on surfaceX { NumberAnimation { duration: Motion.glide; easing.type: Easing.OutCubic } }

    onTargetWChanged: surfaceW = targetW
    onTargetHChanged: surfaceH = targetH
    onTargetXChanged: surfaceX = targetX
    Component.onCompleted: { surfaceW = targetW; surfaceH = targetH; surfaceX = targetX; }

    // ---------------------------------------------------------- mask geometry
    readonly property bool flyoutMaskOn: flyoutItem.visible && flyoutItem.opacity > 0.08
    readonly property bool mediaMaskOn: mediaItem.visible && mediaItem.opacity > 0.08

    readonly property real maskX: surface.x
    readonly property real maskY: surface.y
    readonly property real maskW: surface.width
    readonly property real maskH: surface.height

    readonly property bool panel2On: flyoutMaskOn || mediaMaskOn
    readonly property real mask2X: flyoutMaskOn ? flyoutItem.x : (mediaMaskOn ? mediaItem.x : 0)
    readonly property real mask2Y: flyoutMaskOn ? flyoutItem.y : (mediaMaskOn ? mediaItem.y : 0)
    readonly property real mask2W: flyoutMaskOn ? flyoutItem.width : (mediaMaskOn ? mediaItem.width : 0)
    readonly property real mask2H: flyoutMaskOn ? flyoutItem.height : (mediaMaskOn ? mediaItem.height : 0)

    readonly property bool blurOn: mode === "hub" || mode === "flyout"
        || mode === "media" || mode === "auth"
    readonly property real blurX: maskX
    readonly property real blurY: maskY
    readonly property real blurW: maskW
    readonly property real blurH: maskH
    readonly property bool blur2On: panel2On
    readonly property real blur2X: mask2X
    readonly property real blur2Y: mask2Y
    readonly property real blur2W: mask2W
    readonly property real blur2H: mask2H

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
            attachTop: root.notchMode && root.mode !== "auth"
            panelRadius: root.pillLike ? Theme.radiusPill : Theme.radius
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
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.state && root.state.mode === "idle") root.state.openHub()
                    onWheel: (wheel) => {
                        const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        Services.System.setVolume(Services.System.volume + step);
                        if (root.state) root.state.showOsd("volume");
                    }
                }
            }

            Components.OsdSurface {
                anchors.fill: parent
                state: root.state
                opacity: root.mode === "osd" ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            }

            Components.HubSurface {
                anchors.fill: parent
                state: root.state
                opacity: (root.mode === "hub" || root.mode === "flyout" || root.mode === "media") ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            }

            Item {
                anchors.fill: parent
                opacity: root.mode === "auth" ? 1 : 0
                visible: opacity > 0.001
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                Components.AuthCard {
                    anchors.fill: parent
                    flow: root.polkitFlow
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
            startX: 0; startY: 0
            PathLine { x: Theme.earSize; y: 0 }
            PathLine { x: Theme.earSize; y: Theme.earSize }
            PathArc {
                x: 0; y: 0
                radiusX: Theme.earSize; radiusY: Theme.earSize
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
            startX: 0; startY: 0
            PathLine { x: Theme.earSize; y: 0 }
            PathArc {
                x: 0; y: Theme.earSize
                radiusX: Theme.earSize; radiusY: Theme.earSize
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
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
        function onFlyoutKindChanged() { root.rememberFlyout(); }
    }

    Item {
        id: flyoutItem
        x: root.hubW + root.flyoutGap + (root.flyoutOpen ? 0 : -8)
        y: 0
        width: root.flyoutW
        height: root.flyoutH
        opacity: root.flyoutOpen ? 1 : 0
        visible: opacity > 0.001
        scale: root.flyoutOpen ? 1 : 0.985
        transformOrigin: Item.Left

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on x { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }

        Loader {
            id: flyoutLoader
            anchors.fill: parent
            active: root.flyoutOpen || flyoutItem.opacity > 0.02
            sourceComponent: {
                switch (root.lastFlyoutKind) {
                case "bluetooth": return bluetoothComponent;
                case "audio": return audioComponent;
                case "battery": return batteryComponent;
                case "display": return displayComponent;
                case "session": return sessionComponent;
                case "settings": return settingsComponent;
                default: return wifiComponent;
                }
            }
            onLoaded: {
                if (item && item.back)
                    item.back.connect(function () { if (root.state) root.state.back(); });
            }
        }
    }

    Component { id: wifiComponent; WifiFlyout {} }
    Component { id: bluetoothComponent; BluetoothFlyout {} }
    Component { id: audioComponent; AudioFlyout {} }
    Component { id: batteryComponent; BatteryFlyout {} }
    Component { id: displayComponent; DisplayFlyout {} }
    Component { id: sessionComponent; SessionFlyout {} }
    Component { id: settingsComponent; SettingsFlyout {} }

    // ------------------------------------------------------------------ media
    Item {
        id: mediaItem
        x: Math.round((root.hubW - root.mediaW) / 2)
        y: root.hubH + root.flyoutGap
        width: root.mediaW
        height: root.mediaH
        opacity: root.mediaOpen ? 1 : 0
        visible: opacity > 0.001
        scale: root.mediaOpen ? 1 : 0.985
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Components.MediaSurface {
            anchors.fill: parent
            state: root.state
        }
    }

    // ---------------------------------------------------------------- clock
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // --------------------------------------------------------------- keyboard
    focus: root.interactive

    Keys.onEscapePressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "auth") {
            if (root.polkitFlow) root.polkitFlow.cancelAuthenticationRequest();
            else root.state.back();
        } else {
            root.state.back();
        }
        event.accepted = true;
    }

    Keys.onLeftPressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "hub") { root.state.moveHubFocus(-1, 0); event.accepted = true; }
        else if (root.state.mode === "media") { Services.Media.previous(); event.accepted = true; }
    }
    Keys.onRightPressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "hub") { root.state.moveHubFocus(1, 0); event.accepted = true; }
        else if (root.state.mode === "media") { Services.Media.next(); event.accepted = true; }
    }
    Keys.onUpPressed: (event) => {
        if (root.state && root.state.mode === "hub") { event.accepted = true; }
    }
    Keys.onDownPressed: (event) => {
        if (root.state && root.state.mode === "hub") { event.accepted = true; }
    }
    Keys.onReturnPressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "hub") { root.state.activateHubIndex(root.state.hubIndex); event.accepted = true; }
        else if (root.state.mode === "media") { Services.Media.playPause(); event.accepted = true; }
    }
    Keys.onEnterPressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "hub") { root.state.activateHubIndex(root.state.hubIndex); event.accepted = true; }
        else if (root.state.mode === "media") { Services.Media.playPause(); event.accepted = true; }
    }
    Keys.onSpacePressed: (event) => {
        if (root.state && root.state.mode === "media") {
            Services.Media.playPause();
            event.accepted = true;
        }
    }
    Keys.onPressed: (event) => {
        if (!root.state) return;
        if (root.state.mode === "hub") {
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
