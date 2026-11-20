// SPDX-License-Identifier: GPL-3.0-only
// Adapted from caelestia-dots; see notification-attribution/README.md.
import QtQuick
import Quickshell.Services.Notifications

// The server and tests share this store. Only entries hold live QObjects;
// history contains values and never retains notification or action objects.
QtObject {
    id: root
    property var items: []
    property var history: []
    property var entries: []
    property bool paused: false
    property bool dnd: false
    property int maxVisible: 4
    property int maxHistory: 100
    property int nextKey: 1
    property int progressRevision: 0
    property double lastTick: Date.now()
    readonly property int count: items.length
    readonly property int historyCount: history.length
    readonly property var popups: entries.filter(e => e.popup).slice(0, maxVisible).map(e => e.notification)

    onPausedChanged: lastTick = Date.now()
    onDndChanged: {
        if (dnd) {
            for (const e of entries) e.popup = false
            entries = entries.slice()
        }
    }

    function timeout(n) {
        if (n.urgency === NotificationUrgency.Critical || n.expireTimeout === 0) return 0
        // Quickshell 0.3 exposes the sender timeout in milliseconds.
        return n.expireTimeout > 0 ? Math.round(n.expireTimeout) : 8000
    }
    function snapshot(e) {
        const n = e.notification
        return { key: e.key, time: e.time, appName: String(n.appName || "Notification"),
            appIcon: String(n.appIcon || ""), image: String(n.image || ""),
            summary: String(n.summary || ""), body: String(n.body || ""), urgency: n.urgency }
    }
    function refresh(e) {
        if (!e || entries.indexOf(e) < 0) return
        const index = history.findIndex(h => h.key === e.key)
        if (index < 0) return
        const next = history.slice()
        next[index] = snapshot(e)
        history = next
    }
    function add(n) {
        if (!n) return
        // Account for idle time before publishing the entry. Popup creation can
        // synchronously report hover and call tick() again.
        tick(Date.now(), n)
        let e = entries.find(entry => entry.notification === n)
        if (e) {
            e.time = Date.now()
            e.duration = timeout(n)
            e.remaining = e.duration
            e.popup = !dnd
            entries = [e].concat(entries.filter(entry => entry !== e))
            history = history.filter(h => h.key !== e.key)
        } else {
            e = { key: nextKey++, notification: n, time: Date.now(), duration: timeout(n),
                remaining: timeout(n), popup: !dnd, hovers: [] }
            entries = [e].concat(entries)
            e.watcher = watcherComponent.createObject(root, { notification: n, entry: e })
        }
        let visible = 0
        for (const entry of entries) {
            if (entry.popup && ++visible > maxVisible) entry.popup = false
        }
        entries = entries.slice()
        if (!n.transient) history = [snapshot(e)].concat(history).slice(0, maxHistory)
        items = entries.map(entry => entry.notification)
    }
    function entryFor(n) { return entries.find(e => e.notification === n) }
    function liveForKey(key) {
        const e = entries.find(entry => entry.key === key)
        return e ? e.notification : null
    }
    function timeFor(n) { const e = entryFor(n); return e ? e.time : Date.now() }
    function progressFor(n) {
        const e = entryFor(n)
        return e && e.duration > 0 ? Math.max(0, e.remaining / e.duration) : -1
    }
    function setHovered(n, owner, hovered) {
        const e = entryFor(n)
        if (!e) return
        tick(Date.now())
        e.hovers = e.hovers.filter(o => o !== owner)
        if (hovered) e.hovers.push(owner)
    }
    function tick(now, exclude) {
        const elapsed = Math.max(0, now - lastTick)
        lastTick = now
        const expired = []
        for (const e of entries) {
            if (e.notification !== exclude && e.duration > 0 && !paused && e.hovers.length === 0) {
                e.remaining -= elapsed
                if (e.remaining <= 0) expired.push(e.notification)
            }
        }
        progressRevision++
        for (const n of expired) { remove(n); n.expire() }
    }
    function remove(n) {
        const e = entryFor(n)
        if (!e) return
        entries = entries.filter(entry => entry !== e)
        items = entries.map(entry => entry.notification)
        if (e.watcher) e.watcher.destroy()
    }
    function dismiss(n) { if (!n) return; remove(n); n.dismiss() }
    function dismissAll() {
        const all = items.slice()
        for (const n of all) dismiss(n)
    }
    function removeHistory(key) {
        const n = liveForKey(key)
        if (n) dismiss(n)
        history = history.filter(h => h.key !== key)
    }
    function clearHistory() { dismissAll(); history = [] }

    property Timer ticker: Timer {
        interval: 100; repeat: true; running: !root.paused && root.entries.some(e => e.duration > 0)
        onTriggered: root.tick(Date.now())
    }
    property Component watcherComponent: Component {
        Connections {
            required property var notification
            required property var entry
            target: notification
            ignoreUnknownSignals: true
            function onClosed() { root.remove(notification) }
            function onSummaryChanged() { root.refresh(entry) }
            function onBodyChanged() { root.refresh(entry) }
            function onAppNameChanged() { root.refresh(entry) }
            function onAppIconChanged() { root.refresh(entry) }
            function onImageChanged() { root.refresh(entry) }
            function onUrgencyChanged() { root.refresh(entry) }
        }
    }
}
