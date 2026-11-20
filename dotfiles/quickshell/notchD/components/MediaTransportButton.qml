/*
Adapted from duxlabs-dev/dux-shell (commit aa3dc8bbc08707f67ef0e6c4f319c2ff628966d4).
MIT License

Copyright (c) 2025 Avenge Media LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
import QtQuick
import ".."

Item {
    id: root
    property string glyph: ""
    property string label: ""
    property bool primary: false
    signal clicked
    implicitWidth: primary ? 48 : 32
    implicitHeight: primary ? 48 : 32
    activeFocusOnTab: enabled
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: if (enabled)
        clicked()
    opacity: enabled ? 1 : 0.4
    Keys.onPressed: event => {
        if (!event.isAutoRepeat && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            root.clicked();
            event.accepted = true;
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.primary ? Theme.accent : (mouse.containsMouse || root.activeFocus ? Theme.track : "transparent")
        scale: mouse.pressed ? 0.97 : 1
        Behavior on scale {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
        Icon {
            anchors.centerIn: parent
            glyph: root.glyph
            size: 13
            tint: root.primary ? Theme.accentInk : Theme.fg
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
