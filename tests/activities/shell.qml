import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../../dotfiles/quickshell/notchD/services" as Services

ShellRoot {
    id: root

    // The offscreen platform supplies a window without a real Wayland surface.
    Window { id: testWindow; visible: true; width: 1; height: 1 }

    function check(condition, message) {
        if (!condition) throw new Error(message)
    }
    function link(state, source, target) {
        return { state: state, source: { properties: source }, target: { properties: target } }
    }
    function event(value) { Services.Privacy.castEvent(JSON.stringify(value)) }
    function run() {
        const audio = { "media.class": "Audio/Source" }
        const monitor = { "media.class": "Audio/Source", "device.class": "monitor" }
        const video = { "media.class": "Video/Source", "device.api": "v4l2" }
        const screen = { "media.class": "Video/Source", "media.role": "Screen" }
        const micClient = { "media.class": "Stream/Input/Audio", "application.name": "Call" }
        const videoClient = { "media.class": "Stream/Input/Video", "application.name": "Meeting" }
        const pausedClient = { "media.class": "Stream/Input/Audio", "application.name": "Paused" }
        const result = Services.Privacy.classifyLinks([
            link(PwLinkState.Active, audio, micClient),
            link(PwLinkState.Paused, audio, pausedClient),
            link(PwLinkState.Active, monitor, pausedClient),
            link(PwLinkState.Active, video, videoClient),
            link(PwLinkState.Active, screen, videoClient)
        ])
        check(result.microphone.length === 1 && result.microphone[0] === "Call", "active microphone only; exclude paused and monitor")
        check(result.camera.length === 1 && result.camera[0] === "Meeting", "camera only; exclude screen")
        check(Services.Privacy.classifyLinks([link(PwLinkState.Paused, video, videoClient)]).camera.length === 0, "paused camera")
        check(Services.Privacy.classifyLinks([link(PwLinkState.Active, screen, videoClient)]).camera.length === 0, "screen is not camera")

        event({ CastsChanged: { casts: [] } })
        check(Services.Privacy.screenAvailable && !Services.Privacy.screenActive, "empty cast snapshot")
        event({ CastStartedOrChanged: { cast: { stream_id: 42, is_active: true, pid: -1 } } })
        check(Services.Privacy.screenActive, "cast started")
        event({ CastStartedOrChanged: { cast: { stream_id: 42, is_active: false, pid: -1 } } })
        check(!Services.Privacy.screenActive, "cast paused")
        event({ CastStartedOrChanged: { cast: { stream_id: 42, is_active: true, pid: -1 } } })
        event({ CastStopped: { stream_id: 42 } })
        check(!Services.Privacy.screenActive, "cast stopped")
        event({ CastStartedOrChanged: { cast: { stream_id: 43, is_active: true, pid: Quickshell.processId } } })
        check(!Services.Privacy.screenActive, "own cast excluded")

        const awake = Services.KeepAwake
        check(!awake.start(15) && !awake.active, "windowless request rejected")
        awake.window = testWindow
        check(!awake.start(5) && !awake.active, "unsupported duration rejected")
        check(awake.start(15) && awake.active && awake.durationMinutes === 15 && awake.remainingText === "15 min left", "timed inhibitor started")
        awake._deadline = Date.now() - 1
        awake.updateRemaining()
        check(!awake.active && awake.remainingSeconds === 0 && awake.durationMinutes === 0 && awake.remainingText === "Off", "deadline expiry")
        check(awake.start(30), "30 minute duration")
        awake.stop()
        check(!awake.active, "manual stop")
        check(awake.start(60), "60 minute duration")
        testWindow.visible = false
        check(!awake.active, "hidden window stops inhibitor")
        awake.window = null
        console.log("ACTIVITY_TESTS_PASSED")
        Qt.quit()
    }
    Timer { interval: 50; running: true; onTriggered: root.run() }
}
