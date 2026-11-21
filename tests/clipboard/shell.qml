import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import "app/components" as Components

ShellRoot {
    id: test
    property int step: 0
    property int ticks: 0
    property int closed: 0
    property bool failed: false
    Component.onCompleted: clipboard.refresh()
    function check(ok, message) {
        if (!ok) { failed = true; console.error("FAIL", message); }
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children || []) {
            const match = find(child, name);
            if (match) return match;
        }
        return null;
    }
    Window {
        visible: true
        width: 800
        height: 480
        Components.ClipboardSurface {
            id: clipboard
            width: 600
            height: 450
            onCloseRequested: test.closed++
        }
        Components.ActionButton {
            id: action
            x: 620
            label: "Tonal action"
            tonal: true
            property int presses: 0
            onClicked: presses++
        }
        Components.NotchSlider {
            id: slider
            x: 610; y: 70; width: 180
            label: "Fixture volume"
            canToggle: true
            value: 0.5
            property int toggles: 0
            onToggled: toggles++
            onMoved: value => slider.value = value
        }
        Components.QuickSetting {
            id: quick
            x: 610; y: 150; width: 180
            title: "Wi-Fi"; subtitle: "Fixture network"
            toggleable: true
            property int toggles: 0
            property int details: 0
            onTriggered: toggles++
            onDetailsRequested: details++
        }
        TestCase { id: keys; name: "ClipboardKeys"; when: false }
    }
    Timer {
        interval: 70; repeat: true; running: true
        onTriggered: {
            if (++test.ticks > 100) { console.error("FAIL clipboard timeout at step", test.step, clipboard.status); Qt.quit(); return; }
            const search = test.find(clipboard, "clipboardSearch");
            const list = test.find(clipboard, "clipboardList");
            if (!search || !list) return;
            if (test.step === 0) {
                if (clipboard.entries.length !== 32) return;
                search.forceActiveFocus();
                for (let i = 0; i < 25; i++) keys.keyClick(Qt.Key_Down);
                test.check(clipboard.selected === 25, "Down navigates while search retains focus");
            } else if (test.step === 1) {
                test.check(list.contentY > 0, "keyboard navigation scrolls selected clip into view");
                search.text = "Fixture clip 03";
            } else if (test.step === 2) {
                test.check(clipboard.filtered.length === 1 && clipboard.selected === 0 && list.contentY === 0, "filter resets selection and scroll position");
                keys.keyClick(Qt.Key_Return);
            } else if (test.step === 3) {
                if (!test.closed) return;
                test.check(test.closed === 1, "Enter copies then requests dismissal");
                search.text = "";
            } else if (test.step === 4) {
                keys.keyClick(Qt.Key_Down);
                keys.keyClick(Qt.Key_Delete, Qt.ControlModifier);
            } else if (test.step === 5) {
                if (clipboard.entries.length !== 31) return;
                test.check(search.activeFocus, "delete refresh preserves search focus");
                action.forceActiveFocus();
                keys.keyClick(Qt.Key_Return);
                keys.keyClick(Qt.Key_Space);
                test.check(action.presses === 2, "tonal buttons activate from keyboard");
                keys.mouseMove(action, 16, 16);
                keys.mousePress(action, 16, 16, Qt.LeftButton);
                keys.mouseRelease(action, 16, 16, Qt.LeftButton);
                test.check(action.presses === 3, "state layer does not intercept pointer activation");
                action.enabled = false;
                keys.keyClick(Qt.Key_Return);
                test.check(action.presses === 3, "disabled action cannot activate");
                slider.forceActiveFocus();
                keys.keyClick(Qt.Key_Right);
                test.check(Math.abs(slider.value - 0.55) < 0.001, "slider accepts keyboard adjustment");
                keys.keyClick(Qt.Key_Tab);
                keys.keyClick(Qt.Key_Space);
                test.check(slider.toggles === 1, "mute has an independent keyboard target");
                keys.mouseClick(quick, 30, 30, Qt.LeftButton);
                keys.mouseClick(quick, quick.width - 20, 30, Qt.LeftButton);
                test.check(quick.toggles === 1 && quick.details === 1, "primary and detail pointer targets stay separate");
                console.log(test.failed ? "CLIPBOARD_KEYS_FAILED" : "CLIPBOARD_KEYS_PASSED");
                stop(); Qt.callLater(Qt.quit);
            }
            test.step++;
        }
    }
}
