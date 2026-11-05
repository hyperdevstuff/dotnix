pragma Singleton

import QtQuick
import Quickshell

// Duration/easing tokens adapted from Ukishima Singletons/Motion.qml.
// Dropped the Flags dependency (no animation-style settings in NotchD).
Singleton {
    id: root

    readonly property real mult: 1.0
    readonly property int fast:     Math.round(140 * mult)
    readonly property int standard: Math.round(300 * mult)
    readonly property int morph:    Math.round(420 * mult)
    readonly property int shapeshift: Math.round(820 * mult)
    readonly property int glide:    Math.round(260 * mult)
    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeMorph:    Easing.BezierSpline
    readonly property var morphCurve: [0.16, 1, 0.3, 1, 1, 1]
    readonly property int rSmall: 7
    readonly property int rTile:  13

    // Reduced-motion helper
    readonly property bool reduceMotion: false
}