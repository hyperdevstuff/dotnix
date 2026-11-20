import QtQuick
import QtQuick.Window
import Quickshell
import "app" as App
import "app/components" as Components
import "app/services" as Services
import "app/services/mocks" as Mocks

ShellRoot {
    id: test
    property bool failed: false
    function check(ok, message) { if (!ok) { failed = true; console.error("FAIL", message); } }
    QtObject {
        id: first
        property string trackTitle: "A long track title"
        property string trackArtist: "Artist"
        property string trackAlbum: "Album"
        property string identity: "First player"
        property string trackArtUrl: ""
        property bool isPlaying: true
        property bool canPlay: true
        property bool canPause: true
        property bool canTogglePlaying: true
        property bool canGoNext: true
        property bool canGoPrevious: true
        property bool canSeek: true
        property bool positionSupported: true
        property real position: 40
        property real length: 200
        property bool lengthSupported: true
        function togglePlaying() { isPlaying = !isPlaying; }
        function next() {}
        function previous() {}
    }
    QtObject {
        id: second
        property string trackTitle: "Second track"
        property string trackArtist: "Second artist"
        property string trackAlbum: ""
        property string identity: "Second player"
        property string trackArtUrl: ""
        property bool isPlaying: false
        property bool canPlay: true
        property bool canPause: true
        property bool canTogglePlaying: true
        property bool canGoNext: false
        property bool canGoPrevious: false
        property bool canSeek: false
        property bool positionSupported: false
        property real position: 0
        property real length: 100
        property bool lengthSupported: true
        function togglePlaying() { isPlaying = !isPlaying; }
    }
    App.IslandState { id: island }
    Window {
        id: testWindow
        visible: true
        width: 1000
        height: 560
        App.NotchD { id: notch; state: island; screen: ({width: testWindow.width, height: testWindow.height}); anchors.horizontalCenter: parent.horizontalCenter }
    }
    Components.PerformanceSurface { id: perf; visible: false }
    function sample(time, total, idle, rx, tx) {
        return { time: time, cpu: {name: "CPU", total: total, idle: idle, temperature: null},
            gpu: {name: "GPU", usage: null, temperature: null, state: "Sleeping"},
            memory: {used: 2, total: 8}, storage: {used: 25, total: 100, free: 75},
            network: {rx: rx, tx: tx}, uptime: 100 };
    }
    Component.onCompleted: {
        Mocks.Mpris.players.values = [first, second];
        check(Services.Media.activePlayer === first, "follow playing source");
        Services.Media.seek(999); check(first.position === 200, "seek upper bound");
        Services.Media.seek(-9); check(first.position === 0, "seek lower bound");
        first.lengthSupported = false;
        check(Services.Media.length === 0 && !Services.Media.canSeek, "unknown duration is not a full progress bar");
        first.lengthSupported = true;
        Services.Media.selectPlayer(second);
        Services.Media.seek(40); check(second.position === 0, "respect unsupported seek");
        check(Services.Media.activePlayer === second, "select source");
        Mocks.Mpris.players.values = [first];
        check(Services.Media.activePlayer === first, "fallback when source disappears");
        first.position = 40;
        perf.consume(sample(10, 100, 80, 1000, 500));
        perf.consume(sample(12, 200, 130, 5096, 1524));
        check(perf.cpu === 50, "CPU delta excludes idle");
        check(perf.download === 2048 && perf.upload === 512, "network byte rates");
        check(perf.memory === 25 && perf.storage === 25, "resource proportions");
        perf.consume(sample(14, 300, 180, 0, 0));
        check(perf.download === 0 && perf.upload === 0, "counter resets do not produce negative rates");
        check(island.mainTabs.join(",") === "Dashboard,Media,Performance", "workspace tab removed");
    }
    property int step: 0
    Timer {
        interval: 250; repeat: true; running: true
        onTriggered: {
            step++;
            if (step === 1) island.openHub();
            if (step === 3) island.selectTab("Media");
            if (step === 5) island.selectTab("Performance");
            if (step === 7) { testWindow.width = 500; testWindow.height = 240; island.selectTab("Dashboard"); }
            if (step === 9) island.selectTab("Media");
            if (step === 11) island.selectTab("Performance");
            if (step === 13) { island.openFlyout("wifi"); island.back(); check(island.hubTab === "Performance", "detail back preserves tab"); }
            if (step === 15) {
                check(isFinite(notch.surfaceW) && notch.surfaceW <= 500, "bounded surface width");
                check(isFinite(notch.surfaceH) && notch.surfaceH <= 240, "bounded surface height");
                console.log(test.failed ? "POLISH_TESTS_FAILED" : "POLISH_TESTS_PASSED");
                Services.Media.selectedPlayer = null;
                Mocks.Mpris.players.values = [];
                Qt.quit();
            }
        }
    }
}
