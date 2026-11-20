import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "components" as Components
import "services" as Services

// Native wallpaper switcher: a bottom-anchored overlay with a large preview
// of the selected image and a horizontal filmstrip of thumbnails.
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

    readonly property var catalog: Services.WallpaperCatalog
    readonly property bool busy: catalog.status === "loading" || catalog.status === "idle"
    readonly property bool errored: catalog.status === "error"

    // Search is local to the picker so two pickers never fight over state.
    readonly property var results: {
        const q = root.searchText.trim().toLowerCase();
        const all = catalog.items;
        if (!q) return all;
        return all.filter(p => catalog.displayName(p).toLowerCase().indexOf(q) >= 0);
    }

    readonly property string selectedPath: (root.selectedIndex >= 0 && root.selectedIndex < results.length)
        ? results[root.selectedIndex] : ""

    readonly property int panelH: {
        const h = root.screen ? root.screen.height : 1080;
        return Math.min(h, 560, Math.max(420, Math.round(h * 0.62)));
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
            anchors.margins: Theme.pad
            spacing: Theme.gap

            // ------------------------------------------------------- header
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.gap

                    Text {
                        text: "Wallpapers"
                        color: Theme.fg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontTitle
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: catalog.items.length && root.results.length !== catalog.items.length
                            ? root.results.length + " of " + catalog.items.length + " shown"
                            : ""
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 260
                        Layout.maximumWidth: 320
                        Layout.preferredHeight: 30
                        radius: Theme.radiusSmall
                        color: Theme.surface
                        border.width: 1
                        border.color: searchField.activeFocus ? Theme.muted : Theme.hairline

                        Text {
                            anchors.left: searchField.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search wallpapers…"
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            visible: searchField.text.length === 0
                        }

                        TextInput {
                            id: searchField
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            selectByMouse: true

                            onTextChanged: root.searchText = text

                            // Let typing keep focus for the search field, but
                            // hand navigation / Escape / Enter back to root.
                            Keys.onEscapePressed: (e) => { root.closeRequested(); e.accepted = true; }
                            Keys.onReturnPressed: (e) => { root.applySelection(); e.accepted = true; }
                            Keys.onEnterPressed: (e) => { root.applySelection(); e.accepted = true; }
                            Keys.onLeftPressed: (e) => {
                                if (cursorPosition === 0) { root.move(-1); e.accepted = true; }
                            }
                            Keys.onRightPressed: (e) => {
                                if (cursorPosition === text.length) { root.move(1); e.accepted = true; }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: Theme.radiusSmall
                        color: closeMouse.containsMouse ? Theme.surfaceHover : "transparent"

                        Components.Icon {
                            anchors.centerIn: parent
                            glyph: "\uf00d"
                            size: 12
                            tint: Theme.muted
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }
                }
            }

            // ------------------------------------------------------- preview
            Item {
                id: previewPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    radius: Theme.radiusSmall
                    border.width: 1
                    border.color: Theme.hairlineSoft
                }

                Image {
                    id: previewImg
                    anchors { fill: parent; margins: 1 }
                    source: catalog.fileUrl(root.selectedPath)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.selectedPath || previewImg.status === Image.Error
                    text: root.busy ? "Loading…"
                        : (root.selectedPath ? "Preview unavailable" : "No wallpaper selected")
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 46
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0) }
                        GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0.72) }
                    }
                }

                Text {
                    anchors {
                        left: parent.left; right: parent.right; bottom: parent.bottom
                        leftMargin: 14; rightMargin: 56; bottomMargin: 10
                    }
                    text: catalog.displayName(root.selectedPath)
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    textFormat: Text.PlainText
                }

                Components.Icon {
                    anchors { right: parent.right; bottom: parent.bottom; rightMargin: 16; bottomMargin: 11 }
                    visible: catalog.isFavorite(root.selectedPath)
                    glyph: "\uf005"
                    size: 14
                    tint: "#fbbf24"
                }

                Rectangle {
                    id: prevBtn
                    width: 30
                    height: 30
                    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                    radius: 15
                    color: prevMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.38)
                    visible: root.results.length > 1

                    Components.Icon {
                        anchors.centerIn: parent
                        glyph: "\uf053"
                        size: 14
                        tint: "#ffffff"
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.move(-1)
                    }
                }

                Rectangle {
                    id: nextBtn
                    width: 30
                    height: 30
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    radius: 15
                    color: nextMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.38)
                    visible: root.results.length > 1

                    Components.Icon {
                        anchors.centerIn: parent
                        glyph: "\uf054"
                        size: 14
                        tint: "#ffffff"
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.move(1)
                    }
                }
            }

            // ----------------------------------------------------- filmstrip
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 104
                clip: true

                ListView {
                    id: strip
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    layoutDirection: Qt.LeftToRight
                    spacing: Theme.gap
                    clip: true
                    model: root.results
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property string modelData

                        width: 142
                        height: 100
                        radius: Theme.radiusSmall
                        color: modelData === root.selectedPath ? Theme.surfaceHover : Theme.surface
                        border.width: modelData === root.selectedPath ? 2 : 1
                        border.color: modelData === root.selectedPath ? Theme.fg : Theme.hairline

                        Image {
                            anchors { fill: parent; margins: 1 }
                            source: catalog.fileUrl(modelData)
                            sourceSize: Qt.size(142, 100)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 24
                            color: Qt.rgba(0, 0, 0, 0.62)

                            Text {
                                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                text: catalog.baseName(modelData)
                                color: "#fafafa"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontLabel
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                textFormat: Text.PlainText
                            }
                        }

                        Components.Icon {
                            anchors { top: parent.top; right: parent.right; margins: 5 }
                            visible: catalog.isFavorite(modelData)
                            glyph: "\uf005"
                            size: 11
                            tint: "#fbbf24"
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index;
                                searchField.forceActiveFocus();
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    visible: !root.busy && !root.errored && root.results.length === 0
                    text: root.searchText.length > 0
                        ? "No wallpapers match “" + root.searchText + "”"
                        : "No wallpapers found in " + catalog.wallsDir
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: root.busy || root.errored

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.busy ? "Loading wallpapers…" : catalog.errorText
                        color: root.errored ? Theme.danger : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontBody
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.errored
                        width: 80
                        height: 26
                        radius: 8
                        color: Theme.surfaceHover
                        border.width: 1
                        border.color: Theme.hairline

                        Text {
                            anchors.centerIn: parent
                            text: "Retry"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: catalog.reload()
                        }
                    }
                }
            }

            // -------------------------------------------------------- footer
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 36

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.gap

                    Text {
                        Layout.fillWidth: true
                        text: "← → navigate · Enter apply · Esc close"
                        color: Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontLabel
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: favBtn
                        Layout.preferredWidth: 98
                        Layout.preferredHeight: 30
                        radius: Theme.radiusSmall
                        color: favMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: 1
                        border.color: Theme.hairline
                        opacity: root.selectedPath ? 1 : 0.5

                        Components.Icon {
                            anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                            glyph: catalog.isFavorite(root.selectedPath) ? "\uf005" : "\uf006"
                            size: 12
                            tint: catalog.isFavorite(root.selectedPath) ? "#fbbf24" : Theme.muted
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 27; right: parent.right; verticalCenter: parent.verticalCenter }
                            text: catalog.isFavorite(root.selectedPath) ? "Favorited" : "Favorite"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                        }

                        MouseArea {
                            id: favMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (root.selectedPath) catalog.toggleFavorite(root.selectedPath); }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 78
                        Layout.preferredHeight: 30
                        radius: Theme.radiusSmall
                        color: cancelMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: 1
                        border.color: Theme.hairline

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                    }

                    Rectangle {
                        id: applyBtn
                        Layout.preferredWidth: 86
                        Layout.preferredHeight: 30
                        radius: Theme.radiusSmall
                        color: applyBtn.enabled ? Theme.accent : Theme.surface
                        border.width: applyBtn.enabled ? 0 : 1
                        border.color: Theme.hairline
                        opacity: applyBtn.enabled ? (applyMouse.containsMouse ? 0.88 : 1) : 0.5
                        enabled: !!root.selectedPath && !root.busy && !root.errored

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: applyBtn.enabled ? Theme.accentInk : Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontLabel
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: applyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: applyBtn.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applySelection()
                        }
                    }
                }
            }
        }
    }
}
