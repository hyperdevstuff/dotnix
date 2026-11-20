import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import "app" as App
import "app/components" as Components
import "app/services" as Services
ShellRoot {
    id: test
    property bool failed: false
    property bool menuRead: false
    property bool attentionSeen: false
    property bool passiveSeen: false
    property bool registered: false
    property int attempts: 0
    function check(ok, message) { if (!ok) { failed = true; console.error("FAIL", message); } }
    App.IslandState { id: state }
    Window {
        visible: true; width: 1000; height: 560
        Components.HubSurface { anchors.fill: parent; state: state }
        Components.CalendarSurface { id: calendar; visible: false }
        Components.TrayButton { id: appButton; item: Services.Tray.items.length ? Services.Tray.items[0] : null }
    }
    QsMenuOpener { id: menu; menu: appButton.item ? appButton.item.menu : null }
    Component.onCompleted: {
        calendar.select(new Date(2024, 0, 31, 12), false);
        calendar.moveMonth(1);
        check(calendar.selectedDate.getMonth() === 1 && calendar.selectedDate.getDate() === 29, "leap February clamps day");
        calendar.select(new Date(2025, 0, 31, 12), false);
        calendar.moveMonth(1);
        check(calendar.selectedDate.getDate() === 28, "ordinary February clamps day");
        calendar.select(new Date(2026, 11, 31, 12), false);
        calendar.moveDays(1);
        check(calendar.selectedDate.getFullYear() === 2027 && calendar.selectedDate.getMonth() === 0 && calendar.selectedDate.getDate() === 1, "year boundary");
        check(calendar.cellDate(0).getDay() === calendar.firstWeekday, "locale week start");
        state.hidden = true; state.selectTab("Calendar");
        check(!state.hidden && state.mode === "hub", "calendar unhides island");
        state.back(); check(state.hubTab === "Dashboard", "calendar Back");
        state.selectTab("Tray"); state.back(); check(state.hubTab === "Dashboard", "tray Back");
        check(Services.Time.time.length >= 4 && Services.Time.date.length > 5, "clock/date initialized");
    }
    Timer {
        interval: 100; repeat: true; running: true
        onTriggered: {
            test.attempts++;
            if (appButton.item) {
                test.registered = true;
                if (!test.menuRead && menu.children.values.length) {
                    test.check(menu.children.values[0].text === "Fixture action", "DBusMenu label");
                    menu.children.values[0].triggered();
                    appButton.activate();
                    appButton.item.secondaryActivate();
                    appButton.item.scroll(120, false);
                    test.menuRead = true;
                }
                if (appButton.item.status === Status.NeedsAttention) {
                    test.attentionSeen = true;
                    test.check(Services.Tray.attentionCount === 1, "attention state");
                }
                if (appButton.item.status === Status.Passive) {
                    test.passiveSeen = true;
                    test.check(Services.Tray.activeItems.length === 0 && Services.Tray.count === 1, "passive kept in full tray");
                }
            } else if (test.registered && test.passiveSeen) {
                test.check(test.menuRead && test.attentionSeen, "menu and attention exercised");
                console.log(test.failed ? "TRAY_CALENDAR_FAILED" : "TRAY_CALENDAR_PASSED");
                Qt.quit();
            }
            if (test.attempts > 90) { console.error("TRAY_CALENDAR_TIMEOUT", test.menuRead, test.attentionSeen, test.passiveSeen); Qt.quit(); }
        }
    }
}
