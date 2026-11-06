pragma Singleton

import QtQuick
import Quickshell

// Vercel-style black/white palette, light and dark.
// `dark` follows ~/.config/matugen/generated/mode, which `wp theme` writes.
// Single palette source: shell.qml flips `Theme.dark`, every surface follows.
Singleton {
    id: root

    property bool dark: true

    // Typography
    readonly property string fontFamily: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"

    // Surfaces. Panel colors are translucent so niri can blur behind them.
    readonly property color bg:          dark ? "#0a0a0a" : "#fafafa"
    readonly property color bgElev:      dark ? "#161616" : "#ffffff"
    readonly property color panel:       dark ? "#d90b0b0b" : "#e8fafafa"
    readonly property color panelSolid:  dark ? "#0b0b0b" : "#fafafa"
    readonly property color surface:     dark ? "#141414" : "#ffffff"
    readonly property color surfaceHover: dark ? "#1f1f1f" : "#f1f1f2"
    readonly property color surfacePress: dark ? "#272727" : "#e8e8ea"
    readonly property color fg:          dark ? "#fafafa" : "#0a0a0a"
    readonly property color muted:       dark ? "#8f8f8f" : "#71717a"
    readonly property color hairline:    dark ? "#2a2a2a" : "#e4e4e7"
    readonly property color hairlineSoft: dark ? "#1d1d1d" : "#efeff1"
    readonly property color accent:      dark ? "#ffffff" : "#000000"
    readonly property color accentInk:   dark ? "#0a0a0a" : "#ffffff"
    readonly property color track:       dark ? "#333333" : "#e4e4e7"

    // Status
    readonly property color ok:     dark ? "#4ade80" : "#16a34a"
    readonly property color warn:   dark ? "#fbbf24" : "#d97706"
    readonly property color danger: dark ? "#f87171" : "#dc2626"
    readonly property color info:   dark ? "#93c5fd" : "#2563eb"

    // Geometry
    readonly property real radius:      18
    readonly property real radiusSmall: 11
    readonly property real radiusPill:  15
    readonly property real earSize:     10
    readonly property bool notchMode:   false   // pill | notch

    // Sizes. The hub is a single horizontal chip row; everything except media
    // opens sideways as a flyout, media opens as a card below the hub.
    readonly property int pillW:      76
    readonly property int pillH:      30
    readonly property int osdW:       300
    readonly property int osdH:       44
    readonly property int hubW:       760
    readonly property int hubH:       60
    readonly property int mediaW:     380
    readonly property int mediaH:     132
    readonly property int flyoutW:    330
    readonly property int flyoutH:    450
    readonly property int authW:      340
    readonly property int authH:      250
    readonly property int gap:        10
    readonly property int pad:        14
    readonly property int tileH:      54
    readonly property int rowH:       46
    readonly property int headerH:    40
}
