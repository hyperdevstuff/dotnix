import QtQuick
import QtQuick.Layouts
import ".."
import "../services" as Services

Flickable {
    id: root
    property var state: null
    contentWidth: width
    contentHeight: content.implicitHeight
    activeFocusOnTab: true
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) contentY = Math.min(Math.max(0, contentHeight - height), contentY + (event.key === Qt.Key_Down ? 40 : height));
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) contentY = Math.max(0, contentY - (event.key === Qt.Key_Up ? 40 : height));
        else return;
        event.accepted = true;
    }
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    ColumnLayout {
        id: content
        width: root.width
        spacing: 12
        Text {
            Layout.leftMargin: 46
            Layout.preferredHeight: 36
            verticalAlignment: Text.AlignVCenter
            text: "Background apps"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 18 * Theme.textScale
            font.weight: Font.DemiBold
        }
        Text {
            Layout.fillWidth: true
            text: Services.Tray.count ? "Click to open an app. Right-click for its menu." : "No apps have registered a tray icon."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 12 * Theme.textScale
            wrapMode: Text.Wrap
        }
        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: Services.Tray.items
                delegate: TrayButton {
                    required property var modelData
                    item: modelData
                    showLabel: true
                    width: Math.max(1, (parent.width - 8 * (Math.max(1, Math.floor(parent.width / 200)) - 1)) / Math.max(1, Math.floor(parent.width / 200)))
                    onActivated: if (root.state)
                        root.state.collapse()
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: Services.Tray.count === 0
            text: "Apps appear here when they offer a system-tray icon. Enable that option in the app if needed."
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 12 * Theme.textScale
            wrapMode: Text.Wrap
        }
    }
}
