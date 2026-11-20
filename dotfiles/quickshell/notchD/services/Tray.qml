pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

// Keep the status-notifier host alive even while the island is compact.
Singleton {
    readonly property var items: SystemTray.items.values
    readonly property var activeItems: items.filter(item => item.status !== Status.Passive)
    readonly property int count: items.length
    readonly property int attentionCount: items.filter(item => item.status === Status.NeedsAttention).length
}
