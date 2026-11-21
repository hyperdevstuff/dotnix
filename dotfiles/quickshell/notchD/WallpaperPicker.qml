import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components" as Components
import "services" as Services

// Native wallpaper switcher: a compact bottom sheet with a selected preview
// and a horizontal filmstrip of thumbnails.
//
// Design constraints kept deliberately:
//   * no opaque full-screen window while hidden — both layer surfaces are
//     `visible: shown`, and the full-screen dismiss layer has a subtracted
//     mask, so clicks pass through to the desktop the rest of the time;
//   * keyboard focus is grabbed only while shown (Exclusive -> None);
//   * applying goes through `wp <exact path>` (awww + matugen) and never
//     reimplements theme generation;
//   * `screen` defaults to the primary screen but can be set by the caller,
//     which is the multi-screen integration point.
//
// Contract for the instantiating module:
//   WallpaperPicker {
//       shown: <bool>
//       onCloseRequested: <set shown false / close IPC path>
//       // screen: shell.primaryScreen   (optional)
//   }
Item {
    id: root

    property bool shown: false
    signal closeRequested()

    // Optional: defaults to the primary screen. Set explicitly on a
    // multi-screen setup if the picker should follow a particular output.
    property var screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    property string searchText: ""
    property int selectedIndex: -1
    property bool favoritesOnly: false

    readonly property var catalog: Services.WallpaperCatalog
    readonly property bool busy: catalog.status === "loading" || catalog.status === "idle"
    readonly property bool errored: catalog.status === "error"

    // Search is local to the picker so two pickers never fight over state.
    readonly property var results: {
        const q = root.searchText.trim().toLowerCase();
        const all = catalog.items;
        return all.filter(p => (!root.favoritesOnly || catalog.isFavorite(p))
            && (!q || catalog.displayName(p).toLowerCase().indexOf(q) >= 0));
    }

    readonly property string selectedPath: (root.selectedIndex >= 0 && root.selectedIndex < results.length)
        ? results[root.selectedIndex] : ""

    readonly property int panelH: {
        const h = root.screen ? root.screen.height : 1080;
        return Math.min(h, 410);
    }

    // ------------------------------------------------------------- behaviour
    function selectAt(i) {
        if (i < 0 || i >= results.length) return;
        root.selectedIndex = i;
        strip.positionViewAtIndex(i, ListView.Contain);
    }

    function move(delta) {
        if (!results.length) return;
        let i = root.selectedIndex;
        if (i < 0) i = delta > 0 ? -1 : 0;
        let n = i + delta;
        if (n < 0) n = 0;
        if (n >= results.length) n = results.length - 1;
        selectAt(n);
    }

    function resetSelection(preferCurrent) {
        const list = root.results;
        let idx = -1;
        if (preferCurrent && catalog.currentPath)
            idx = list.indexOf(catalog.currentPath);
        if (idx < 0) idx = list.length ? 0 : -1;
        root.selectedIndex = idx;
        if (idx >= 0) strip.positionViewAtIndex(idx, ListView.Contain);
    }

    function applySelection() {
        if (!selectedPath || root.busy || root.errored) return;
        catalog.apply(selectedPath);
        root.closeRequested();
    }

    onShownChanged: {
        if (root.shown) {
            root.searchText = "";
            root.favoritesOnly = false;
            searchField.text = "";
            root.selectedIndex = -1;
            root.catalog.reload();
            Qt.callLater(() => focusTarget.forceActiveFocus());
        }
    }

    onSearchTextChanged: {
        const n = root.results.length;
        root.selectedIndex = n ? 0 : -1;
        if (n) strip.positionViewAtIndex(0, ListView.Contain);
    }

    onFavoritesOnlyChanged: resetSelection(false)
    onResultsChanged: {
        if (selectedIndex >= results.length) selectedIndex = results.length - 1;
        if (selectedIndex < 0 && results.length && !busy) selectedIndex = 0;
    }

    Connections {
        target: catalog
        function onStatusChanged() {
            if (!root.shown) return;
            if (catalog.status === "ready" || catalog.status === "empty")
                root.resetSelection(true);
        }
    }

    // ---------------------------------------------------------- dismiss layer
    // Full-screen but never mapped while hidden. Its mask subtracts the picker
    // rectangle, so clicks inside the picker reach it and clicks anywhere
    // else close it. No keyboard focus is ever taken here.
    PanelWindow {
        id: dismissWin
        screen: root.screen
        anchors { top: true; left: true; right: true; bottom: true }
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-wallpaper-dismiss"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {
            width: dismissWin.width
            height: dismissWin.height
            Region {
                x: 0
                y: Math.max(0, dismissWin.height - pickerWin.height)
                width: dismissWin.width
                height: pickerWin.height
                intersection: Intersection.Subtract
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    // --------------------------------------------------------------- picker
    PanelWindow {
        id: pickerWin
        screen: root.screen
        anchors { left: true; right: true; bottom: true }
        implicitHeight: root.panelH
        color: "transparent"
        aboveWindows: true
        focusable: root.shown
        exclusiveZone: 0
        visible: root.shown
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "notchD-wallpaper-picker"
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Rounded top corners both visually and for input, so the transparent
        // corners do not swallow clicks meant for the window below.
        mask: Region {
            width: pickerWin.width
            height: pickerWin.height
            topLeftRadius: Math.round(Theme.radius)
            topRightRadius: Math.round(Theme.radius)
        }

        // Invisible key sink. It owns global shortcuts while the picker is
        // visible; the search field forwards its own edge cases below.
        Item {
            id: focusTarget
            anchors.fill: parent
            focus: root.shown

            Keys.onEscapePressed: (e) => { root.closeRequested(); e.accepted = true; }
            Keys.onLeftPressed: (e) => { root.move(-1); e.accepted = true; }
            Keys.onRightPressed: (e) => { root.move(1); e.accepted = true; }
            Keys.onReturnPressed: (e) => { root.applySelection(); e.accepted = true; }
            Keys.onEnterPressed: (e) => { root.applySelection(); e.accepted = true; }

            Component.onCompleted: { if (root.shown) forceActiveFocus(); }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.bgElev
            topLeftRadius: Math.round(Theme.radius)
            topRightRadius: Math.round(Theme.radius)
            border.width: 1
            border.color: Theme.hairline
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.max(24, (parent.width - 1120) / 2)
            anchors.rightMargin: anchors.leftMargin
            anchors.topMargin: 18
            anchors.bottomMargin: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Wallpaper"
                        color: Theme.fg
                        font { family: Theme.fontFamily; pixelSize: 20; weight: Font.DemiBold }
                    }
                    Text {
                        text: "Choose a view for your desktop"
                        color: Theme.muted
                        font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 245
                    Layout.preferredHeight: 40
                    radius: 20
                    color: Theme.surfaceHover
                    border.width: searchField.activeFocus ? 2 : 0
                    border.color: Theme.accent
                    Components.Icon {
                        anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                        glyph: "\uf002"; size: 13; tint: Theme.muted
                    }
                    TextInput {
                        id: searchField
                        anchors { fill: parent; leftMargin: 38; rightMargin: 14 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.fg
                        font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                        selectByMouse: true
                        clip: true
                        onTextChanged: root.searchText = text
                        Keys.onEscapePressed: (e) => { root.closeRequested(); e.accepted = true; }
                        Keys.onReturnPressed: (e) => { root.applySelection(); e.accepted = true; }
                        Keys.onEnterPressed: (e) => { root.applySelection(); e.accepted = true; }
                        Keys.onLeftPressed: (e) => { if (cursorPosition === 0) { root.move(-1); e.accepted = true; } }
                        Keys.onRightPressed: (e) => { if (cursorPosition === text.length) { root.move(1); e.accepted = true; } }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: !searchField.text.length
                            text: "Search wallpapers"
                            color: Theme.muted
                            font: searchField.font
                        }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    radius: 20; color: closeMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Components.Icon { anchors.centerIn: parent; glyph: "\uf00d"; size: 14; tint: Theme.fg }
                    MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 18
                Rectangle {
                    id: previewPane
                    Layout.preferredWidth: 300
                    Layout.fillHeight: true
                    radius: 18
                    color: Theme.track
                    clip: true
                    Image {
                        id: previewImg
                        anchors.fill: parent
                        source: catalog.fileUrl(root.selectedPath)
                        sourceSize: Qt.size(660, 400)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true; cache: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        text: root.busy || previewImg.status === Image.Loading ? "Loading preview…" : (root.selectedPath ? "Preview unavailable" : "No selection")
                        visible: previewImg.status !== Image.Ready
                        color: Theme.muted
                        font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    spacing: 8
                    Item { Layout.fillHeight: true }
                    Text {
                        text: root.selectedPath && root.selectedPath === catalog.currentPath ? "CURRENT WALLPAPER" : "SELECTED WALLPAPER"
                        color: Theme.secondary
                        font { family: Theme.fontFamily; pixelSize: Theme.fontLabel; weight: Font.DemiBold; letterSpacing: 1 }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedPath ? catalog.baseName(root.selectedPath) : "Choose a wallpaper"
                        color: Theme.fg
                        font { family: Theme.fontFamily; pixelSize: 18; weight: Font.DemiBold }
                        elide: Text.ElideMiddle; textFormat: Text.PlainText
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.selectedPath ? catalog.displayName(root.selectedPath) : "Select an image from the collection below."
                        color: Theme.muted
                        font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                        elide: Text.ElideMiddle; textFormat: Text.PlainText
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        spacing: 8
                        Rectangle {
                            Layout.preferredWidth: 112; Layout.preferredHeight: 36
                            radius: 18; color: favMouse.containsMouse ? Theme.surfacePress : Theme.surfaceHover
                            opacity: root.selectedPath ? 1 : 0.5
                            Row {
                                anchors.centerIn: parent; spacing: 7
                                Components.Icon { glyph: catalog.isFavorite(root.selectedPath) ? "\uf005" : "\uf006"; size: 13; tint: Theme.fg }
                                Text { text: catalog.isFavorite(root.selectedPath) ? "Saved" : "Favorite"; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.fontBody; weight: Font.Medium } }
                            }
                            MouseArea { id: favMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !!root.selectedPath; onClicked: catalog.toggleFavorite(root.selectedPath) }
                        }
                        Text {
                            text: root.results.length ? (root.selectedIndex + 1) + " / " + root.results.length : ""
                            color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.fontLabel }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "Collection"; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: 14; weight: Font.DemiBold } }
                Text { text: root.results.length + " images"; color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.fontLabel } }
                Item { Layout.fillWidth: true }
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: previousMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    opacity: root.selectedIndex > 0 ? 1 : 0.4
                    Components.Icon { anchors.centerIn: parent; glyph: "\uf053"; size: 11; tint: Theme.fg }
                    MouseArea { id: previousMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.selectedIndex > 0; cursorShape: Qt.PointingHandCursor; onClicked: root.move(-1) }
                }
                Rectangle {
                    Layout.preferredWidth: 28; Layout.preferredHeight: 28; radius: 14
                    color: nextMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    opacity: root.selectedIndex >= 0 && root.selectedIndex < root.results.length - 1 ? 1 : 0.4
                    Components.Icon { anchors.centerIn: parent; glyph: "\uf054"; size: 11; tint: Theme.fg }
                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; enabled: root.selectedIndex >= 0 && root.selectedIndex < root.results.length - 1; cursorShape: Qt.PointingHandCursor; onClicked: root.move(1) }
                }
                Rectangle {
                    Layout.preferredWidth: 64; Layout.preferredHeight: 28; radius: 14
                    color: !root.favoritesOnly ? Theme.accentContainer : (allMouse.containsMouse ? Theme.surfaceHover : "transparent")
                    Text { anchors.centerIn: parent; text: "All"; color: !root.favoritesOnly ? Theme.accentContainerInk : Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
                    MouseArea { id: allMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.favoritesOnly = false }
                }
                Rectangle {
                    Layout.preferredWidth: 92; Layout.preferredHeight: 28; radius: 14
                    color: root.favoritesOnly ? Theme.accentContainer : (filterMouse.containsMouse ? Theme.surfaceHover : "transparent")
                    Text { anchors.centerIn: parent; text: "★  Favorites"; color: root.favoritesOnly ? Theme.accentContainerInk : Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
                    MouseArea { id: filterMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.favoritesOnly = true }
                }
            }

            Item {
                Layout.fillWidth: true; Layout.preferredHeight: 78
                ListView {
                    id: strip
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: 8; clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        width: 120; height: 76; radius: 12
                        color: Theme.track
                        border.width: modelData === root.selectedPath ? 3 : 0
                        border.color: Theme.accent
                        clip: true
                        Image {
                            anchors.fill: parent; anchors.margins: modelData === root.selectedPath ? 3 : 0
                            source: catalog.fileUrl(modelData); sourceSize: Qt.size(240, 152)
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true
                        }
                        Rectangle {
                            anchors { right: parent.right; top: parent.top; margins: 6 }
                            width: 23; height: 23; radius: 12
                            color: Theme.accent; visible: modelData === root.selectedPath
                            Components.Icon { anchors.centerIn: parent; glyph: "\uf00c"; size: 11; tint: Theme.accentInk }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { root.selectAt(index); focusTarget.forceActiveFocus(); } }
                    }
                }
                Text {
                    anchors.centerIn: parent; width: parent.width - 24
                    visible: root.busy || root.errored || root.results.length === 0
                    text: root.busy ? "Loading wallpapers…" : root.errored ? catalog.errorText + "  ·  Click to retry" : root.favoritesOnly ? "No favorites match this collection" : root.searchText ? "No wallpapers match your search" : "No wallpapers found in " + catalog.wallsDir
                    color: root.errored ? Theme.danger : Theme.muted
                    font { family: Theme.fontFamily; pixelSize: Theme.fontBody }
                    horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                    MouseArea { anchors.fill: parent; enabled: root.errored; cursorShape: Qt.PointingHandCursor; onClicked: catalog.reload() }
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text {
                    Layout.fillWidth: true
                    text: "← → Navigate   ·   Enter Apply   ·   Esc Close"
                    color: Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.fontLabel }
                    elide: Text.ElideRight
                }
                Rectangle {
                    Layout.preferredWidth: 86; Layout.preferredHeight: 36; radius: 18
                    color: cancelMouse.containsMouse ? Theme.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.fg; font { family: Theme.fontFamily; pixelSize: Theme.fontBody; weight: Font.DemiBold } }
                    MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.closeRequested() }
                }
                Rectangle {
                    id: applyBtn
                    Layout.preferredWidth: 116; Layout.preferredHeight: 36; radius: 18
                    enabled: !!root.selectedPath && !root.busy && !root.errored
                    color: enabled ? Theme.accent : Theme.track
                    opacity: enabled ? (applyMouse.pressed ? 0.72 : applyMouse.containsMouse ? 0.88 : 1) : 0.5
                    Text { anchors.centerIn: parent; text: "Apply"; color: applyBtn.enabled ? Theme.accentInk : Theme.muted; font { family: Theme.fontFamily; pixelSize: Theme.fontBody; weight: Font.DemiBold } }
                    MouseArea { id: applyMouse; anchors.fill: parent; enabled: applyBtn.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applySelection() }
                }
            }
        }
    }
}
