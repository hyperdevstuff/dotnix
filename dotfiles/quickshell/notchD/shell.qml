import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Polkit
import Quickshell.Services.UPower
import QtQuick
import "services" as Services

ShellRoot {
    id: shell

    // Cross-restart settings. JsonAdapter keeps the QML side declarative;
    // FileView writes atomically and reloads if the file changes on disk.
    //
    // A stable path is deliberate: Quickshell.statePath() is keyed by the
    // config path, which changes every time home-manager rebuilds the store
    // symlink. Keeping settings under ~/.local/state/notchD means module order
    // and visibility survive system rebuilds as well as restarts.
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")

    FileView {
        id: settingsFile
        path: shell.stateHome + "/notchD/settings.json"
        blockLoading: true
        // notchD is the only writer. Watching the file would reload our own
        // writes and race with rapid module edits (toggle, then move).
        watchChanges: false
        // Coalesce rapid edits into one atomic write of the final state.
        onAdapterUpdated: saveTimer.restart()
        onLoaded: shell.applySettings()
        onLoadFailed: (error) => {
            // First run: seed defaults so the next launch has a file to read.
            // Defer until the failed read has fully unwound.
            if (error === FileViewError.FileNotFound)
                Qt.callLater(() => settingsFile.writeAdapter());
        }

        JsonAdapter {
            id: settings
            property string style: "pill"   // pill | notch
            property bool hidden: false
            property string modulesOrder: "wifi,bluetooth,audio,battery,display,session"
            property string modulesEnabled: "wifi,bluetooth,audio,battery,display,session"
        }
    }

    Timer {
        id: saveTimer
        interval: 180
        onTriggered: settingsFile.writeAdapter()
    }

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    // Global light/dark mode. `wp` writes the effective mode here after
    // matugen runs (auto follows the wallpaper; `wp theme light|dark` forces
    // it). notchD follows the same file as the rest of the desktop.
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")

    FileView {
        id: modeView
        path: shell.configHome + "/matugen/generated/mode"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: shell.applyThemeMode()
    }

    function applyThemeMode() {
        const m = String(modeView.text()).trim();
        if (m === "light" || m === "dark")
            Theme.dark = m === "dark";
    }

    Component.onCompleted: {
        applyThemeMode();
        applySettings();
    }

    function applySettings() {
        if (settingsFile.loaded) {
            if (settings.modulesOrder.length > 0) Modules.orderCsv = settings.modulesOrder;
            if (settings.modulesEnabled.length > 0) Modules.enabledCsv = settings.modulesEnabled;
        }
    }

    // Persist registry changes as they happen.
    Connections {
        target: Modules
        function onOrderCsvChanged() { settings.modulesOrder = Modules.orderCsv; }
        function onEnabledCsvChanged() { settings.modulesEnabled = Modules.enabledCsv; }
    }

    IslandState {
        id: islandState
        hidden: settings.hidden
        onHiddenChanged: settings.hidden = hidden
    }

    // Native session lock, idle actions and the shell services.
    LockScreen {
        id: lockScreen
    }

    Connections {
        target: Services.Session
        function onLockRequested() { if (!lockScreen.locked) lockScreen.lock(); }
    }

    Connections {
        target: Services.Idle
        function onLockRequested() { if (!lockScreen.locked) lockScreen.lock(); }
        function onDisplayOffRequested() { Services.Session.powerOffMonitors(); }
        function onSuspendRequested() {
            if (!UPower.onBattery) return;
            // Give the compositor a moment to acquire the session lock before
            // logind freezes the machine.
            if (!lockScreen.locked) lockScreen.lock();
            suspendTimer.restart();
        }
    }

    Timer {
        id: suspendTimer
        interval: 300
        onTriggered: Services.Session.suspend()
    }

    // Now-playing peeks: only while idle, never on top of an open flyout.
    Connections {
        target: Services.Media
        function onTitleChanged() {
            if (!Services.Media.hasPlayer || !Services.Media.playing) return;
            if (islandState.hidden || islandState.mode !== "idle") return;
            islandState.peekMedia(4200);
        }
        function onPlayingChanged() {
            if (!Services.Media.playing) return;
            if (islandState.hidden || islandState.mode !== "idle") return;
            islandState.peekMedia(3200);
        }
    }

    // Right-click on the empty desktop: wallpaper actions.
    DesktopMenu {
        id: desktopMenu
        screen: shell.primaryScreen
    }

    // ------------------------------------------------------------- polkit
    PolkitAgent {
        id: polkitAgent
        onAuthenticationRequestStarted: islandState.openAuth()
        onIsActiveChanged: {
            if (polkitAgent.isActive) islandState.openAuth();
            else if (islandState.mode === "auth") islandState.closeAuth();
        }
    }

    Timer {
        id: authCloseTimer
        interval: 450
        onTriggered: if (islandState.mode === "auth") islandState.closeAuth()
    }

    Connections {
        target: polkitAgent.flow
        ignoreUnknownSignals: true
        function onIsCompletedChanged() {
            if (polkitAgent.flow && polkitAgent.flow.isCompleted) authCloseTimer.restart();
        }
    }

    function dismissTop() {
        if (islandState.mode === "auth") {
            if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest();
            else islandState.back();
            return;
        }
        islandState.back();
    }

    // Workspace OSD: only after the first event-stream snapshot, so startup
    // does not flash a card.
    property string lastWorkspaceName: ""

    Connections {
        target: Services.Compositor
        function onWorkspacesDataChanged() {
            const name = Services.Compositor.focusedWorkspaceName();
            if (shell.lastWorkspaceName.length > 0 && name.length > 0 && name !== shell.lastWorkspaceName)
                islandState.showOsd("workspace");
            shell.lastWorkspaceName = name;
        }
    }

    // --------------------------------------------------------------- overlay
    PanelWindow {
        id: win
        screen: shell.primaryScreen
        anchors { top: true; left: true; right: true }
        implicitHeight: 470
        color: "transparent"
        aboveWindows: true
        focusable: true
        exclusiveZone: 0
        visible: !islandState.hidden && !lockScreen.locked
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD"
        WlrLayershell.keyboardFocus: islandState.interactive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        mask: Region {
            Region {
                x: notch.x + notch.maskX
                y: notch.y + notch.maskY
                width: notch.maskW
                height: notch.maskH
                radius: Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
                topLeftRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
                topRightRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
            }
            Region {
                x: notch.x + notch.mask2X
                y: notch.y + notch.mask2Y
                width: notch.mask2W
                height: notch.mask2H
                radius: Math.round(Theme.radius)
            }
        }

        // Blur only behind expanded surfaces. niri implements
        // ext-background-effect-v1; the radius matches the panel.
        BackgroundEffect.blurRegion: Region {
            Region {
                x: notch.x + notch.blurX
                y: notch.y + notch.blurY
                width: notch.blurOn ? notch.blurW : 0
                height: notch.blurOn ? notch.blurH : 0
                radius: Math.round(Theme.radius)
                topLeftRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(Theme.radius)
                topRightRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(Theme.radius)
            }
            Region {
                x: notch.x + notch.blur2X
                y: notch.y + notch.blur2Y
                width: notch.blur2On ? notch.blur2W : 0
                height: notch.blur2On ? notch.blur2H : 0
                radius: Math.round(Theme.radius)
            }
        }

        NotchD {
            id: notch
            x: Math.round((win.width - Theme.hubW) / 2)
            state: islandState
            polkitFlow: polkitAgent.flow
            notchMode: settings.style === "notch"
        }
    }

    // Dismiss layer: full screen, mask subtracts both island surfaces so
    // clicks inside reach the island and clicks anywhere else step back.
    PanelWindow {
        id: dismissWin
        screen: shell.primaryScreen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        visible: islandState.interactive && !lockScreen.locked
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-dismiss"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            width: dismissWin.width
            height: dismissWin.height
            Region {
                x: notch.x + notch.maskX
                y: notch.y + notch.maskY
                width: notch.maskW
                height: notch.maskH
                radius: Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
                topLeftRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
                topRightRadius: (notch.notchMode && notch.mode !== "auth") ? 0 : Math.round(notch.pillLike ? Theme.radiusPill : Theme.radius)
                intersection: Intersection.Subtract
            }
            Region {
                x: notch.x + notch.mask2X
                y: notch.y + notch.mask2Y
                width: notch.mask2W
                height: notch.mask2H
                radius: Math.round(Theme.radius)
                intersection: Intersection.Subtract
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: shell.dismissTop()
        }
    }

    // ----------------------------------------------------------------- IPC
    IpcHandler {
        target: "notchD"

        function toggle() { islandState.setHidden(!islandState.hidden); }
        function hide()   { islandState.setHidden(true); }
        function show()   { islandState.setHidden(false); }
        function expand() { islandState.openHub(); }
        function collapse() { islandState.collapse(); }
        function back() { islandState.back(); }
        function toggleExpanded() { islandState.toggleExpanded(); }
        function peek(s: string) { islandState.peek(s, 0); }

        function openHub() { islandState.openHub(); }
        function openFlyout(kind: string) { islandState.openFlyout(kind); }
        function openWifi() { islandState.openFlyout("wifi"); }
        function openBluetooth() { islandState.openFlyout("bluetooth"); }
        function openAudio() { islandState.openFlyout("audio"); }
        function openBattery() { islandState.openFlyout("battery"); }
        function openDisplay() { islandState.openFlyout("display"); }
        function openSession() { islandState.openFlyout("session"); }
        function openSettings() { islandState.openFlyout("settings"); }

        // ------------------------------------------------------------ media
        function openMedia() { islandState.openMedia(); }
        function closeMedia() { islandState.closeMedia(); }
        function mediaPeek() {
            if (Services.Media.hasPlayer) islandState.peekMedia(4200);
        }
        function mediaPlayPause() {
            Services.Media.playPause();
            if (Services.Media.hasPlayer) islandState.peekMedia(2400);
        }
        function mediaNext() {
            Services.Media.next();
            if (Services.Media.hasPlayer) islandState.peekMedia(2400);
        }
        function mediaPrevious() {
            Services.Media.previous();
            if (Services.Media.hasPlayer) islandState.peekMedia(2400);
        }

        // ------------------------------------------------------------ osd
        function showVolume() {
            Services.System.refreshVolume();
            islandState.showOsd("volume");
        }
        function showMic() { islandState.showOsd("mic"); }
        function showBrightness() {
            Services.System.refreshBrightness();
            islandState.showOsd("brightness");
        }
        function showBattery() { islandState.showOsd("battery"); }
        function showWorkspace() { islandState.showOsd("workspace"); }
        function showNightLight() { islandState.showOsd("nightlight"); }
        function showOsd(kind: string, title: string, text: string) {
            islandState.showOsd(kind, { title: title, text: text });
        }

        // ---------------------------------------------------------- actions
        function volumeUp() {
            Services.System.setVolume(Services.System.volume + 0.05);
            islandState.showOsd("volume");
        }
        function volumeDown() {
            Services.System.setVolume(Services.System.volume - 0.05);
            islandState.showOsd("volume");
        }
        function toggleMute() {
            Services.System.toggleMute();
            islandState.showOsd("volume");
        }
        function toggleMic() {
            Services.System.toggleMicMute();
            islandState.showOsd("mic");
        }
        function brightnessUp() {
            Services.System.stepBrightness(0.05);
            islandState.showOsd("brightness");
        }
        function brightnessDown() {
            Services.System.stepBrightness(-0.05);
            islandState.showOsd("brightness");
        }
        function toggleNightLight() {
            Services.System.toggleNightLight();
            islandState.showOsd("nightlight");
        }

        // ------------------------------------------------------------- lock
        function lock() { if (!lockScreen.locked) lockScreen.lock(); }
        function unlock() { if (lockScreen.locked) lockScreen.unlock(); }

        // ---------------------------------------------------------- modules
        function enableModule(id: string) { Modules.setEnabled(id, true); }
        function disableModule(id: string) { Modules.setEnabled(id, false); }
        function toggleModule(id: string) { Modules.toggle(id); }
        function moveModule(id: string, delta: int) { Modules.move(id, delta); }

        function toggleStyle() {
            settings.style = (settings.style === "notch") ? "pill" : "notch";
        }
        function setStyle(s: string) {
            if (s === "pill" || s === "notch") settings.style = s;
        }

        function openDesktopMenu() { desktopMenu.menuOpen = true; }
        function closeDesktopMenu() { desktopMenu.menuOpen = false; }

        function setTheme(mode: string) {
            Quickshell.execDetached(["wp", "theme", mode]);
            islandState.showOsd("theme");
        }
        function toggleTheme() { setTheme(Theme.dark ? "light" : "dark"); }

        function status(): string {
            return JSON.stringify({
                style: settings.style,
                hidden: islandState.hidden,
                locked: lockScreen.locked,
                mode: islandState.mode,
                flyout: islandState.flyoutKind,
                hubIndex: islandState.hubIndex,
                hubKinds: islandState.hubKinds,
                interactive: islandState.interactive,
                desktopMenu: desktopMenu.menuOpen,
                theme: Theme.dark ? "dark" : "light",
                media: Services.Media.hasPlayer,
                mediaMode: islandState.mode === "media",
                modules: Modules.enabledIds,
                moduleOrder: Modules.order,
                polkitActive: polkitAgent.isActive,
                polkitRegistered: polkitAgent.isRegistered
            });
        }
    }
}
