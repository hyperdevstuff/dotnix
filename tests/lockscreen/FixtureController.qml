import QtQuick

// Visual test controller only: never imports PAM or the session-lock protocol.
QtObject {
    property bool locked: true
    property bool promptPage: false
    property bool authenticating: false
    property string password: ""
    property string errorText: ""
    property string userName: "hyper"
    property string wallpaper: ""
    property date now: new Date(2026, 10, 21, 20, 53)
    property int submissions: 0
    function enterPrompt() { promptPage = true; }
    function leavePrompt() { promptPage = false; password = ""; errorText = ""; }
    function clearPassword() { password = ""; errorText = ""; }
    function submit() {
        if (authenticating || !password.length) return;
        submissions++;
        password = "";
        authenticating = true;
    }
    function fail() { authenticating = false; errorText = "Incorrect password. Try again."; }
}
