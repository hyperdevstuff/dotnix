import QtQuick
import ".."
import "../services" as Services

// Night-light tint surface. This machine's NVIDIA output rejects
// wlr-gamma-control, so instead of a gamma ramp we blend a warm full-screen
// colour. The window that hosts this item is click-through (empty mask) and
// takes no keyboard focus, so it behaves like a physical amber filter.
Rectangle {
    id: root

    color: Services.System.nightLightColor
    opacity: Services.System.nightLightAlpha

    Behavior on opacity {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }
    Behavior on color {
        ColorAnimation {
            duration: 220
        }
    }
}
