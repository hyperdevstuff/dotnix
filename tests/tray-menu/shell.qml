//@ pragma UseQApplication
import QtQuick
import QtQuick.Window
import Quickshell
import "app/components" as Components
import "app/services" as Services
ShellRoot {
    id: test
    property int step: 0
    property int ticks: 0
    function check(ok, msg) { if (!ok) { console.error("FAIL", msg); Qt.quit(); } }
    Window {
        visible: true; width: 500; height: 400
        Components.TrayMenu { id: menu; menuHandle: Services.Tray.items.length ? Services.Tray.items[0].menu : null }
    }
    Timer {
        interval: 100; running: true; repeat: true
        onTriggered: {
            if (++test.ticks > 70) { console.error("MENU_TIMEOUT", test.step, menu.count); Qt.quit(); }
            if (test.step === 0 && menu.menuHandle) { menu.open(); test.step++; }
            else if (test.step === 1 && menu.count === 5) {
                test.check(menu.width >= 200 && menu.itemAt(0).width > 0, "root popup has usable width");
                test.check(menu.itemAt(0).text === "Fixture action", "action label");
                test.check(!menu.itemAt(1).enabled, "disabled");
                test.check(menu.itemAt(2).entry.checkState === Qt.Checked, "checked");
                test.check(menu.menuAt(3) !== null, "submenu");
                menu.menuAt(3).open(); test.step++;
            } else if (test.step === 2 && menu.menuAt(3).count === 1) {
                test.check(menu.menuAt(3).width >= 200, "submenu has usable width");
                test.check(menu.menuAt(3).itemAt(0).text === "Nested action", "nested action");
                menu.menuAt(3).itemAt(0).triggered();
                menu.close(); test.step++;
            } else if (test.step === 3 && !menu.visible) {
                console.log("TRAY_MENU_PASSED"); Qt.quit();
            }
        }
    }
}
