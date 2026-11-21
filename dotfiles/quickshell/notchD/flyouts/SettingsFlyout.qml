import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

// Module settings: enable, disable and reorder the built-in registry.
// Changes apply immediately to the hub and are persisted by shell.qml.
FlyoutFrame {
    id: root

    title: "Modules"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: "Enabled modules appear in this order. Use the arrows to reorder; changes apply immediately and persist."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11 * Theme.textScale
            wrapMode: Text.WordWrap
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: list.height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width
                spacing: 5

                Repeater {
                    model: Modules.order

                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index

                        readonly property bool isEnabled: Modules.isEnabled(modelData)
                        readonly property var info: Modules.manifest(modelData)

                        width: list.width
                        height: 50
                        radius: Theme.radiusSmall
                        color: rowMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: 1
                        border.color: Theme.hairlineSoft
                        opacity: row.isEnabled ? 1.0 : 0.62

                        Behavior on color { ColorAnimation { duration: 110 } }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: Theme.radiusControl
                                color: Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
                                Icon {
                                    anchors.centerIn: parent
                                    glyph: row.info ? String(row.info.icon) : "\uf128"
                                    size: 12
                                    tint: row.isEnabled ? Theme.fg : Theme.muted
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: row.info ? String(row.info.title) : String(row.modelData)
                                    color: Theme.fg
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11 * Theme.textScale
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.info ? String(row.info.description) : ""
                                    color: Theme.muted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11 * Theme.textScale
                                    elide: Text.ElideRight
                                }
                            }

                            // Reorder controls.
                            ColumnLayout {
                                spacing: 1

                                Rectangle {
                                    width: 22
                                    height: 15
                                    radius: 4
                                    color: upMouse.containsMouse ? Theme.surfacePress : "transparent"
                                    opacity: row.index > 0 ? 1.0 : 0.25
                                    Icon {
                                        anchors.centerIn: parent
                                        glyph: "\uf077"
                                        size: 9
                                        tint: Theme.muted
                                    }
                                    MouseArea {
                                        id: upMouse
                                        anchors.fill: parent
                                        enabled: row.index > 0
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Modules.move(row.modelData, -1)
                                    }
                                }

                                Rectangle {
                                    width: 22
                                    height: 15
                                    radius: 4
                                    color: downMouse.containsMouse ? Theme.surfacePress : "transparent"
                                    opacity: row.index < Modules.order.length - 1 ? 1.0 : 0.25
                                    Icon {
                                        anchors.centerIn: parent
                                        glyph: "\uf078"
                                        size: 9
                                        tint: Theme.muted
                                    }
                                    MouseArea {
                                        id: downMouse
                                        anchors.fill: parent
                                        enabled: row.index < Modules.order.length - 1
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Modules.move(row.modelData, 1)
                                    }
                                }
                            }

                            Toggle {
                                checked: row.isEnabled
                                onToggled: Modules.setEnabled(row.modelData, !row.isEnabled)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.hairlineSoft
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Icon { glyph: "\uf05a"; size: 10; tint: Theme.muted }
            Text {
                Layout.fillWidth: true
                text: "Disabled modules unload their flyout. Services stay native Quickshell singletons and are shared."
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11 * Theme.textScale
                wrapMode: Text.WordWrap
            }
        }
    }
}
