import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

// Visuals only. The session-lock protocol and PAM stay in LockScreen.qml.
// A plain controller lets previews exercise the exact UI without locking or
// authenticating the desktop. The two pages share one password controller.
Item {
    id: root
    required property var controller
    readonly property var palette: Theme.palettes.dark || ({})
    function tone(name, fallback) {
        return palette[name] || fallback;
    }
    readonly property color ink: tone("on_surface", "#f5f0e8")
    readonly property color inkSoft: tone("on_surface_variant", "#c8c3ba")
    readonly property color accent: tone("primary", "#e4c48c")
    readonly property color accentInk: tone("on_primary", "#402d08")
    readonly property color accentContainer: tone("primary_container", "#594322")
    readonly property color accentContainerInk: tone("on_primary_container", "#ffdead")
    readonly property color field: tone("surface_container_high", "#2e2b26")
    readonly property color fieldFocused: tone("surface_container_highest", "#39362f")
    readonly property color errorInk: tone("error", "#ffb4ab")
    readonly property real clockSize: Math.round(Math.min(width * 0.32, 172, Math.max(76, height * 0.15)))
    readonly property bool compact: height < 640
    property bool pointerTransition: false
    readonly property int pageDuration: pointerTransition && !Motion.reduceMotion ? 220 : 0

    function focusPage() {
        if (!controller.locked)
            return;
        if (controller.promptPage) {
            passwordInput.forceActiveFocus();
            Qt.callLater(ensurePasswordVisible);
        } else
            clockFocus.forceActiveFocus();
    }
    function ensurePasswordVisible() {
        if (!controller.promptPage)
            return;
        const bottom = passwordField.mapToItem(authViewport.contentItem, 0, passwordField.height).y;
        authViewport.contentY = Math.max(0, Math.min(authViewport.contentHeight - authViewport.height, bottom - authViewport.height + 16));
    }
    function showPrompt(animate) {
        pointerTransition = animate;
        controller.enterPrompt();
    }
    function back(animate) {
        pointerTransition = animate;
        controller.leavePrompt();
    }
    function escapePrompt() {
        if (controller.authenticating)
            return;
        if (controller.password.length)
            controller.clearPassword();
        else
            back(false);
    }
    Component.onCompleted: {
        passwordInput.text = controller.password;
        Qt.callLater(focusPage);
    }

    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
    }
    Image {
        anchors.fill: parent
        source: root.controller.wallpaper ? "file://" + root.controller.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
        scale: root.controller.promptPage ? 1.025 : 1
        Behavior on scale {
            NumberAnimation {
                duration: root.pageDuration
                easing.type: Easing.OutCubic
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.controller.promptPage ? 0.62 : 0.32
        Behavior on opacity {
            NumberAnimation {
                duration: root.pageDuration
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(0, 0, 0, 0.28)
            }
            GradientStop {
                position: 0.45
                color: "transparent"
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0, 0, 0, 0.45)
            }
        }
    }

    Item {
        id: ambientPage
        anchors.fill: parent
        opacity: root.controller.promptPage ? 0 : 1
        enabled: !root.controller.promptPage
        Behavior on opacity {
            NumberAnimation {
                duration: root.pageDuration
            }
        }
        transform: Translate {
            y: root.controller.promptPage ? -18 : 0
            Behavior on y {
                NumberAnimation {
                    duration: root.pageDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
        Column {
            id: clockGroup
            objectName: "lockClockGroup"
            width: parent.width - 48
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.25 - height / 2
            spacing: 8
            Text {
                objectName: "lockAmbientTime"
                width: parent.width
                text: Qt.formatTime(root.controller.now, Theme.use12HourClock ? "h:mm AP" : "HH:mm")
                color: root.ink
                font.family: Theme.fontFamily
                font.pixelSize: root.clockSize
                font.weight: Font.Medium
                font.letterSpacing: -root.clockSize * 0.035
                font.features: ({
                        "tnum": 1
                    })
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 40
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
            }
            Text {
                objectName: "lockAmbientDate"
                width: parent.width
                text: Qt.formatDate(root.controller.now, "dddd, d MMMM")
                color: root.ink
                font.family: Theme.fontFamily
                font.pixelSize: Math.min(26, root.width * 0.055) * Theme.textScale
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
            }
        }
        Item {
            id: clockFocus
            objectName: "lockAmbientTarget"
            anchors.fill: parent
            focus: !root.controller.promptPage
            enabled: !root.controller.promptPage
            Keys.onPressed: event => {
                root.showPrompt(false);
                event.accepted = true;
            }
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showPrompt(true)
            }
            WheelHandler {
                onWheel: root.showPrompt(true)
            }
        }
    }

    Item {
        id: authPage
        anchors.fill: parent
        enabled: root.controller.promptPage
        opacity: root.controller.promptPage ? 1 : 0
        Keys.onEscapePressed: event => {
            root.escapePrompt();
            event.accepted = true;
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.pageDuration
            }
        }
        transform: Translate {
            y: root.controller.promptPage ? 0 : 12
            Behavior on y {
                NumberAnimation {
                    duration: root.pageDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: if (root.controller.promptPage)
                passwordInput.forceActiveFocus()
        }
        Rectangle {
            id: backButton
            objectName: "lockBack"
            x: 24
            y: 24
            width: 48
            height: 48
            radius: 24
            color: backMouse.containsMouse || activeFocus ? root.fieldFocused : "transparent"
            activeFocusOnTab: enabled
            enabled: !root.controller.authenticating
            Accessible.role: Accessible.Button
            Accessible.name: "Back to clock"
            Accessible.onPressAction: if (enabled)
                root.back(false)
            Keys.onReturnPressed: root.back(false)
            Keys.onSpacePressed: root.back(false)
            KeyNavigation.tab: passwordInput
            KeyNavigation.backtab: submit.enabled ? submit : passwordInput
            Symbol {
                anchors.centerIn: parent
                name: "arrow_back"
                size: 24
                tint: root.ink
            }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back(true)
            }
        }
        Column {
            visible: root.height >= 600
            width: Math.max(0, parent.width - 176)
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.07
            spacing: 6
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(root.controller.now, "dddd, d MMMM yyyy")
                color: root.ink
                font.family: Theme.fontFamily
                font.pixelSize: 24 * Theme.textScale
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.controller.now, Theme.use12HourClock ? "h:mm AP" : "HH:mm")
                color: root.inkSoft
                font.family: Theme.fontFamily
                font.pixelSize: 16 * Theme.textScale
                font.features: ({
                        "tnum": 1
                    })
            }
        }
        Flickable {
            id: authViewport
            objectName: "lockAuthViewport"
            anchors.fill: parent
            anchors.topMargin: root.height < 600 ? 80 : Math.round(root.height * 0.19)
            anchors.bottomMargin: 80
            contentWidth: width
            contentHeight: Math.max(height, authColumn.implicitHeight)
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            clip: true
            onHeightChanged: Qt.callLater(root.ensurePasswordVisible)
            ColumnLayout {
                id: authColumn
                objectName: "lockAuthColumn"
                width: Math.max(0, Math.min(420, authViewport.width - 48))
                x: (authViewport.width - width) / 2
                y: Math.max(0, (authViewport.height - implicitHeight) / 2)
                spacing: root.compact ? 14 : 20
                Rectangle {
                    objectName: "lockAvatar"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.compact ? 76 : 96
                    Layout.preferredHeight: width
                    radius: width / 2
                    color: root.accentContainer
                    Text {
                        anchors.centerIn: parent
                        text: root.controller.userName.charAt(0).toUpperCase() || "?"
                        color: root.accentContainerInk
                        font.family: Theme.fontFamily
                        font.pixelSize: root.compact ? 30 : 38
                        font.weight: Font.DemiBold
                        textFormat: Text.PlainText
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: root.controller.userName
                        color: root.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: 28 * Theme.textScale
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.controller.authenticating ? "Checking your password…" : "Sign in to your session"
                        color: root.inkSoft
                        font.family: Theme.fontFamily
                        font.pixelSize: 16 * Theme.textScale
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                Rectangle {
                    id: passwordField
                    objectName: "lockPasswordField"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: 20
                    color: passwordInput.activeFocus ? root.fieldFocused : root.field
                    Symbol {
                        x: 18
                        anchors.verticalCenter: parent.verticalCenter
                        name: "lock"
                        size: 24
                        tint: root.inkSoft
                    }
                    TextInput {
                        id: passwordInput
                        objectName: "lockPasswordInput"
                        anchors.left: parent.left
                        anchors.right: submit.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: 56
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: root.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: 18 * Theme.textScale
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        selectionColor: root.accentContainer
                        selectedTextColor: root.accentContainerInk
                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        clip: true
                        enabled: !root.controller.authenticating
                        Accessible.name: "Password"
                        KeyNavigation.priority: KeyNavigation.BeforeItem
                        KeyNavigation.tab: submit.enabled ? submit : backButton
                        KeyNavigation.backtab: backButton
                        onTextChanged: if (root.controller.password !== text)
                            root.controller.password = text
                        onAccepted: root.controller.submit()
                        Keys.onEscapePressed: event => {
                            root.escapePrompt();
                            event.accepted = true;
                        }
                    }
                    Text {
                        x: 56
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !passwordInput.text.length
                        text: root.controller.authenticating ? "Please wait…" : "Password"
                        color: root.inkSoft
                        font.family: Theme.fontFamily
                        font.pixelSize: 16 * Theme.textScale
                    }
                    Rectangle {
                        id: submit
                        objectName: "lockSubmit"
                        width: 48
                        height: 48
                        radius: 24
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        enabled: !root.controller.authenticating && root.controller.password.length > 0
                        activeFocusOnTab: enabled
                        color: enabled ? root.accent : root.fieldFocused
                        Accessible.role: Accessible.Button
                        Accessible.name: "Unlock session"
                        Accessible.onPressAction: if (enabled)
                            root.controller.submit()
                        Keys.onReturnPressed: root.controller.submit()
                        Keys.onSpacePressed: root.controller.submit()
                        KeyNavigation.tab: backButton
                        KeyNavigation.backtab: passwordInput
                        StateLayer {
                            radius: submit.radius
                            ink: root.accentInk
                            hovered: submitMouse.containsMouse
                            pressed: submitMouse.pressed
                            focused: submit.activeFocus
                        }
                        Symbol {
                            anchors.centerIn: parent
                            name: "arrow_back"
                            rotation: 180
                            size: 24
                            tint: submit.enabled ? root.accentInk : root.inkSoft
                            visible: !root.controller.authenticating
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: root.controller.authenticating
                            text: "…"
                            color: root.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 24
                        }
                        MouseArea {
                            id: submitMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.controller.submit()
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.ceil(42 * Theme.textScale)
                    Text {
                        id: errorLabel
                        objectName: "lockError"
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        text: root.controller.errorText
                        color: root.errorInk
                        font.family: Theme.fontFamily
                        font.pixelSize: 15 * Theme.textScale
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.controller.password.length ? "Enter to unlock · Esc to clear" : "Esc to return to the clock"
                    color: root.inkSoft
                    font.family: Theme.fontFamily
                    font.pixelSize: 14 * Theme.textScale
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
        LockSidebar {
            anchors.right: parent.right
            anchors.rightMargin: 32
            anchors.top: parent.top
            anchors.topMargin: Math.round(parent.height * 0.075)
            width: 320
            height: Math.min(implicitHeight, parent.height - anchors.topMargin - 92)
            visible: parent.width >= 1340 && root.height >= 640 && (Services.Media.hasPlayer || Services.Notifications.count > 0)
            ink: root.ink
            inkSoft: root.inkSoft
            card: root.field
        }
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            width: Math.min(320, parent.width * 0.44)
            spacing: 10
            Symbol {
                name: Services.Network.wiredConnected ? "lan" : Services.Network.wifiEnabled ? "wifi" : "wifi_off"
                size: 22
                tint: root.inkSoft
            }
            Text {
                Layout.fillWidth: true
                text: Services.Network.wiredConnected ? "Ethernet" : Services.Network.statusText
                color: root.inkSoft
                font.family: Theme.fontFamily
                font.pixelSize: 14 * Theme.textScale
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }
        RowLayout {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            spacing: 10
            visible: Services.System.batteryReady
            Text {
                text: Services.System.batteryPercent + "%"
                color: Services.System.batteryPercent <= 15 && !Services.System.batteryCharging ? root.errorInk : root.inkSoft
                font.family: Theme.fontFamily
                font.pixelSize: 14 * Theme.textScale
            }
            Icon {
                glyph: Services.System.batteryIcon
                size: 24
                tint: root.inkSoft
            }
        }
    }
    Connections {
        target: root.controller
        function onPromptPageChanged() {
            Qt.callLater(root.focusPage);
        }
        function onLockedChanged() {
            if (root.controller.locked)
                Qt.callLater(root.focusPage);
        }
        function onPasswordChanged() {
            if (passwordInput.text !== root.controller.password)
                passwordInput.text = root.controller.password;
        }
        function onAuthenticatingChanged() {
            if (!root.controller.authenticating && root.controller.promptPage)
                Qt.callLater(root.focusPage);
        }
    }
}
