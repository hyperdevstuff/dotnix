import QtQuick
import ".."

// Compatibility for existing module glyphs; common shell icons use one family.
Item {
    id: root
    property string glyph: ""
    property int size: 15
    property color tint: Theme.fg
    readonly property var symbols: ({
            "\uf1eb": "wifi",
            "\uf293": "bluetooth",
            "\uf028": "volume_up",
            "\uf026": "volume_off",
            "\uf185": "brightness_6",
            "\uf240": "battery_full",
            "\uf241": "battery_full",
            "\uf242": "battery_full",
            "\uf243": "battery_saver",
            "\uf244": "battery_saver",
            "\uf0e7": "battery_charging_full",
            "\uf011": "power_settings_new",
            "\uf013": "settings",
            "\uf03e": "wallpaper",
            "\uf048": "skip_previous",
            "\uf051": "skip_next",
            "\uf04b": "play_arrow",
            "\uf04c": "pause",
            "\uf001": "music_note",
            "\uf005": "star", "\uf006": "star", "\uf030": "photo_camera", "\uf009": "grid_view",
            "\uf00d": "close",
            "\uf017": "schedule",
            "\uf0f3": "notifications",
            "\uf2db": "memory",
            "\uf108": "desktop_windows",
            "\uf0a0": "storage",
            "\uf0ec": "swap_vert",
            "\uf053": "keyboard_arrow_left",
            "\uf054": "keyboard_arrow_right",
            "\uf023": "lock",
            "\uf130": "mic",
            "\uf131": "mic_off",
            "\uf06c": "battery_saver",
            "\uf24e": "tune",
            "\uf021": "tune",
            "\uf071": "info",
            "\uf05a": "info"
        })
    readonly property string symbol: symbols[glyph] || ""
    implicitWidth: symbol ? size : Math.max(size, fallback.implicitWidth)
    implicitHeight: size
    Symbol {
        anchors.centerIn: parent
        name: root.symbol
        size: root.size
        tint: root.tint
        visible: root.symbol.length > 0
    }
    Text {
        id: fallback
        anchors.centerIn: parent
        visible: !root.symbol
        text: root.glyph
        color: root.tint
        font.family: Theme.iconFont
        font.pixelSize: root.size
        textFormat: Text.PlainText
    }
}
