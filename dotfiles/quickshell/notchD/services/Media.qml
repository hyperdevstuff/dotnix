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

    // Pick the first playing player, else the first available.
    readonly property var activePlayer: {
        const ps = root.players;
        if (!ps || ps.length === 0) return null;
        for (let i = 0; i < ps.length; i++)
            if (ps[i] && ps[i].isPlaying) return ps[i];
        return ps[0];
    }

    readonly property bool hasPlayer: root.activePlayer !== null
    readonly property bool playing: root.activePlayer ? root.activePlayer.isPlaying : false
    readonly property string title:  root.activePlayer ? root.activePlayer.trackTitle  : ""
    readonly property string artist: root.activePlayer ? root.activePlayer.trackArtist : ""
    readonly property string artUrl: root.activePlayer ? root.activePlayer.trackArtUrl : ""
    readonly property real position: root.activePlayer ? root.activePlayer.position : 0
    readonly property real length:   root.activePlayer ? root.activePlayer.length   : 0
    readonly property bool canPlay:    root.activePlayer ? root.activePlayer.canPlay    : false
    readonly property bool canPause:   root.activePlayer ? root.activePlayer.canPause   : false
    readonly property bool canNext:    root.activePlayer ? root.activePlayer.canGoNext : false
    readonly property bool canPrev:    root.activePlayer ? root.activePlayer.canGoPrevious : false

    function playPause() { if (root.activePlayer && root.activePlayer.canTogglePlaying) root.activePlayer.togglePlaying(); }
    function next()      { if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next(); }
    function previous()  { if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous(); }
}