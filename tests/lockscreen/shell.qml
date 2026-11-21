import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "app" as App
import "app/components" as Components

ShellRoot {
    id: test
    property bool failed: false
    property int step: 0
    property real fieldY: 0
    function check(ok, message) {
        if (!ok) { failed = true; console.error("FAIL", message); }
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const result = find(child, name);
            if (result) return result;
        }
        return null;
    }
    FixtureController { id: controller }
    Window {
        id: window
        visible: true
        width: 1670; height: 940
        Components.LockContent { id: content; anchors.fill: parent; controller: controller }
        TestCase { id: keys; name: "LockContent"; when: false }
    }
    Timer {
        interval: 130; repeat: true; running: true
        onTriggered: {
            const input = test.find(content, "lockPasswordInput");
            const field = test.find(content, "lockPasswordField");
            const submit = test.find(content, "lockSubmit");
            const viewport = test.find(content, "lockAuthViewport");
            if (test.step === 0) {
                const group = test.find(content, "lockClockGroup");
                const date = test.find(content, "lockAmbientDate");
                const time = test.find(content, "lockAmbientTime");
                test.check(Math.abs(group.y + group.height / 2 - window.height * 0.25) < 2, "clock group is halfway between top and center");
                test.check(date.y >= time.y + time.height && date.text.length > 0, "date is beneath the clock");
                test.check(test.find(content, "lockAmbientTarget").activeFocus, "ambient page owns initial focus");
                keys.keyClick(Qt.Key_A);
                test.check(controller.promptPage && controller.password === "", "first key reveals sign-in without typing a password");
            } else if (test.step === 1) {
                test.check(input.activeFocus && input.echoMode === TextInput.Password, "password field receives focus and stays masked");
                test.check(field.height === 64 && submit.width === 48, "larger field and submit targets");
                keys.keyClick(Qt.Key_Q);
                test.check(controller.password === "q", "typing reaches the controller");
                keys.keyClick(Qt.Key_Escape);
                test.check(controller.password === "" && controller.promptPage, "first Escape clears password");
                keys.keyClick(Qt.Key_Escape);
                test.check(!controller.promptPage, "second Escape returns to ambient page");
            } else if (test.step === 2) {
                keys.keyClick(Qt.Key_Space);
                test.check(controller.promptPage && !controller.password.length, "returning to sign-in never types ahead");
            } else if (test.step === 3) {
                keys.keyClick(Qt.Key_Q); keys.keyClick(Qt.Key_R);
                keys.keyClick(Qt.Key_Tab);
                test.check(submit.activeFocus, "submit is keyboard reachable");
                test.fieldY = field.mapToItem(content, 0, 0).y;
                keys.keyClick(Qt.Key_Return);
                test.check(controller.submissions === 1 && controller.authenticating && !input.enabled && !submit.enabled && !input.text.length, "busy state disables input and clears visible buffer");
                controller.fail();
            } else if (test.step === 4) {
                test.check(input.activeFocus && input.enabled, "failed authentication restores focus");
                test.check(Math.abs(field.mapToItem(content, 0, 0).y - test.fieldY) < 1, "error text does not move the password field");
                test.check(test.find(content, "lockError").text.length > 0, "error is displayed");
                App.Theme.dark = false;
                test.check(content.ink.r > 0.6, "lock palette stays dark when desktop is light");
                App.Theme.use12HourClock = true;
                test.check(test.find(content, "lockAmbientTime").text.includes("PM"), "12-hour preference is honored");
                window.width = 480; window.height = 480;
                App.Theme.textScale = 1.2;
            } else if (test.step === 5) {
                test.check(field.width <= window.width - 48 && viewport.contentHeight >= viewport.height, "form is bounded and scrollable on smaller outputs");
                window.width = 320; window.height = 360;
                content.focusPage();
            } else if (test.step === 6) {
                const p = field.mapToItem(viewport, 0, 0);
                test.check(p.y >= 0 && p.y + field.height <= viewport.height, "focused password field scrolls into view on short outputs");
                App.Motion.reduceMotion = true;
                content.showPrompt(true);
                test.check(content.pageDuration === 0, "reduced motion has no page displacement animation");
                controller.leavePrompt();
            } else if (test.step === 7) {
                keys.mouseClick(content, 20, 200, Qt.LeftButton);
                test.check(controller.promptPage && !controller.password.length, "pointer reveals sign-in without typing ahead");
            } else if (test.step === 8) {
                input.forceActiveFocus();
                keys.keyClick(Qt.Key_Q);
                keys.keyClick(Qt.Key_Return);
                test.check(controller.submissions === 2 && controller.authenticating, "Enter in password input submits directly");
                keys.keyClick(Qt.Key_Escape);
                test.check(controller.promptPage, "busy sign-in stays on the authentication page");
                console.log(test.failed ? "LOCKSCREEN_VISUAL_TESTS_FAILED" : "LOCKSCREEN_VISUAL_TESTS_PASSED");
                stop(); Qt.callLater(Qt.quit);
            }
            test.step++;
        }
    }
}
