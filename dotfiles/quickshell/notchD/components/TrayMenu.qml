import QtQuick
import QtQuick.Controls
import Quickshell
import ".."

Menu {
    id: root
    property var menuHandle: null
    property var entry: null
    property var submenuComponent: Qt.createComponent("TrayMenu.qml")
    title: entry ? entry.text : ""
    enabled: entry ? entry.enabled : true
    popupType: Popup.Window
    implicitWidth: {
        let widest = 216;
        for (let index = 0; index < count; index++) {
            const row = itemAt(index);
            if (row) widest = Math.max(widest, row.implicitWidth);
        }
        return Math.min(360, widest);
    }
    padding: 6
    overlap: 2
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    delegate: TrayMenuItem {
        entry: subMenu ? subMenu.entry : null
    }
    background: Rectangle {
        radius: 10
        color: Theme.bgElev
        border.color: Theme.hairline
    }
    QsMenuOpener {
        id: opener
        menu: root.visible ? root.menuHandle : null
    }
    Instantiator {
        model: opener.children
        delegate: QtObject {
            required property var modelData
            readonly property var entry: modelData
            readonly property bool isSubmenu: entry && entry.hasChildren && !entry.isSeparator
            property var control: {
                if (entry.isSeparator)
                    return separatorComponent.createObject(root.contentItem);
                if (entry.hasChildren)
                    return root.submenuComponent.createObject(root, {
                        entry: entry,
                        menuHandle: entry
                    });
                return itemComponent.createObject(root.contentItem, {
                    entry: entry
                });
            }
        }
        onObjectAdded: (index, object) => {
            if (object.isSubmenu)
                root.insertMenu(index, object.control);
            else
                root.insertItem(index, object.control);
        }
        onObjectRemoved: (index, object) => {
            if (object.isSubmenu)
                root.removeMenu(object.control);
            else
                root.removeItem(object.control);
            object.control.destroy();
        }
    }
    Component {
        id: itemComponent
        TrayMenuItem {
            onTriggered: if (entry)
                entry.triggered()
        }
    }
    Component {
        id: separatorComponent
        MenuSeparator {
            padding: 0
            implicitHeight: 9
            contentItem: Rectangle {
                implicitHeight: 1
                color: Theme.hairline
            }
            leftPadding: 8
            rightPadding: 8
            topPadding: 4
            bottomPadding: 4
        }
    }
}
