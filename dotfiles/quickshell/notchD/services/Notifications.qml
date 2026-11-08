pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Native notification daemon. Quickshell implements org.freedesktop.Notifications
// in-process, so notifications cost no extra daemon: the cards are QML inside
// the shell that is already running.
Singleton {
    id: root

    // Keep at most this many cards on screen; older ones are expired.
    readonly property int maxVisible: 4

    // Newest first. Reassigned (not mutated) so QML bindings update.
    property var items: []

    readonly property int count: items.length

    NotificationServer {
        id: server

        // Reloading the shell (config changes, rebuilds) should not lose cards.
        keepOnReload: true

        // Advertise what the cards actually render. Markup/hyperlinks are off
        // so text is always plain and cannot inject styling.
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        actionsSupported: true
        actionIconsSupported: false
        imageSupported: true
        inlineReplySupported: false
        persistenceSupported: false

        onNotification: (notification) => {
            // tracked keeps the object alive after this handler returns and
            // adds it to trackedNotifications.
            notification.tracked = true
            root.add(notification)
        }
    }

    function add(notification) {
        if (!notification) return

        // A replaces_id update reuses the same object; move it to the top.
        let next = items.slice().filter(n => n !== notification)
        next.unshift(notification)

        // Don't let a chatty app pile up cards forever.
        if (next.length > maxVisible) {
            const dropped = next.splice(maxVisible)
            for (let i = 0; i < dropped.length; i++)
                if (dropped[i]) dropped[i].expire()
        }

        items = next
    }

    function remove(notification) {
        const idx = items.indexOf(notification)
        if (idx === -1) return
        const next = items.slice()
        next.splice(idx, 1)
        items = next
    }

    function dismiss(notification) {
        if (notification) notification.dismiss()
        remove(notification)
    }

    function dismissAll() {
        const all = items.slice()
        items = []
        for (let i = 0; i < all.length; i++)
            if (all[i]) all[i].dismiss()
    }
}
