pragma Singleton
import QtQuick
import Quickshell
import ".."

Singleton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    readonly property date now: clock.date
    readonly property string time: Qt.formatTime(now, Theme.use12HourClock ? "h:mm AP" : "HH:mm")
    readonly property string weekday: Qt.formatDate(now, "dddd")
    readonly property string date: Qt.formatDate(now, "d MMMM yyyy")
    readonly property string zone: Qt.formatDateTime(now, "t")
}
