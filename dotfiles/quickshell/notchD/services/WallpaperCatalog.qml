pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper discovery for the native wallpaper picker.
//
// Deliberately read-only: it lists the images in the same folder `wp` uses
// (~/Pictures/walls by default), reads the same favorites file, and reports
// the current wallpaper via `wp current`. It never changes the wallpaper or
// the theme — applying is delegated to `wp <exact path>` so awww + matugen
// stay the single source of truth for the desktop theme.
//
// Filenames are safe by construction: the find command is an argument array
// (no shell interpolation) and its output is NUL-delimited, so spaces, quotes,
// unicode and even newlines in a filename cannot split or inject anything.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME") || ""
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || (home + "/.config")
    // wp's WALLS default. NOTCHD_WALLS_DIR is a picker-only override for
    // testing / unusual layouts; leave it unset for the normal workflow.
    readonly property string wallsDir: Quickshell.env("NOTCHD_WALLS_DIR") || (home + "/Pictures/walls")
    readonly property string favsFile: configHome + "/wallpapers/favorites"

    // idle | loading | ready | empty | error
    property string status: "idle"
    property string errorText: ""
    property var items: []          // absolute image paths, sorted
    property var favorites: []      // absolute paths from the favorites file
    property string currentPath: "" // `wp current`

    property string _scanText: ""

    function reload() {
        root.status = "loading";
        root.errorText = "";
        root._scanText = "";
        root.items = [];
        scan.running = true;
        currentProc.running = true;
        favView.reload();
    }

    // ------------------------------------------------------------- discovery
    // `find -print0` keeps every path intact. StdioCollector gives us the raw
    // bytes; splitting on NUL happens in JS so a path with a newline is safe.
    Process {
        id: scan
        command: ["find", root.wallsDir, "-type", "f", "(",
            "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
            "-iname", "*.png", "-o", "-iname", "*.webp", ")", "-print0"]

        stdout: StdioCollector {
            onTextChanged: root._scanText = String(text)
        }

        onExited: (code) => {
            if (code !== 0) {
                root.status = "error";
                root.errorText = "Could not scan " + root.wallsDir;
                return;
            }
            const sep = String.fromCharCode(0);
            const raw = root._scanText.length > 0 ? root._scanText.split(sep) : [];
            const found = [];
            for (let i = 0; i < raw.length; ++i) {
                if (raw[i].length > 0)
                    found.push(raw[i]);
            }
            found.sort();
            root.items = found;
            root.status = found.length > 0 ? "ready" : "empty";
        }
    }

    Process {
        id: currentProc
        command: ["wp", "current"]

        stdout: SplitParser {
            onRead: (line) => {
                const p = String(line).trim();
                if (p.length > 0) root.currentPath = p;
            }
        }

        onExited: (code) => { if (code !== 0) root.currentPath = ""; }
    }

    FileView {
        id: favView
        path: root.favsFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseFavorites()
        onTextChanged: root.parseFavorites()
        onLoadFailed: root.favorites = []
    }

    function parseFavorites() {
        if (!favView.loaded) return;
        const lines = String(favView.text()).split("\n");
        const out = [];
        for (let i = 0; i < lines.length; ++i) {
            const p = lines[i].trim();
            if (p.length > 0) out.push(p);
        }
        root.favorites = out;
    }

    // --------------------------------------------------------------- actions
    // Apply through the existing `wp` with the exact absolute path. wp runs
    // awww (transition) then matugen, and writes the effective mode file that
    // shell.qml already watches — no duplicated theme logic here.
    function apply(path) {
        if (!path) return false;
        Quickshell.execDetached(["wp", path]);
        return true;
    }

    function toggleFavorite(path) {
        if (!path) return;
        favToggle.command = ["wp", "fav", "toggle", path];
        favToggle.running = true;
    }

    Process {
        id: favToggle
        command: []
        onExited: (code) => { if (code === 0) favView.reload(); }
    }

    function isFavorite(path) {
        return !!path && root.favorites.indexOf(path) >= 0;
    }

    // ------------------------------------------------------------ formatting
    function fileUrl(path) {
        if (!path) return "";
        return "file://" + String(path).split("/").map(encodeURIComponent).join("/");
    }

    function baseName(path) {
        if (!path) return "";
        const parts = String(path).split("/");
        return parts[parts.length - 1];
    }

    // Subfolder-aware label: "gruvbox/foo.png" instead of just "foo.png".
    function displayName(path) {
        if (!path) return "";
        const base = root.wallsDir.replace(/\/+$/, "") + "/";
        return path.indexOf(base) === 0 ? path.slice(base.length) : baseName(path);
    }
}
