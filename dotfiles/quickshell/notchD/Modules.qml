pragma Singleton

import QtQuick
import Quickshell

// Built-in module registry.
//
// A module is a manifest plus a QML flyout. This is deliberately not a binary
// plugin ABI: modules ship inside the shell, are loaded lazily by NotchD.qml
// and can be enabled, disabled and reordered at runtime. The settings flyout
// edits `orderCsv` / `enabledCsv`; shell.qml persists both strings through a
// FileView + JsonAdapter.
Singleton {
    id: root

    readonly property var manifests: [
        {
            id: "wifi",
            title: "Wi-Fi",
            icon: "\uf1eb",
            description: "Networks, saved profiles and passphrases"
        },
        {
            id: "bluetooth",
            title: "Bluetooth",
            icon: "\uf293",
            description: "Adapters, pairing and connected devices"
        },
        {
            id: "audio",
            title: "Audio",
            icon: "\uf028",
            description: "Output, microphone and media transport"
        },
        {
            id: "battery",
            title: "Battery",
            icon: "\uf240",
            description: "Charge, health and power profiles"
        },
        {
            id: "display",
            title: "Display",
            icon: "\uf185",
            description: "Backlight, night light and monitors"
        },
        {
            id: "session",
            title: "Session",
            icon: "\uf011",
            description: "Lock, suspend, log out and power"
        }
    ]

    // Comma-separated so the settings JsonAdapter can store them directly.
    property string orderCsv: "wifi,bluetooth,audio,battery,display,session"
    property string enabledCsv: "wifi,bluetooth,audio,battery,display,session"

    function splitCsv(value) {
        const parts = String(value || "").split(",");
        const out = [];
        for (let i = 0; i < parts.length; i++) {
            const p = parts[i].trim();
            if (p.length > 0 && out.indexOf(p) < 0) out.push(p);
        }
        return out;
    }

    function manifest(id) {
        for (let i = 0; i < manifests.length; i++)
            if (manifests[i].id === id) return manifests[i];
        return null;
    }

    readonly property var allIds: {
        const ids = [];
        for (let i = 0; i < manifests.length; i++) ids.push(manifests[i].id);
        return ids;
    }

    // Registry order, with any new modules appended so upgrades never hide one.
    readonly property var order: {
        const out = [];
        const saved = splitCsv(orderCsv);
        for (let i = 0; i < saved.length; i++)
            if (allIds.indexOf(saved[i]) >= 0) out.push(saved[i]);
        for (let i = 0; i < allIds.length; i++)
            if (out.indexOf(allIds[i]) < 0) out.push(allIds[i]);
        return out;
    }

    readonly property var enabledIds: {
        const saved = splitCsv(enabledCsv);
        const out = [];
        for (let i = 0; i < order.length; i++)
            if (saved.indexOf(order[i]) >= 0) out.push(order[i]);
        return out;
    }

    readonly property var enabledManifests: {
        const out = [];
        for (let i = 0; i < enabledIds.length; i++) {
            const m = manifest(enabledIds[i]);
            if (m) out.push(m);
        }
        return out;
    }

    function isEnabled(id) { return enabledIds.indexOf(id) >= 0; }

    function setEnabled(id, enabled) {
        if (!manifest(id)) return;
        const next = [];
        const current = splitCsv(enabledCsv);
        for (let i = 0; i < order.length; i++) {
            const candidate = order[i];
            if (candidate === id ? enabled : current.indexOf(candidate) >= 0)
                next.push(candidate);
        }
        enabledCsv = next.join(",");
    }

    function toggle(id) { setEnabled(id, !isEnabled(id)); }

    function move(id, delta) {
        const ids = order.slice();
        const from = ids.indexOf(id);
        if (from < 0) return;
        const to = Math.max(0, Math.min(ids.length - 1, from + Number(delta || 0)));
        if (to === from) return;
        ids.splice(from, 1);
        ids.splice(to, 0, id);
        orderCsv = ids.join(",");
    }

    function indexOf(id) { return enabledIds.indexOf(id); }
}
