import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../services" as Services

// Read-only sidebar for the lock screen: the current media activity and the
// most recent notifications. It is intentionally passive — no actions, no
// dismissal and no keyboard focus — so nothing can be invoked while locked.
//
// It is hidden entirely on narrow outputs and when there is nothing to show,
// because the centre column (password) always wins the space.
Item {
    id: root

    readonly property var notes: Services.Notifications.items || []
    readonly property var recentNotes: notes.slice(0, 3)
    readonly property bool hasActivity: Services.Media.hasPlayer
    readonly property bool hasNotes: notes.length > 0

    // The lock owner supplies its dark matugen palette even in light mode.
    property color ink: "#f5f5f5"
    property color inkSoft: "#b8b8bf"
    property color card: Qt.rgba(1, 1, 1, 0.07)

    implicitWidth: 320
    implicitHeight: column.implicitHeight
    clip: true

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 10

        // ------------------------------------------------------- activity
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: activity.implicitHeight + 28
            visible: root.hasActivity
            radius: 28
            color: root.card

            ColumnLayout {
                id: activity
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 56
                        Layout.preferredHeight: 56
                        radius: 14
                        color: Qt.rgba(1, 1, 1, 0.06)
                        clip: true

                        Image {
                            id: art
                            anchors.fill: parent
                            source: Services.Media.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: !art.visible
                            glyph: Services.Media.playing ? "\uf001" : "\uf04b"
                            size: 16
                            tint: root.inkSoft
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: Services.Media.title || "Now playing"
                            color: root.ink
                            font.family: Theme.fontFamily
                            font.pixelSize: 15 * Theme.textScale
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Services.Media.artist || "Unknown artist"
                            color: root.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13 * Theme.textScale
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }
                    }
                }

                // Progress is a passive read: it never offers a seek target.
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    visible: Services.Media.length > 0

                    Rectangle {
                        anchors.fill: parent
                        radius: 1
                        color: Qt.rgba(1, 1, 1, 0.16)
                    }

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Services.Media.position / Math.max(1, Services.Media.length)))
                        height: parent.height
                        radius: 1
                        color: root.ink
                    }
                }
            }
        }

        // -------------------------------------------------- notifications
        Text {
            Layout.fillWidth: true
            Layout.topMargin: root.hasActivity ? 4 : 0
            visible: root.hasNotes
            text: "NOTIFICATIONS"
            color: root.inkSoft
            font.family: Theme.fontFamily
            font.pixelSize: 13 * Theme.textScale
            font.weight: Font.DemiBold
            font.letterSpacing: 1.1
            textFormat: Text.PlainText
        }

        Repeater {
            model: root.recentNotes

            delegate: Rectangle {
                id: noteCard

                required property var modelData
                readonly property var note: modelData

                readonly property string iconSource: {
                    if (!note)
                        return "";
                    if (note.image && note.image.length > 0)
                        return note.image;
                    const icon = note.appIcon || "";
                    if (icon.length === 0)
                        return "";
                    if (icon.startsWith("/"))
                        return "file://" + icon;
                    return Quickshell.iconPath(icon, true);
                }

                Layout.fillWidth: true
                Layout.preferredHeight: noteBody.implicitHeight + 28
                radius: 28
                color: root.card

                RowLayout {
                    id: noteBody
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 14
                    spacing: 9

                    Rectangle {
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.06)

                        Image {
                            id: noteIcon
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: noteCard.iconSource
                            sourceSize.width: 36
                            sourceSize.height: 36
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                            visible: source !== "" && status === Image.Ready
                        }

                        Icon {
                            anchors.centerIn: parent
                            visible: !noteIcon.visible
                            glyph: "\uf0f3"
                            size: 13
                            tint: root.inkSoft
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: noteCard.note ? (noteCard.note.appName || "Notification") : ""
                            color: root.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13 * Theme.textScale
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }

                        Text {
                            Layout.fillWidth: true
                            text: noteCard.note ? (noteCard.note.summary || "") : ""
                            color: root.ink
                            font.family: Theme.fontFamily
                            font.pixelSize: 15 * Theme.textScale
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: noteCard.note ? (noteCard.note.body || "") : ""
                            color: root.inkSoft
                            font.family: Theme.fontFamily
                            font.pixelSize: 13 * Theme.textScale
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            textFormat: Text.PlainText
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: root.notes.length > root.recentNotes.length
            text: "+" + (root.notes.length - root.recentNotes.length) + " more"
            color: root.inkSoft
            font.family: Theme.fontFamily
            font.pixelSize: 13 * Theme.textScale
            textFormat: Text.PlainText
        }
    }
}
