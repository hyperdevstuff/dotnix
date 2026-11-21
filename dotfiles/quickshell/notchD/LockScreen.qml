import QtQuick
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
// The lock keeps the Windows-style two-page sequence:
//
//   page 1  raised ambient clock and date on the wallpaper. Any key, click or scroll advances.
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
    readonly property string wallpaper: Quickshell.env("NOTCHD_LOCK_WALLPAPER") || (Quickshell.env("HOME") + "/Pictures/walls/dotted.png")

    signal unlocked

    SystemClock {
        id: lockClock
        precision: SystemClock.Minutes
    }

    readonly property date now: lockClock.date

    function resetState() {
        password = "";
        pendingPassword = "";
        errorText = "";
        authenticating = false;
        if (pam.active)
            pam.abort();
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
        if (!locked || promptPage)
            return;
        promptPage = true;
    }

    function leavePrompt() {
        if (!promptPage)
            return;
        promptPage = false;
        password = "";
        errorText = "";
    }

    function submit() {
        if (!locked || authenticating)
            return;
        if (password.length === 0)
            return;
        pendingPassword = password;
        password = "";
        errorText = "";
        authenticating = true;
        if (pam.active)
            pam.abort();
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
            if (!responseRequired || !lockRoot.authenticating)
                return;
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

        onCompleted: result => {
            lockRoot.authenticating = false;
            if (result === PamResult.Success) {
                lockRoot.unlock();
            } else {
                lockRoot.password = "";
                lockRoot.errorText = result === PamResult.MaxTries ? "Too many attempts. Try again later." : "Incorrect password";
            }
        }

        onError: error => {
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
            Components.LockContent {
                anchors.fill: parent
                controller: lockRoot
            }
        }
    }
}
