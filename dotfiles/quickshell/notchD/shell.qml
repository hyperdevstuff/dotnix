import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    id: shell

    PersistentProperties {
        id: persisted
        reloadableId: "notchD-settings"
        property string theme: "gruvbox"
    }

    readonly property var primaryScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    PanelWindow {
        id: panel

        screen: shell.primaryScreen
        anchors.top: true
        anchors.left: true
        margins.top: 0
        margins.left: panel.screen && panel.screen.width
            ? Math.round((panel.screen.width - notch.targetWidth) / 2)
            : 0

        implicitWidth: notch.targetWidth
        implicitHeight: notch.targetHeight
        color: "transparent"
        aboveWindows: true
        focusable: false
        exclusiveZone: 0

        NotchD {
            id: notch
            anchors.fill: parent
            outputName: panel.screen && panel.screen.name ? panel.screen.name : ""
            themeName: persisted.theme
            onThemeChangeRequested: themeName => persisted.theme = themeName
        }
    }

    IpcHandler {
        target: "notchD"

        function toggle(): void {
            notch.toggle();
        }

        function expand(): void {
            notch.expand();
        }

        function collapse(): void {
            notch.collapse();
        }

        function hide(): void {
            notch.hide();
        }

        function show(): void {
            notch.show();
        }

        function setTheme(theme: string): bool {
            return notch.setTheme(theme);
        }

        function cycleTheme(): string {
            notch.cycleTheme();
            return notch.themeName;
        }

        function currentTheme(): string {
            return notch.themeName;
        }

        function workspaceInfo(): string {
            return JSON.stringify({
                id: notch.currentWorkspaceId,
                idx: notch.currentWorkspaceIdx,
                known: notch.workspaceKnown
            });
        }
    }
}
