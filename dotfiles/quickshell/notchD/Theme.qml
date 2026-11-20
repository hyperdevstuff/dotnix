pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Live matugen semantic palette, light and dark.
// `dark` follows ~/.config/matugen/generated/mode, which `wp theme` writes.
// Single palette source: shell.qml flips `Theme.dark`, every surface follows.
//
// Readability rules for the 14" 1080p panel (niri scale 1.1, ~130 logical PPI):
// no text below 11px, body is 12px, the hub clock is 14px, and there are only
// three radii. Those constraints are what keep the island from looking like a
// widget collage.
Singleton {
    id: root

    property bool dark: true
    property real surfaceOpacity: 1.0

    property var palettes: ({})
    readonly property var palette: palettes[dark ? "dark" : "light"] || ({})
    function tone(name, fallback) {
        return palette[name] || fallback;
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/matugen/generated/notchd-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: {
            try {
                root.palettes = JSON.parse(text());
            } catch (e) {}
        }
    }

    // Typography
    readonly property string fontFamily: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Type scale (logical px). Do not add anything smaller than 11.
    readonly property int fontDisplay: 14
    readonly property int fontTitle: 12
    readonly property int fontBody: 12
    readonly property int fontLabel: 11
    readonly property int fontValue: 12

    // Shared matugen surfaces. Only the outer panel uses the persisted opacity.
    readonly property color bg: tone("background", dark ? "#0a0a0a" : "#fafafa")
    readonly property color bgElev: tone("surface_container", dark ? "#161616" : "#ffffff")
    readonly property color panel: Qt.rgba(panelSolid.r, panelSolid.g, panelSolid.b, Math.max(0.7, Math.min(1, surfaceOpacity)))
    readonly property color panelSolid: tone("surface", dark ? "#0b0b0b" : "#fafafa")
    readonly property color surface: tone("surface_container", dark ? "#141414" : "#ffffff")
    readonly property color surfaceHover: tone("surface_container_high", dark ? "#1e1e1e" : "#f1f1f2")
    readonly property color surfacePress: tone("surface_container_highest", dark ? "#272727" : "#e8e8ea")
    readonly property color fg: tone("on_surface", dark ? "#fafafa" : "#0a0a0a")
    // 8f8f8f fails contrast at 11px; a1a1aa is the smallest legible muted.
    readonly property color muted: tone("on_surface_variant", dark ? "#a1a1aa" : "#52525b")
    readonly property color hairline: tone("outline_variant", dark ? "#262626" : "#e4e4e7")
    readonly property color hairlineSoft: tone("outline_variant", dark ? "#1d1d1d" : "#efeff1")
    readonly property color accent: tone("primary", dark ? "#ffffff" : "#000000")
    readonly property color accentInk: tone("on_primary", dark ? "#0a0a0a" : "#ffffff")
    readonly property color accentContainer: tone("primary_container", dark ? "#38301c" : "#f4e4b9")
    readonly property color accentContainerInk: tone("on_primary_container", dark ? "#f4e4b9" : "#28200d")
    readonly property color secondary: tone("secondary", dark ? "#cbc5a6" : "#625f46")
    readonly property color track: tone("surface_container_highest", dark ? "#333333" : "#e4e4e7")

    // Status
    readonly property color ok: dark ? "#4ade80" : "#16a34a"
    readonly property color warn: dark ? "#fbbf24" : "#d97706"
    readonly property color danger: dark ? "#f87171" : "#dc2626"
    readonly property color info: dark ? "#93c5fd" : "#2563eb"

    // Shape scale: card / control / pill. Nothing else.
    readonly property real radius: 16
    readonly property real radiusControl: 16
    readonly property real radiusSmall: 10   // legacy alias for controls
    readonly property real radiusPill: 16
    readonly property real earSize: 10
    property bool notchMode: false

    // Dashboard size and compact activity sizes; detail pages replace the hub.
    readonly property int pillW: 60
    // Extra width while the idle pill carries a compact now-playing indicator.
    readonly property int pillMediaExtra: 76
    readonly property int pillH: 26
    readonly property int osdW: 196
    readonly property int osdH: 32
    readonly property int hubW: 980
    readonly property int hubH: 524
    // Dashboard width is bounded by the output in NotchD.qml.
    readonly property int hubSidePad: 6
    readonly property int mediaW: 400
    readonly property int mediaH: 150
    readonly property int flyoutW: 380
    readonly property int flyoutH: 520
    readonly property int authW: 380
    readonly property int authH: 320
    readonly property int gap: 8
    readonly property int pad: 12
    readonly property int rowH: 48
    readonly property int tileH: 54
    readonly property int headerH: 36

    // The pill floats a few pixels below the screen edge so it does not look
    // glued to the bezel. Notch mode stays flush on purpose.
    readonly property int topGap: notchMode ? 0 : 6
}
