import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../../dotfiles/quickshell/notchD/services" as Services

ShellRoot {
    id: root
    Services.NotificationStore { id: store }
    Component {
        id: mock
        QtObject {
            property string appName: "App"
            property string appIcon: ""
            property string image: ""
            property string summary: "First"
            property string body: "Body"
            property int urgency: NotificationUrgency.Normal
            property real expireTimeout: 1000
            property int expired: 0
            property int dismissed: 0
            property int invoked: 0
            property var actions: [{ text: "Open", invoke: () => invoked++ }]
            signal closed()
            function expire() { expired++; closed() }
            function dismiss() { dismissed++; closed() }
        }
    }
    function check(value, message) { if (!value) throw new Error(message) }
    function advance(ms) { store.tick(store.lastTick + ms) }
    function make() { return mock.createObject(root) }
    function run() {
        // A notification arriving after a long quiet period must get its full lifetime.
        store.lastTick = Date.now() - 30000
        let n = make(); store.add(n)
        check(store.entries[0].remaining === 1000, "fresh notification after idle")
        advance(1100)
        check(n.expired === 1 && store.count === 0 && store.historyCount === 1, "expiry/history")
        check(store.history[0].summary === "First" && store.history[0].notification === undefined && store.liveForKey(store.history[0].key) === null, "safe snapshot")
        store.clearHistory()
        n = make(); store.add(n); let key = store.history[0].key
        n.summary = "Updated"; store.add(n)
        check(store.count === 1 && store.historyCount === 1 && store.history[0].key === key && store.history[0].summary === "Updated", "replacement")
        store.liveForKey(key).actions[0].invoke(); check(n.invoked === 1, "live action")
        store.clearHistory(); check(n.dismissed === 1 && store.historyCount === 0, "clear")
        store.dnd = true; n = make(); store.add(n); store.dnd = false
        check(store.popups.length === 0 && store.historyCount === 1, "DND")
        for (let i = 0; i < 5; i++) store.add(make())
        check(store.popups.length === 4 && store.count === 6 && store.historyCount === 6, "bounded popups")
        store.dismiss(store.popups[0]); check(store.popups.length === 3, "overflow must not reappear")
        store.clearHistory(); n = make(); n.urgency = NotificationUrgency.Critical; store.add(n); advance(50000)
        check(n.expired === 0, "critical")
        n.urgency = NotificationUrgency.Normal; n.expireTimeout = 0; store.add(n); advance(50000)
        check(n.expired === 0, "persistent")
        store.clearHistory(); n = make(); store.add(n); store.setHovered(n, root, true); advance(5000)
        check(n.expired === 0, "hover pause")
        store.setHovered(n, root, false); store.paused = true; advance(5000)
        check(n.expired === 0, "lock pause")
        store.paused = false; advance(1100); check(n.expired === 1, "resume")
        n = make(); store.add(n); n.closed(); check(store.count === 0 && store.historyCount === 2, "sender close")
        store.removeHistory(store.history[0].key); check(store.historyCount === 1, "remove history")
        console.log("NOTIFICATION_TESTS_PASSED")
        Qt.quit()
    }
    Timer { interval: 50; running: true; onTriggered: root.run() }
}
