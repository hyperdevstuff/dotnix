pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: {
        const p = Mpris.players;
        return (p && p.values !== undefined) ? p.values : (p || []);
    }

    property var selectedPlayer: null
    // Respect the selected source while it exists; otherwise follow playback.
    readonly property var activePlayer: {
        const ps = root.players;
        if (!ps || ps.length === 0)
            return null;
        if (root.selectedPlayer && ps.indexOf(root.selectedPlayer) >= 0)
            return root.selectedPlayer;
        for (let i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].isPlaying)
                return ps[i];
        return ps[0];
    }

    readonly property bool hasPlayer: root.activePlayer !== null
    readonly property bool playing: root.activePlayer ? root.activePlayer.isPlaying : false
    readonly property string title: root.activePlayer ? root.activePlayer.trackTitle : ""
    readonly property string artist: root.activePlayer ? root.activePlayer.trackArtist : ""
    readonly property string artUrl: root.activePlayer ? root.activePlayer.trackArtUrl : ""
    readonly property string album: root.activePlayer ? root.activePlayer.trackAlbum : ""
    readonly property string playerName: root.activePlayer ? root.activePlayer.identity : ""
    readonly property real position: root.activePlayer ? root.activePlayer.position : 0
    readonly property real length: root.activePlayer && root.activePlayer.lengthSupported ? root.activePlayer.length : 0
    readonly property bool canPlay: root.activePlayer ? root.activePlayer.canPlay : false
    readonly property bool canPause: root.activePlayer ? root.activePlayer.canPause : false
    readonly property bool canNext: root.activePlayer ? root.activePlayer.canGoNext : false
    readonly property bool canPrev: root.activePlayer ? root.activePlayer.canGoPrevious : false
    readonly property bool canSeek: root.activePlayer ? root.activePlayer.canSeek && root.activePlayer.positionSupported && root.length > 0 : false

    function selectPlayer(player) {
        if (root.players.indexOf(player) >= 0)
            root.selectedPlayer = player;
    }
    function seek(seconds) {
        if (root.canSeek && isFinite(seconds))
            root.activePlayer.position = Math.max(0, Math.min(root.length, seconds));
    }
    // MPRIS extrapolates position when read, but deliberately avoids periodic
    // notifications. Visible seekbars opt in; hidden panels do no polling.
    function updatePosition() {
        if (root.activePlayer)
            root.activePlayer.positionChanged();
    }

    function playPause() {
        if (root.activePlayer && root.activePlayer.canTogglePlaying)
            root.activePlayer.togglePlaying();
    }
    function next() {
        if (root.activePlayer && root.activePlayer.canGoNext)
            root.activePlayer.next();
    }
    function previous() {
        if (root.activePlayer && root.activePlayer.canGoPrevious)
            root.activePlayer.previous();
    }
}
