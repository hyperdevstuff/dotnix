import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import "services" as Services

Item {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Injected
    property var state: null

    // Style
    property bool notchMode: Theme.notchMode
    property real targetRadius: Theme.radius

    // Sizes
    readonly property int pillW: Theme.pillW
    readonly property int pillH: Theme.pillH
    readonly property int expandedW: Theme.expandedW
    readonly property int expandedH: Theme.expandedH

    // Current geometry (animated)
    property real displayedW: pillW
    property real displayedH: pillH

    // Report geometry to IslandWindow for input mask
    function pushGeom() {
        if (parent) {
            parent.capsuleX = x;
            parent.capsuleY = y;
            parent.capsuleW = width;
            parent.capsuleH = height;
            parent.notchMode = notchMode;
        }
    }
    onXChanged: pushGeom()
    onYChanged: pushGeom()
    onWidthChanged: pushGeom()
    onHeightChanged: pushGeom()
    Component.onCompleted: pushGeom()

    // Width/height targets based on state
    readonly property bool expanded: state ? state.active : false

    width: displayedW
    height: displayedH

    Behavior on displayedW { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }
    Behavior on displayedH { NumberAnimation { duration: Motion.morph; easing.type: Motion.easeMorph; easing.bezierCurve: Motion.morphCurve } }

    onExpandedChanged: {
        if (expanded) { displayedW = expandedW; displayedH = expandedH; }
        else { displayedW = pillW; displayedH = pillH; }
    }

    // Top radii: 0 in notch mode
    readonly property real tr: notchMode ? 0 : targetRadius
    readonly property real br: targetRadius

    Rectangle {
        id: capsule
        anchors.fill: parent
        color: Theme.bg
        border.width: notchMode ? 0 : 1
        border.color: Theme.hairline
        topLeftRadius: root.tr
        topRightRadius: root.tr
        bottomLeftRadius: root.br
        bottomRightRadius: root.br
        antialiasing: true

        Behavior on topLeftRadius { NumberAnimation { duration: Motion.morph; easing.type: Easing.OutQuint } }
        Behavior on topRightRadius { NumberAnimation { duration: Motion.morph; easing.type: Easing.OutQuint } }
        Behavior on bottomLeftRadius { NumberAnimation { duration: Motion.morph; easing.type: Easing.OutQuint } }
        Behavior on bottomRightRadius { NumberAnimation { duration: Motion.morph; easing.type: Easing.OutQuint } }
        Behavior on color { ColorAnimation { duration: 200 } }

        // Inner highlight border (pill mode only)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.width: notchMode ? 0 : 1
            border.color: Theme.hairline
            topLeftRadius: Math.max(parent.topLeftRadius - 1, 0)
            topRightRadius: Math.max(parent.topRightRadius - 1, 0)
            bottomLeftRadius: Math.max(parent.bottomLeftRadius - 1, 0)
            bottomRightRadius: Math.max(parent.bottomRightRadius - 1, 0)
            visible: !notchMode
        }

        // Content
        Item {
            id: content
            anchors.fill: parent
            anchors.margins: notchMode ? 8 : 10

            // Idle surface: time
            Text {
                anchors.centerIn: parent
                visible: !root.expanded
                text: Qt.formatTime(clock.date, "HH:mm")
                color: Theme.fg
                font.family: "Roboto"
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            // Expanded surface
            ColumnLayout {
                anchors.fill: parent
                visible: root.expanded
                spacing: 6

                Text {
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: Theme.fg
                    font.family: "Roboto"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }
                Text {
                    text: Qt.formatDate(clock.date, "ddd, MMM d")
                    color: Theme.muted
                    font.pixelSize: 11
                }
                RowLayout {
                    spacing: 10
                    Text { text: Services.System.batteryReady ? ("BAT " + Services.System.batteryPercent + "%" + (Services.System.batteryCharging ? " ⚡" : "")) : "BAT --%"; color: Theme.muted; font.pixelSize: 11 }
                    Text { text: Services.System.volumeMuted ? "VOL MUTED" : ("VOL " + Math.round(Services.System.volume * 100) + "%"); color: Theme.muted; font.pixelSize: 11 }
                    Text { text: "BRI " + Math.round(Services.System.brightness * 100) + "%"; color: Theme.muted; font.pixelSize: 11 }
                }
                Text {
                    text: Services.Media.hasPlayer ? (Services.Media.title + " — " + Services.Media.artist) : "No media"
                    color: Theme.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                RowLayout {
                    spacing: 8
                    Repeater {
                        model: Services.Compositor.workspacesFor(Quickshell.screens[0] ? Quickshell.screens[0].name : "")
                        delegate: Rectangle {
                            required property var modelData
                            width: 14; height: 6; radius: 3
                            color: modelData.raw && modelData.raw.active ? Theme.fg : Theme.hairline
                            MouseArea {
                                anchors.fill: parent
                                onClicked: Services.Compositor.activateWorkspace(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // Concave ears (notch mode only)
    Shape {
        id: leftEar
        visible: root.notchMode
        x: -Theme.earSize
        y: 0
        width: Theme.earSize
        height: Theme.earSize
        ShapePath {
            fillColor: Theme.bg
            strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: Theme.earSize; y: 0 }
            PathLine { x: Theme.earSize; y: Theme.earSize }
            PathArc {
                x: 0; y: 0
                radiusX: Theme.earSize; radiusY: Theme.earSize
                direction: PathArc.Clockwise
            }
        }
    }
    Shape {
        id: rightEar
        visible: root.notchMode
        x: root.width
        y: 0
        width: Theme.earSize
        height: Theme.earSize
        ShapePath {
            fillColor: Theme.bg
            strokeColor: "transparent"
            startX: 0; startY: 0
            PathLine { x: Theme.earSize; y: 0 }
            PathArc {
                x: 0; y: Theme.earSize
                radiusX: Theme.earSize; radiusY: Theme.earSize
                direction: PathArc.Clockwise
            }
            PathLine { x: 0; y: 0 }
        }
    }

    // Clock tick
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: { /* force re-eval by touching a property */ root.displayedW = root.displayedW; }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.state && !root.state.expanded) root.state.expanded = true;
        }
        hoverEnabled: true
        onEntered: { if (root.state && !root.state.expanded) root.state.hoverExpanded = true; }
        onExited:  { if (root.state && !root.state.expanded) root.state.hoverExpanded = false; }
    }
}