import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "components" as Components
import "services" as Services

// Native session lock. Quickshell's WlSessionLock covers every screen and
// PamContext authenticates against the dedicated `quickshell` PAM service.
// This replaces swaylock as the primary locker; swaylock stays installed as a
// recovery fallback.
//
// The lock has two pages, like a phone lock screen:
//
//   page 1  ambient clock on the wallpaper. Any key, click or scroll advances.
//   page 2  long date, account, password field, network/battery status and a
//           read-only sidebar with the current activity and notifications.
//
// Page 1 never asks for the password and page 2 never type-aheads: the first
// key press only advances the page, so a password cannot leak into the field
// before the user can see where they are typing.
Item {
    id: lockRoot

    property bool locked: false
    // false = ambient clock, true = authentication page.
    property bool promptPage: false
    property string password: ""
    property string pendingPassword: ""
    property string errorText: ""
    property bool authenticating: false
    property string pamConfig: "quickshell"
    readonly property string userName: Quickshell.env("USER") || "user"

    // The lock surface draws its own wallpaper; no wallpaper daemon is
    // involved. Override with NOTCHD_LOCK_WALLPAPER for a different image.
    readonly property string wallpaper: Quickshell.env("NOTCHD_LOCK_WALLPAPER")
        || (Quickshell.env("HOME") + "/Pictures/walls/dotted.png")

    // Lock chrome is deliberately monochrome and light, independent of the
    // app palette: the session is not the place to flash a white sheet in
    // light mode. `ink` is the only text colour; status colours are allowed.
    readonly property color ink: "#f5f5f5"
    readonly property color inkSoft: "#b8b8bf"
    readonly property color hairline: Qt.rgba(1, 1, 1, 0.16)
    readonly property color glass: Qt.rgba(1, 1, 1, 0.07)
    readonly property color glassHover: Qt.rgba(1, 1, 1, 0.12)

    signal unlocked()

    SystemClock {
        id: lockClock
        precision: SystemClock.Minutes
    }

    function resetState() {
        password = "";
        pendingPassword = "";
        errorText = "";
        authenticating = false;
        if (pam.active) pam.abort();
    }

    function lock() {
        resetState();
        promptPage = false;
        locked = true;
        // Keep cards alive for the lock-sidebar; they resume expiry on unlock.
        Services.Notifications.paused = true;
    }

    function unlock() {
        locked = false;
        promptPage = false;
        resetState();
        Services.Notifications.paused = false;
        unlocked();
    }

    function enterPrompt() {
        if (!locked || promptPage) return;
        promptPage = true;
    }

    function leavePrompt() {
        if (!promptPage) return;
        promptPage = false;
        password = "";
        errorText = "";
    }

    function submit() {
        if (!locked || authenticating) return;
        if (password.length === 0) return;
        pendingPassword = password;
        password = "";
        errorText = "";
        authenticating = true;
        if (pam.active) pam.abort();
        if (!pam.start()) {
            authenticating = false;
            pendingPassword = "";
            errorText = "Authentication is unavailable";
        }
    }

    function clearPassword() {
        password = "";
        errorText = "";
    }

    PamContext {
        id: pam
        config: lockRoot.pamConfig
        onResponseRequiredChanged: {
            if (!responseRequired || !lockRoot.authenticating) return;
            const response = lockRoot.pendingPassword;
            if (response.length === 0) {
                // PAM asked for a second response (for example a retry after a
                // failed password). Abort instead of sending an empty answer.
                pam.abort();
                lockRoot.authenticating = false;
                lockRoot.errorText = "Incorrect password";
                return;
            }
            lockRoot.pendingPassword = "";
            pam.respond(response);
        }

        onCompleted: (result) => {
            lockRoot.authenticating = false;
            if (result === PamResult.Success) {
                lockRoot.unlock();
            } else {
                lockRoot.password = "";
                lockRoot.errorText = result === PamResult.MaxTries
                    ? "Too many attempts. Try again later."
                    : "Incorrect password";
            }
        }

        onError: (error) => {
            lockRoot.authenticating = false;
            lockRoot.password = "";
            lockRoot.errorText = "Authentication failed to start";
        }

        onPamMessage: {
            if (pam.messageIsError && pam.message.length > 0)
                lockRoot.errorText = pam.message;
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: lockRoot.locked

        WlSessionLockSurface {
            id: surface
            color: "#080808"

            Rectangle {
                anchors.fill: parent
                color: "#0a0a0a"

                // ------------------------------------------------- wallpaper
                Image {
                    id: wallpaper
                    anchors.fill: parent
                    source: "file://" + lockRoot.wallpaper
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                    scale: lockRoot.promptPage ? 1.035 : 1.0
                    Behavior on scale {
                        NumberAnimation { duration: 650; easing.type: Easing.OutCubic }
                    }
                }

                // Base scrim. Page 2 darkens further so the auth column and
                // the sidebar read before the pattern does.
                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: lockRoot.promptPage ? 0.56 : 0.30
                    Behavior on opacity {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }
                }

                // Top and bottom scrims keep the date and status corners
                // legible without flattening the middle of the wallpaper.
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.42) }
                        GradientStop { position: 0.30; color: Qt.rgba(0, 0, 0, 0.0) }
                        GradientStop { position: 0.66; color: Qt.rgba(0, 0, 0, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.48) }
                    }
                }

                // ------------------------------------------------- page 1
                Item {
                    id: clockPage
                    anchors.fill: parent
                    opacity: lockRoot.promptPage ? 0 : 1
                    transform: Translate {
                        y: lockRoot.promptPage ? -26 : 0
                        Behavior on y {
                            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Text {
                        id: bigTime
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -Math.round(parent.height * 0.02)
                        text: Qt.formatTime(lockClock.date, "HH:mm")
                        color: lockRoot.ink
                        font.family: Theme.fontFamily
                        font.pixelSize: Math.round(Math.min(172, Math.max(88, parent.height * 0.135)))
                        font.weight: Font.Light
                        font.letterSpacing: -Math.round(font.pixelSize * 0.035)
                        textFormat: Text.PlainText
                    }

                    // The whole page is the "any key" target. It sits above
                    // the clock so a click anywhere advances too.
                    Item {
                        id: clockFocus
                        anchors.fill: parent
                        focus: !lockRoot.promptPage
                        enabled: !lockRoot.promptPage

                        Keys.onPressed: (event) => {
                            lockRoot.enterPrompt();
                            event.accepted = true;
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.AllButtons
                            cursorShape: Qt.PointingHandCursor
                            onClicked: lockRoot.enterPrompt()
                        }

                        WheelHandler {
                            onWheel: lockRoot.enterPrompt()
                        }

                        Component.onCompleted: forceActiveFocus()
                    }
                }

                // ------------------------------------------------- page 2
                Item {
                    id: authPage
                    anchors.fill: parent
                    opacity: lockRoot.promptPage ? 1 : 0
                    enabled: lockRoot.promptPage
                    transform: Translate {
                        y: lockRoot.promptPage ? 0 : 16
                        Behavior on y {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                    }

                    // Clicking anywhere that is not a control returns focus to
                    // the password field. Controls are declared later and win.
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        onClicked: {
                            if (lockRoot.promptPage)
                                Qt.callLater(() => passwordInput.forceActiveFocus());
                        }
                    }

                    // -------------------------------------------- long date
                    ColumnLayout {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: Math.round(parent.height * 0.075)
                        width: Math.min(parent.width - 96, 640)
                        spacing: 7

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDate(lockClock.date, "dddd, d MMMM yyyy")
                            color: lockRoot.ink
                            font.family: Theme.fontFamily
                            font.pixelSize: Math.round(Math.min(32, Math.max(22, authPage.width * 0.018)))
                            font.weight: Font.Light
                            font.letterSpacing: 0.2
                            horizontalAlignment: Text.AlignHCenter
                            textFormat: Text.PlainText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatTime(lockClock.date, "HH:mm")
                            color: lockRoot.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.letterSpacing: 2.4
                            horizontalAlignment: Text.AlignHCenter
                            textFormat: Text.PlainText
                        }
                    }

                    // ----------------------------------------------- auth
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: Math.min(320, parent.width - 96)
                        spacing: 13

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 58
                            radius: 29
                            color: lockRoot.glass
                            border.width: 1
                            border.color: lockRoot.hairline

                            Text {
                                anchors.centerIn: parent
                                text: lockRoot.userName.length > 0
                                    ? lockRoot.userName.charAt(0).toUpperCase() : "?"
                                color: lockRoot.ink
                                font.family: Theme.fontFamily
                                font.pixelSize: 22
                                font.weight: Font.DemiBold
                                textFormat: Text.PlainText
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: lockRoot.userName
                                color: lockRoot.ink
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            Text {
                                Layout.fillWidth: true
                                text: lockRoot.authenticating ? "Authenticating…" : "Locked"
                                color: lockRoot.inkSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                horizontalAlignment: Text.AlignHCenter
                                textFormat: Text.PlainText
                            }
                        }

                        // ------------------------------------ password
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            radius: Theme.radiusControl
                            color: lockRoot.glass
                            border.width: 1
                            border.color: passwordInput.activeFocus ? Qt.rgba(1, 1, 1, 0.55) : lockRoot.hairline

                            TextInput {
                                id: passwordInput
                                anchors.left: parent.left
                                anchors.right: submit.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 15
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: lockRoot.ink
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                echoMode: TextInput.Password
                                passwordCharacter: "•"
                                selectionColor: lockRoot.ink
                                selectedTextColor: "#0a0a0a"
                                clip: true
                                focus: false
                                enabled: !lockRoot.authenticating

                                onTextChanged: {
                                    if (lockRoot.password !== text)
                                        lockRoot.password = text;
                                }

                                onAccepted: lockRoot.submit()

                                Keys.onEscapePressed: (event) => {
                                    if (lockRoot.password.length > 0)
                                        lockRoot.clearPassword();
                                    else
                                        lockRoot.leavePrompt();
                                    event.accepted = true;
                                }
                            }

                            Connections {
                                target: lockRoot
                                function onPasswordChanged() {
                                    if (passwordInput.text !== lockRoot.password)
                                        passwordInput.text = lockRoot.password;
                                }
                                function onAuthenticatingChanged() {
                                    if (!lockRoot.authenticating && lockRoot.promptPage)
                                        Qt.callLater(() => passwordInput.forceActiveFocus());
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                anchors.verticalCenter: parent.verticalCenter
                                visible: passwordInput.text.length === 0
                                text: lockRoot.authenticating ? "Waiting for authentication…" : "Password"
                                color: lockRoot.inkSoft
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                textFormat: Text.PlainText
                            }

                            Rectangle {
                                id: submit
                                width: 30
                                height: 30
                                radius: 15
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property bool ready: !lockRoot.authenticating
                                    && lockRoot.password.length > 0

                                color: ready
                                    ? (submitMouse.containsMouse ? Qt.lighter(lockRoot.ink, 1.08) : lockRoot.ink)
                                    : Qt.rgba(1, 1, 1, 0.09)

                                Components.Icon {
                                    anchors.centerIn: parent
                                    glyph: lockRoot.authenticating ? "\uf110" : "\uf061"
                                    size: 12
                                    tint: submit.ready ? "#0a0a0a" : lockRoot.inkSoft
                                }

                                MouseArea {
                                    id: submitMouse
                                    anchors.fill: parent
                                    enabled: submit.ready
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        passwordInput.forceActiveFocus();
                                        lockRoot.submit();
                                    }
                                }
                            }
                        }

                        // Reserve the error line so a failed attempt does not
                        // move the password field under the pointer.
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.fontLabel + 4

                            Text {
                                anchors.centerIn: parent
                                width: parent.width
                                visible: lockRoot.errorText.length > 0
                                text: lockRoot.errorText
                                color: "#fca5a5"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                textFormat: Text.PlainText
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Enter to unlock · Esc clears"
                            color: lockRoot.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            horizontalAlignment: Text.AlignHCenter
                            opacity: 0.8
                            textFormat: Text.PlainText
                        }
                    }

                    // ------------------------------------- lock sidebar
                    Components.LockSidebar {
                        anchors.right: parent.right
                        anchors.rightMargin: 32
                        anchors.top: parent.top
                        anchors.topMargin: Math.round(parent.height * 0.075)
                        width: 300
                        height: Math.min(implicitHeight, parent.height - anchors.topMargin - 92)
                        visible: parent.width >= 1240
                            && (Services.Media.hasPlayer || Services.Notifications.count > 0)
                    }

                    // ------------------------------------ status corners
                    RowLayout {
                        anchors.left: parent.left
                        anchors.leftMargin: 32
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 28
                        spacing: 7

                        Components.Icon {
                            Layout.alignment: Qt.AlignVCenter
                            glyph: !Services.Network.available
                                || !Services.Network.wifiEnabled
                                || !Services.Network.hardwareEnabled
                                ? "\uf05e" : "\uf1eb"
                            size: 13
                            tint: lockRoot.inkSoft
                        }

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: Services.Network.wiredConnected
                                ? "Ethernet" : Services.Network.statusText
                            color: lockRoot.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            textFormat: Text.PlainText
                        }
                    }

                    RowLayout {
                        anchors.right: parent.right
                        anchors.rightMargin: 32
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 28
                        spacing: 7
                        visible: Services.System.batteryReady

                        Text {
                            Layout.alignment: Qt.AlignVCenter
                            text: Services.System.batteryPercent + "%"
                            color: Services.System.batteryPercent <= 15
                                && !Services.System.batteryCharging
                                ? "#fca5a5" : lockRoot.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            textFormat: Text.PlainText
                        }

                        Components.Icon {
                            Layout.alignment: Qt.AlignVCenter
                            glyph: Services.System.batteryIcon
                            size: 14
                            tint: Services.System.batteryPercent <= 15
                                && !Services.System.batteryCharging
                                ? "#fca5a5" : lockRoot.inkSoft
                        }
                    }

                    // Focus follows the page. This lives inside the surface
                    // so it binds to this screen's password field.
                    Connections {
                        target: lockRoot
                        function onPromptPageChanged() {
                            if (lockRoot.promptPage)
                                Qt.callLater(() => passwordInput.forceActiveFocus());
                            else
                                Qt.callLater(() => clockFocus.forceActiveFocus());
                        }
                        function onLockedChanged() {
                            if (!lockRoot.locked) return;
                            if (lockRoot.promptPage)
                                Qt.callLater(() => passwordInput.forceActiveFocus());
                            else
                                Qt.callLater(() => clockFocus.forceActiveFocus());
                        }
                    }
                }
            }
        }
    }
}
