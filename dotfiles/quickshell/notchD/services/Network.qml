pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wi-Fi seam over Quickshell.Networking (NetworkManager backend).
// Covers scan, connect, saved profiles, forget and inline PSK prompts.
// Enterprise / hidden-SSID / VPN profiles stay in nm-connection-editor, which
// is the one Wi-Fi task that genuinely needs the external GUI.
Singleton {
    id: root

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: {
        const list = root.devices;
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].type === DeviceType.Wifi) return list[i];
        return null;
    }
    readonly property var wiredDevice: {
        const list = root.devices;
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].type === DeviceType.Wired) return list[i];
        return null;
    }

    readonly property bool available: !!wifiDevice
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool connected: !!wifiDevice && wifiDevice.connected
    readonly property bool wiredConnected: !!wiredDevice && wiredDevice.connected

    readonly property string currentSsid: {
        if (!wifiDevice) return "";
        const list = wifiDevice.networks ? (wifiDevice.networks.values || []) : [];
        for (let i = 0; i < list.length; i++)
            if (list[i] && list[i].connected) return String(list[i].name || "");
        return "";
    }

    readonly property string statusText: {
        if (!available) return "No Wi-Fi adapter";
        if (!Networking.wifiHardwareEnabled) return "Wi-Fi blocked";
        if (!Networking.wifiEnabled) return "Wi-Fi off";
        if (connected) return currentSsid || "Connected";
        return "Not connected";
    }

    readonly property bool scanning: wifiDevice ? !!wifiDevice.scannerEnabled : false

    readonly property var networks: {
        const dev = root.wifiDevice;
        if (!dev || !dev.networks) return [];
        const list = dev.networks.values || [];
        const arr = [];
        const byName = {};
        for (let i = 0; i < list.length; i++) {
            const n = list[i];
            if (!n || !n.name) continue;
            const name = String(n.name);
            const key = "k:" + name;
            if (!Object.prototype.hasOwnProperty.call(byName, key)) {
                byName[key] = arr.length;
                arr.push(n);
            } else {
                const current = arr[byName[key]];
                if (root.betterNetwork(n, current))
                    arr[byName[key]] = n;
            }
        }
        arr.sort(function (a, b) {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.known !== b.known) return a.known ? -1 : 1;
            const sa = Number(a.signalStrength) || 0;
            const sb = Number(b.signalStrength) || 0;
            if (sa !== sb) return sb - sa;
            return String(a.name).localeCompare(String(b.name));
        });
        return arr;
    }

    // NetworkManager exposes one object per access point. Collapse them to one
    // row per SSID, preferring the connected/known/strongest AP.
    function betterNetwork(a, b) {
        if (!b) return true;
        if (a.connected !== b.connected) return !!a.connected;
        if (a.known !== b.known) return !!a.known;
        return (Number(a.signalStrength) || 0) > (Number(b.signalStrength) || 0);
    }

    // ------------------------------------------------------------ operations
    property bool busy: false
    property string busyName: ""
    property string errorMessage: ""
    property var activeNetwork: null
    property var pendingNetwork: null
    property bool pendingIsWep: false

    readonly property bool passwordPromptVisible: pendingNetwork !== null

    Connections {
        target: root.activeNetwork
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) {
            root.busy = false;
            root.errorMessage = "Could not connect: " + ConnectionFailReason.toString(reason);
            root.clearErrorTimer.restart();
        }
        function onConnectedChanged() {
            if (root.activeNetwork && root.activeNetwork.connected) {
                root.busy = false;
                root.errorMessage = "";
            }
        }
        function onStateChangingChanged() {
            if (root.activeNetwork && !root.activeNetwork.stateChanging) root.busy = false;
        }
    }

    Timer {
        id: clearErrorTimer
        interval: 5000
        onTriggered: root.errorMessage = ""
    }

    Timer {
        id: scanStopTimer
        interval: 25000
        onTriggered: root.setScanning(false)
    }

    function setScanning(enabled) {
        if (!wifiDevice) return;
        wifiDevice.scannerEnabled = !!enabled;
        if (enabled) scanStopTimer.restart();
        else scanStopTimer.stop();
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function securityLabel(security) {
        switch (security) {
        case WifiSecurityType.Open: return "Open";
        case WifiSecurityType.Owe: return "OWE";
        case WifiSecurityType.WpaPsk: return "WPA";
        case WifiSecurityType.Wpa2Psk: return "WPA2";
        case WifiSecurityType.Sae: return "WPA3";
        case WifiSecurityType.Wpa3SuiteB192: return "WPA3 Enterprise";
        case WifiSecurityType.WpaEap: return "WPA Enterprise";
        case WifiSecurityType.Wpa2Eap: return "WPA2 Enterprise";
        case WifiSecurityType.StaticWep: return "WEP";
        case WifiSecurityType.DynamicWep: return "WEP";
        case WifiSecurityType.Leap: return "LEAP";
        default: return "Secured";
        }
    }

    function requiresAdvanced(security) {
        return security === WifiSecurityType.WpaEap
            || security === WifiSecurityType.Wpa2Eap
            || security === WifiSecurityType.Wpa3SuiteB192
            || security === WifiSecurityType.Leap
            || security === WifiSecurityType.DynamicWep
            || security === WifiSecurityType.Unknown;
    }

    function requiresPassword(security) {
        return security === WifiSecurityType.WpaPsk
            || security === WifiSecurityType.Wpa2Psk
            || security === WifiSecurityType.Sae
            || security === WifiSecurityType.StaticWep;
    }

    function signalLevel(network) {
        if (!network) return 0;
        const s = Number(network.signalStrength) || 0;
        if (s >= 0.75) return 4;
        if (s >= 0.5) return 3;
        if (s >= 0.25) return 2;
        return 1;
    }

    function connectTo(network) {
        if (!network || root.busy) return;
        root.errorMessage = "";

        if (network.connected) {
            network.disconnect();
            return;
        }

        if (requiresAdvanced(network.security)) {
            root.errorMessage = "This network needs the advanced editor.";
            clearErrorTimer.restart();
            return;
        }

        if (network.known) {
            root.begin(network);
            network.connect();
            return;
        }

        if (!requiresPassword(network.security)) {
            root.begin(network);
            network.connect();
            return;
        }

        root.pendingNetwork = network;
        root.pendingIsWep = network.security === WifiSecurityType.StaticWep;
    }

    function submitPassword(password) {
        const network = root.pendingNetwork;
        if (!network) return;
        const psk = String(password || "");
        root.pendingNetwork = null;
        if (psk.length === 0) return;

        root.begin(network);
        if (root.pendingIsWep) {
            wepProc.command = ["nmcli", "device", "wifi", "connect", String(network.name), "password", psk];
            wepProc.running = true;
            root.pendingIsWep = false;
            return;
        }
        network.connectWithPsk(psk);
    }

    function cancelPassword() {
        root.pendingNetwork = null;
        root.pendingIsWep = false;
    }

    function begin(network) {
        root.activeNetwork = network;
        root.busy = true;
        root.busyName = String(network.name || "");
        root.errorMessage = "";
    }

    function forget(network) {
        if (!network) return;
        network.forget();
    }

    function openAdvanced() {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    Process {
        id: wepProc
        stdout: SplitParser { onRead: (line) => { /* nmcli output is ignored */ } }
        stderr: SplitParser { onRead: (line) => { if (String(line).trim()) root.errorMessage = String(line).trim(); } }
        onExited: (exitCode, exitStatus) => {
            root.busy = false;
            if (exitCode !== 0 && root.errorMessage.length === 0)
                root.errorMessage = "Could not connect to WEP network.";
            clearErrorTimer.restart();
        }
    }
}
