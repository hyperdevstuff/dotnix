pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io

// Bluetooth seam over Quickshell.Bluetooth + bluetoothctl.
// Native BlueZ state/connect/disconnect is used where possible. Pairing goes
// through bluetoothctl, which brings its own short-lived agent and therefore
// covers Just Works and most headphone prompts without a private C++ agent.
// Passkey/keyboard-confirmation devices can fall back to overskride.
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: !!adapter && !!adapter.enabled
    readonly property bool discovering: !!adapter && !!adapter.discovering

    readonly property var devices: {
        if (!adapter) return [];
        const model = adapter.devices;
        if (!model) return [];
        const list = model.values || [];
        const arr = [];
        for (let i = 0; i < list.length; i++) {
            const d = list[i];
            if (!d) continue;
            if (!d.address && !d.name) continue;
            arr.push(d);
        }
        arr.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            if (a.pairing !== b.pairing) return a.pairing ? -1 : 1;
            const na = String(a.name || a.address || "");
            const nb = String(b.name || b.address || "");
            return na.localeCompare(nb);
        });
        return arr;
    }

    readonly property var connectedDevices: {
        const out = [];
        const list = root.devices;
        for (let i = 0; i < list.length; i++) if (list[i].connected) out.push(list[i]);
        return out;
    }

    readonly property var pairedDevices: {
        const out = [];
        const list = root.devices;
        for (let i = 0; i < list.length; i++) if (!list[i].connected && (list[i].paired || list[i].bonded)) out.push(list[i]);
        return out;
    }

    readonly property var availableDevices: {
        const out = [];
        const list = root.devices;
        for (let i = 0; i < list.length; i++) if (!list[i].connected && !list[i].paired && !list[i].bonded) out.push(list[i]);
        return out;
    }

    readonly property string connectedName: connectedDevices.length > 0
        ? String(connectedDevices[0].name || connectedDevices[0].address || "Device")
        : ""

    readonly property string statusText: {
        if (!available) return "No adapter";
        if (!enabled) return "Off";
        if (connectedDevices.length === 1) return connectedName;
        if (connectedDevices.length > 1) return connectedDevices.length + " connected";
        return "On";
    }

    readonly property int connectedCount: connectedDevices.length

    // ------------------------------------------------------------ operations
    property string busyAddress: ""
    property string busyText: ""
    property string errorMessage: ""

    Timer {
        id: clearErrorTimer
        interval: 6000
        onTriggered: root.errorMessage = ""
    }

    Timer {
        id: discoveryStopTimer
        interval: 30000
        onTriggered: root.setDiscovering(false)
    }

    function toggle() {
        if (!adapter) return;
        adapter.enabled = !adapter.enabled;
        if (!adapter.enabled) root.setDiscovering(false);
    }

    function setDiscovering(enabled) {
        if (!adapter) return;
        adapter.discovering = !!enabled;
        if (enabled) discoveryStopTimer.restart();
        else discoveryStopTimer.stop();
    }

    function deviceLabel(device) {
        if (!device) return "";
        return String(device.name || device.address || "Unknown device");
    }

    function isBusy(device) {
        return !!device && root.busyAddress === String(device.address || "");
    }

    function pairOrConnect(device) {
        if (!device || root.isBusy(device)) return;
        root.errorMessage = "";

        if (device.connected) {
            device.disconnect();
            return;
        }

        if (device.pairing) {
            device.cancelPair();
            return;
        }

        if (device.paired || device.bonded) {
            root.busyAddress = String(device.address || "");
            root.busyText = "Connecting";
            device.connect();
            busyTimeout.restart();
            return;
        }

        const address = String(device.address || "");
        if (!/^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(address)) {
            root.errorMessage = "Invalid Bluetooth address.";
            clearErrorTimer.restart();
            return;
        }

        root.busyAddress = address;
        root.busyText = "Pairing";
        pairProc.command = ["sh", "-c",
            "bluetoothctl --timeout 30 pair " + address +
            " && bluetoothctl trust " + address +
            " && bluetoothctl connect " + address];
        pairProc.running = true;
    }

    function forget(device) {
        if (!device) return;
        device.forget();
    }

    function openAdvanced() {
        Quickshell.execDetached(["overskride"]);
    }

    Timer {
        id: busyTimeout
        interval: 12000
        onTriggered: {
            if (root.busyAddress !== "") {
                root.busyAddress = "";
                root.busyText = "";
            }
        }
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true
        function onEnabledChanged() {
            if (!root.adapter || !root.adapter.enabled) root.setDiscovering(false);
        }
    }

    Process {
        id: pairProc
        stdout: SplitParser {
            onRead: (line) => {
                const l = String(line).trim();
                if (l.length > 0 && (l.indexOf("Failed") >= 0 || l.indexOf("failed") >= 0))
                    root.errorMessage = l;
            }
        }
        stderr: SplitParser {
            onRead: (line) => {
                const l = String(line).trim();
                if (l.length > 0) root.errorMessage = l;
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.busyAddress = "";
            root.busyText = "";
            busyTimeout.stop();
            if (exitCode !== 0) {
                if (root.errorMessage.length === 0)
                    root.errorMessage = "Pairing failed. Try overskride for passkey prompts.";
                clearErrorTimer.restart();
            }
        }
    }
}
