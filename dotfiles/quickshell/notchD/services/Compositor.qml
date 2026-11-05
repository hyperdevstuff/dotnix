pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.WindowManager
import Quickshell.Io

// Compositor seam. niri-backed via NDJSON event stream (niri msg --json event-stream).
// Adapted from amanhex/Ukishima Singletons/WmGeneric.qml (MIT) event-stream pattern.
// niri-only in practice; everything talks to this object.
Singleton {
    id: root

    readonly property bool available: true
    readonly property string compositor: Quickshell.env("NIRI_SOCKET") ? "niri" : "generic"

    // Live state from niri's event stream.
    property var workspacesData: []
    property var windowsData: []
    property bool overviewOpen: false

    // Restart the event stream if it exits.
    Timer {
        id: restartTimer
        interval: 1000
        repeat: false
        onTriggered: { eventProc.running = true; }
    }

    Process {
        id: eventProc
        running: root.compositor === "niri"
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: (line) => root.handleEventLine(line)
        }
        onExited: {
            restartTimer.start();
        }
    }

    function handleEventLine(line) {
        if (!line) return;
        const l = String(line).trim();
        if (l.length === 0) return;
        let ev;
        try { ev = JSON.parse(l); }
        catch (e) { console.warn("Compositor: malformed event:", e); return; }
        if (!ev || typeof ev !== "object") return;

        if (ev.WorkspacesChanged && ev.WorkspacesChanged.workspaces) {
            root.workspacesData = ev.WorkspacesChanged.workspaces;
        } else if (ev.WindowsChanged && ev.WindowsChanged.windows) {
            root.windowsData = ev.WindowsChanged.windows;
        } else if (ev.OverviewOpenedOrClosed) {
            root.overviewOpen = !!ev.OverviewOpenedOrClosed.is_open;
        }
        // KeyboardLayoutsChanged / ConfigLoaded / CastsChanged are acknowledged
        // but not consumed by this seam.
    }

    function workspaceById(id) {
        const list = root.workspacesData || [];
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].id === id) return list[i];
        return null;
    }

    readonly property var windows: {
        const out = [];
        const ws = root.windowsData || [];
        for (let i = 0; i < ws.length; i++) {
            const w = ws[i];
            if (!w) continue;
            const wr = root.workspaceById(w.workspace_id);
            const output = wr ? String(wr.output || "") : "";
            const screens = output ? [output] : [];
            out.push({
                id: String(w.id),
                appId: String(w.app_id || ""),
                title: String(w.title || ""),
                pid: w.pid,
                workspaceId: w.workspace_id,
                workspace: { id: w.workspace_id, name: wr && wr.name ? String(wr.name) : (wr ? String(wr.idx) : ""), raw: wr },
                active: !!w.is_focused,
                activated: !!w.is_focused,
                minimized: false,
                fullscreen: false,
                isFloating: !!w.is_floating,
                isUrgent: !!w.is_urgent,
                screens: screens,
                raw: w
            });
        }
        return out;
    }

    function focusedScreen() {
        // Prefer the focused workspace's output.
        const list = root.workspacesData || [];
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (w && w.is_focused) return String(w.output || "");
        }
        const t = ToplevelManager.activeToplevel;
        const own = t && t.screens && t.screens.length > 0 ? t.screens[0] : null;
        if (own && own.name) return String(own.name);
        const s = Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
        return s && s.name ? String(s.name) : "";
    }

    function screenFor(output) {
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i] && Quickshell.screens[i].name === output)
                return Quickshell.screens[i];
        return null;
    }

    function workspacesFor(output) {
        const out = [];
        const list = root.workspacesData || [];
        for (let i = 0; i < list.length; i++) {
            const w = list[i];
            if (!w || String(w.output) !== String(output)) continue;
            out.push({
                id: String(w.id),
                idx: w.idx,
                name: w.name ? String(w.name) : String(w.idx),
                output: String(w.output || ""),
                isUrgent: !!w.is_urgent,
                isActive: !!w.is_active,
                isFocused: !!w.is_focused,
                activeWindowId: w.active_window_id,
                raw: { id: w.id, idx: w.idx, name: w.name, active: !!w.is_active, focused: !!w.is_focused }
            });
        }
        out.sort(function (a, b) {
            const ia = (a.idx != null) ? a.idx : 0;
            const ib = (b.idx != null) ? b.idx : 0;
            if (ia !== ib) return ia - ib;
            return String(a.name).localeCompare(String(b.name));
        });
        return out;
    }

    function activateWorkspace(ws) {
        if (!ws) return;
        const raw = ws.raw || {};
        let ref = null;
        if (raw.name) ref = String(raw.name);
        else if (raw.idx != null) ref = String(raw.idx);
        else if (ws.idx != null) ref = String(ws.idx);
        else ref = String(ws.name || "");
        if (root.compositor === "niri" && ref) {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", ref]);
            return;
        }
        if (ws.raw && ws.raw.canActivate) ws.raw.activate();
    }

    function activeWorkspaceName(output) {
        const list = root.workspacesFor(output);
        for (let i = 0; i < list.length; i++)
            if (list[i].raw && list[i].raw.active) return list[i].name;
        return "";
    }

    function fullscreenOn(output) {
        // niri event stream does not expose fullscreen; fall back to active toplevel.
        const t = ToplevelManager.activeToplevel;
        return !!(t && t.fullscreen);
    }
}
