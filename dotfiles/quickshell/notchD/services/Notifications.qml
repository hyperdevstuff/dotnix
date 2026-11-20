// SPDX-License-Identifier: GPL-3.0-only
// Adapted from caelestia-dots; see notification-attribution/README.md.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One native server; the store owns expiry independently of all card views.
Singleton {
    id: root
    property alias items: store.items
    property alias history: store.history
    property alias paused: store.paused
    property alias dnd: store.dnd
    readonly property alias count: store.count
    readonly property alias historyCount: store.historyCount
    readonly property alias popups: store.popups
    readonly property alias entries: store.entries
    readonly property alias progressRevision: store.progressRevision
    readonly property alias maxVisible: store.maxVisible
    function add(n) { store.add(n) }
    function remove(n) { store.remove(n) }
    function dismiss(n) { store.dismiss(n) }
    function dismissAll() { store.dismissAll() }
    function removeHistory(key) { store.removeHistory(key) }
    function clearHistory() { store.clearHistory() }
    function liveForKey(key) { return store.liveForKey(key) }
    function timeFor(n) { return store.timeFor(n) }
    function progressFor(n) { return store.progressFor(n) }
    function setHovered(n, owner, hovered) { store.setHovered(n, owner, hovered) }

    NotificationStore { id: store }
    NotificationServer {
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false
        persistenceSupported: false
        onNotification: notification => { notification.tracked = true; root.add(notification) }
    }
}
