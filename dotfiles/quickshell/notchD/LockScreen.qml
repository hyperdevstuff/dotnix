import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "services" as Services

// Native session lock. Quickshell's WlSessionLock covers every screen and
// PamContext authenticates against the dedicated `quickshell` PAM service.
// This replaces swaylock as the primary locker; swaylock stays installed as a
// recovery fallback.
Item {
    id: lockRoot

    property bool locked: false
    property string password: ""
    property string pendingPassword: ""
    property string errorText: ""
    property bool authenticating: false
    property string pamConfig: "quickshell"
    readonly property string userName: Quickshell.env("USER") || "user"

    signal unlocked()

    SystemClock {
        id: lockClock
        precision: SystemClock.Minutes
    }

    function lock() {
        password = "";
        pendingPassword = "";
        errorText = "";
        authenticating = false;
        if (pam.active) pam.abort();
        locked = true;
    }

    function unlock() {
        locked = false;
        password = "";
        pendingPassword = "";
        errorText = "";
        authenticating = false;
        if (pam.active) pam.abort();
        unlocked();
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
            color: "#080808"

            Rectangle {
                anchors.fill: parent
                color: "#080808"

                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Theme.dark ? "#0b0b0c" : "#f4f4f5" }
                    GradientStop { position: 0.55; color: Theme.dark ? "#0f0f10" : "#fafafa" }
                    GradientStop { position: 1.0; color: Theme.dark ? "#080808" : "#efeff1" }
                }

                // Soft glow behind the auth card.
                Rectangle {
                    width: 520
                    height: 320
                    radius: 160
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.012) : Qt.rgba(0, 0, 0, 0.01)
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(360, parent.width - 48)
                    spacing: 18

                    // ------------------------------------------------- clock
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatTime(lockClock.date, "HH:mm")
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 56
                            font.weight: Font.Light
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Qt.formatDate(lockClock.date, "dddd, MMMM d")
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // -------------------------------------------------- card
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: card.height

                        Rectangle {
                            id: card
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: cardColumn.implicitHeight + 36
                            radius: Theme.radius
                            color: Theme.dark ? Qt.rgba(0.09, 0.09, 0.10, 0.86) : Qt.rgba(1, 1, 1, 0.88)
                            border.width: 1
                            border.color: Theme.hairline

                            ColumnLayout {
                                id: cardColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 18
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 11

                                    Rectangle {
                                        width: 38
                                        height: 38
                                        radius: 19
                                        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05)

                                        Text {
                                            anchors.centerIn: parent
                                            text: lockRoot.userName.length > 0
                                                ? lockRoot.userName.charAt(0).toUpperCase() : "?"
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            Layout.fillWidth: true
                                            text: lockRoot.userName
                                            color: Theme.fg
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: lockRoot.authenticating ? "Authenticating…" : "Locked"
                                            color: Theme.muted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                // --------------------------------- password
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 40
                                    radius: Theme.radiusControl
                                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0, 0, 0, 0.03)
                                    border.width: 1
                                    border.color: passwordInput.activeFocus ? Theme.fg : Theme.hairlineSoft

                                    TextInput {
                                        id: passwordInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 11
                                        anchors.rightMargin: 11
                                        verticalAlignment: TextInput.AlignVCenter
                                        color: Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        echoMode: TextInput.Password
                                        selectionColor: Theme.fg
                                        selectedTextColor: Theme.bg
                                        clip: true
                                        focus: true
                                        enabled: !lockRoot.authenticating

                                        Component.onCompleted: forceActiveFocus()

                                        onTextChanged: {
                                            if (lockRoot.password !== text)
                                                lockRoot.password = text;
                                        }

                                        onAccepted: lockRoot.submit()

                                        Keys.onEscapePressed: (event) => {
                                            lockRoot.clearPassword();
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
                                            if (!lockRoot.authenticating)
                                                Qt.callLater(() => passwordInput.forceActiveFocus());
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: passwordInput.text.length === 0
                                        text: lockRoot.authenticating ? "Waiting for authentication…" : "Password"
                                        color: Theme.muted
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                // ----------------------------------- action
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: Theme.radiusControl
                                    color: unlockMouse.containsMouse ? Qt.lighter(Theme.fg, 1.15) : Theme.fg
                                    opacity: lockRoot.authenticating || lockRoot.password.length === 0 ? 0.55 : 1.0

                                    Text {
                                        anchors.centerIn: parent
                                        text: lockRoot.authenticating ? "Unlocking…" : "Unlock"
                                        color: Theme.accentInk
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: unlockMouse
                                        anchors.fill: parent
                                        enabled: !lockRoot.authenticating
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: lockRoot.submit()
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: lockRoot.errorText.length > 0
                                    text: lockRoot.errorText
                                    color: Theme.danger
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Press Enter to unlock · Esc clears"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        opacity: 0.75
                    }
                }
            }
        }
    }
}
