import QtQuick
import Quickshell

// State machine for the island. Drives NotchD.qml and shell.qml.
//
//   idle ── click / Mod+N ──> hub ── chip ──> flyout (sideways)
//     ▲                        │                │
//     │                        └── media chip ──> media (downward)
//     └──── Escape / outside ──┴──── back ──────┘
//
// OSD and media peeks are transient and never clobber an open hub/flyout.
// Polkit authentication temporarily takes over the island and restores the
// previous surface when it finishes.
Item {
    id: root

    // Visibility
    property bool hidden: false
    readonly property bool shown: !hidden

    // Current surface: idle | osd | hub | flyout | media | auth
    property string mode: "idle"
    property string flyoutKind: ""

    // Hub keyboard focus. The chip order follows the module registry, so
    // disabling or reordering a module changes navigation too.
    property int hubIndex: 0
    readonly property var hubKinds: Modules.enabledIds
    readonly property int hubCount: hubKinds.length
    readonly property string hubKind: hubCount > 0
        ? hubKinds[Math.max(0, Math.min(hubIndex, hubCount - 1))]
        : ""

    // Transient OSD
    property string osdKind: "generic"
    property string osdTitle: ""
    property string osdText: ""
    property string osdValue: ""
    property real osdProgress: -1
    property int osdTimeoutMs: 2200

    // Media return state. A hub click returns to the hub; an automatic peek
    // returns to idle.
    property string mediaReturnMode: "idle"

    // Polkit return state
    property string authReturnMode: "idle"
    property string authReturnFlyout: ""

    readonly property bool mediaOpen: mode === "media"
    readonly property bool interactive: mode === "hub" || mode === "flyout"
        || mode === "media" || mode === "auth"
    readonly property bool active: !hidden && mode !== "idle"
    readonly property bool osdVisible: !hidden && mode === "osd"

    function setHidden(value) {
        if (hidden === value) return;
        hidden = value;
        if (hidden) collapse();
    }

    // Legacy surface peeks: peek("osd") or peek("workspace").
    function peek(surface, ms) {
        if (hidden) return;
        if (interactive) return;
        showOsd(surface || "generic", {}, ms);
    }

    function showOsd(kind, opts, ms) {
        if (hidden) return;
        if (interactive) return;
        const o = opts || {};
        osdKind = kind || "generic";
        osdTitle = o.title !== undefined ? String(o.title) : "";
        osdText = o.text !== undefined ? String(o.text) : "";
        osdValue = o.value !== undefined ? String(o.value) : "";
        osdProgress = o.progress !== undefined ? Number(o.progress) : -1;
        mode = "osd";
        osdTimer.interval = (ms && ms > 0) ? ms : osdTimeoutMs;
        osdTimer.restart();
    }

    function hideOsd() {
        if (mode === "osd") mode = "idle";
        osdTimer.stop();
    }

    function clampHubIndex() {
        const count = Modules.enabledIds.length;
        if (count <= 0) { hubIndex = 0; return; }
        hubIndex = Math.max(0, Math.min(hubIndex, count - 1));
    }

    function openHub() {
        hidden = false;
        stopPeeks();
        flyoutKind = "";
        mode = "hub";
        clampHubIndex();
    }

    function openFlyout(kind) {
        if (!kind) return;
        // Clicking the active chip (or re-issuing the same IPC) closes it.
        if (mode === "flyout" && flyoutKind === String(kind)) {
            mode = "hub";
            flyoutKind = "";
            return;
        }
        hidden = false;
        stopPeeks();
        flyoutKind = String(kind);
        const i = hubKinds.indexOf(flyoutKind);
        if (i >= 0) hubIndex = i;
        mode = "flyout";
    }

    function activateHubIndex(index) {
        if (hubCount <= 0) return;
        const i = Math.max(0, Math.min(Number(index) || 0, hubCount - 1));
        hubIndex = i;
        openFlyout(hubKinds[i]);
    }

    // Linear navigation across the chip row. dx moves; dy is accepted so the
    // callers can keep the old 2D contract without changing behaviour.
    function moveHubFocus(dx, dy) {
        if (hubCount <= 0) return;
        hubIndex = Math.max(0, Math.min(hubCount - 1, hubIndex + Number(dx || 0)));
    }

    // --------------------------------------------------------------- media
    function openMedia() {
        hidden = false;
        stopPeeks();
        mediaReturnMode = "hub";
        flyoutKind = "";
        mode = "media";
        clampHubIndex();
    }

    function peekMedia(ms) {
        if (hidden) return;
        if (interactive) return;
        osdTimer.stop();
        mediaReturnMode = "idle";
        mode = "media";
        mediaTimer.interval = (ms && ms > 0) ? ms : 4200;
        mediaTimer.restart();
    }

    function closeMedia() {
        mediaTimer.stop();
        if (mode === "media") mode = mediaReturnMode === "hub" ? "hub" : "idle";
    }

    // One step back: media -> hub/idle, flyout -> hub, then idle.
    // Auth -> previous surface.
    function back() {
        if (mode === "auth") { closeAuth(); return; }
        if (mode === "media") {
            mediaTimer.stop();
            if (mediaReturnMode === "hub") { mode = "hub"; }
            else { mode = "idle"; }
            return;
        }
        if (mode === "flyout") { mode = "hub"; flyoutKind = ""; return; }
        collapse();
    }

    function collapse() {
        stopPeeks();
        flyoutKind = "";
        mode = "idle";
    }

    function stopPeeks() {
        osdTimer.stop();
        mediaTimer.stop();
    }

    function toggleExpanded() {
        // A polkit prompt owns the surface; never dismiss it from a keybind.
        if (mode === "auth") return;
        if (hidden) { hidden = false; stateIdle(); return; }
        if (interactive) collapse();
        else openHub();
    }

    function stateIdle() {
        mode = "idle";
        flyoutKind = "";
        stopPeeks();
    }

    function openAuth() {
        if (mode === "auth") return;
        authReturnMode = mode;
        authReturnFlyout = flyoutKind;
        stopPeeks();
        mode = "auth";
    }

    function closeAuth() {
        const previous = authReturnMode;
        const previousFlyout = authReturnFlyout;
        authReturnMode = "idle";
        authReturnFlyout = "";
        if (previous === "flyout" && previousFlyout) {
            mode = "flyout";
            flyoutKind = previousFlyout;
        } else if (previous === "hub") {
            mode = "hub";
            flyoutKind = "";
        } else {
            mode = "idle";
            flyoutKind = "";
        }
    }

    // Kept for callers that still use the old name.
    function toggle() { setHidden(!hidden); }

    Timer {
        id: osdTimer
        onTriggered: {
            if (root.mode === "osd") root.mode = "idle";
        }
    }

    Timer {
        id: mediaTimer
        onTriggered: {
            if (root.mode === "media" && root.mediaReturnMode === "idle")
                root.mode = "idle";
        }
    }
}
