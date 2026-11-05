pragma Singleton

import QtQuick
import Quickshell

// Vercel-style black/white pill. Replaces themes.js.
// Single palette: black bg, white fg, hairline border.
Singleton {
    id: root

    readonly property bool dark: true

    // Surfaces
    readonly property color bg:        "#0a0a0a"
    readonly property color bgElev:    "#161616"
    readonly property color fg:        "#fafafa"
    readonly property color muted:     "#8f8f8f"
    readonly property color hairline:  "#262626"
    readonly property color accent:    "#ffffff"

    // Notch geometry
    readonly property real radius:    16
    readonly property real earSize:   10
    readonly property bool notchMode: true   // pill | notch

    // Sizes
    readonly property int pillW:      76
    readonly property int pillH:      30
    readonly property int expandedW:  340
    readonly property int expandedH:  150
}