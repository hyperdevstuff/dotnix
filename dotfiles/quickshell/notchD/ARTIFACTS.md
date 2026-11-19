# NotchD artifact guidelines

An **artifact** is anything that wants a place in the island: now playing, a
volume change, a battery warning, a timer, a download, an incoming call, or a
polkit prompt. This document defines which presentation an artifact may use,
what it may show there, and whether it is allowed to take focus.

The model is adapted from Apple's Live Activities / Dynamic Island guidelines,
but sized for a small top-centre Linux island that is **not** interactive by
default. The guiding rule is simple:

> Passive information earns a glance, never focus.

## The five presentations

| Presentation | What it is | Who opens it | Keyboard focus | Lifetime |
|---|---|---|---|---|
| **Minimal** | A single glyph, dot, or album-art tile in the idle pill. No text, no controls. | Automatic, from state. | Never | While the activity is ongoing. |
| **Compact** | The idle pill (or a hub chip) with one activity's essential value: title, count, percentage, or countdown. | Automatic, from state. | Never | While the activity is ongoing; collapses when it ends. |
| **Expanded** | The hub, a side flyout, or the downward media card. Details and controls live here. | **User only**: click, `Mod+N`, a module key, or IPC. | Yes, while open | Until the user goes back, clicks outside, or presses Escape. |
| **OSD** | A brief system-feedback pill: volume, brightness, mic, workspace, theme. | User action or a system event. | Never | 2.2 s (caller may override). Never replaces an open expanded surface. |
| **Modal** | A blocking prompt that needs an answer: polkit authentication or the lock screen. | The system, with an explicit reason. | Yes, required | Until answered or cancelled. |

### Minimal

Minimal is the *only* presentation allowed in the idle pill without the user
doing anything. It must survive being glanced at for half a second.

Allowed:
- one icon or glyph (play/pause, microphone, timer, download arrow)
- one 5 px status dot (playing, muted, charging, recording)
- one 18×18 album-art tile

Not allowed: text, progress bars, multiple badges, animation that loops for
attention, or a click target that changes the current surface without the user
clicking it.

### Compact

Compact adds exactly one datum to the pill or an existing hub chip. It still
does not open a surface or move focus.

Allowed:
- a short title (elided, one line)
- a percentage (`72%`)
- a short countdown (`04:31`)
- one small progress indicator
- a play/pause glyph plus a mute glyph

Not allowed: more than two pieces of information, transport controls in the
idle pill, scrolling marquees, or anything below 11 px.

### Expanded

Expanded is the only place for controls, full titles, long lists, sliders,
keyboards, and destructive actions. It is **always user-invoked**.

Allowed:
- the hub and its module chips
- side flyouts (Wi-Fi, Bluetooth, Audio, Battery, Display, Session, Settings)
- the downward media card with transport and progress
- a media card opened by `Mod+Alt+M`, the hub chip, or IPC

Not allowed: opening an expanded surface from a title change, a progress tick,
a network event, or a new notification. Those update compact state or raise an
OSD.

### OSD

OSD is feedback for something the user just did, or a brief system event. It
uses the pill surface, never a flyout or the media card.

Rules:
- one OSD at a time; a new OSD replaces the old one
- OSD never clobbers an open hub, flyout, media card, or auth prompt
- OSD never takes keyboard focus
- default 2.2 s, with a caller-provided timeout

### Modal

Only two things may be modal: authentication and the lock screen. A modal may
take keyboard focus and must say why it is there. It restores the previous
surface when it closes.

## Hard rules

1. **No automatic expansion.** A state change may update minimal or compact
   content. It may raise an OSD if it is feedback for a user action. It may not
   open the hub, a flyout, or the media card.
2. **No automatic keyboard focus.** Passive surfaces use
   `WlrKeyboardFocus.None`. Only `hub`, `flyout`, user-opened `media`, and
   `auth` may request `Exclusive`.
3. **One expanded surface at a time.** Opening a flyout closes the media card
   and vice versa. `Escape` and an outside click step back one level.
4. **One primary activity.** If several activities are ongoing, one gets the
   compact slot. The others reduce to a minimal dot, or wait. Do not rotate
   rapidly; rotate only when the primary ends or the user acts.
5. **Priority is explicit.** `auth` > critical system warning > user-opened
   surface > active media/timer/call > passive status. An OSD never outranks a
   modal or an open expanded surface.
6. **Bound the lifetime.** An activity ends when its task ends. Do not leave a
   stale compact card forever; drop back to minimal or idle. Paused media may
   stay compact, but it must not animate as if playing.
7. **No attention-seeking motion.** No looping bounce, flashing, or marquee in
   minimal or compact. Motion explains a state change, then stops.
8. **Respect the type scale.** Nothing below 11 px. Compact titles are 12 px
   and elided. Expanded body text is 12 px, the hub clock is 14 px.
9. **Protect secrets.** Do not put passwords, 2FA codes, private message text,
   or sensitive titles in minimal or compact content. Those belong in an
   expanded card, and should be hidden while locked or screen-sharing.
10. **Click means "open the detail", not "toggle something".** Minimal and
    compact may open the owning expanded surface. They do not contain inline
    controls.
11. **No ads, promotions, or unrelated tips.** An artifact must represent an
    ongoing task, a system state, or a direct response to the user.
12. **OSD and compact are not a notification channel.** Notifications keep
    their own top-right cards. Use an OSD only for immediate feedback.

## Content budget

| State | Glyph | Text | Value | Controls | Focus | Max width |
|---|---|---|---|---|---|---|
| Minimal | 1 | none | 1 dot | none | none | 18 px tile in the pill |
| Compact (pill) | 1 | 1 elided line | 1 | none | none | pill grows by 34 px |
| Compact (hub chip) | 1 | 1 line, 96 px max | 1 | none | none | 108 px chip |
| Expanded | many | full | full | yes | yes | surface-specific |
| OSD | 1 | 1 title + 1 value | 1 | none | none | 320 px |

## Artifact catalog

| Artifact | Minimal | Compact | Expanded | Notes |
|---|---|---|---|---|
| Now playing | album-art tile + playing dot in the idle pill | hub now-playing chip (glyph + title) | media card (art, title, artist, progress, transport) | Never auto-expands. Click tile/chip or `Mod+Alt+M`. |
| Volume | muted dot | hub Audio chip percentage | Audio flyout slider | OSD on wheel/hardware keys. |
| Microphone | muted/in-use dot | Audio chip state | Audio flyout input slider | OSD on mute toggle. |
| Brightness | — | Display chip percentage | Display flyout slider/presets | OSD on `Mod+Shift+B` and brightness keys. |
| Battery | low/charging dot | hub Battery chip percentage | Battery flyout | OSD on low battery or explicit query. |
| Wi-Fi | connected dot | hub Wi-Fi chip (On/Off/No link) | Wi-Fi flyout, inline password prompt | Password prompt is focused only inside the open flyout. |
| Bluetooth | connected dot | hub Bluetooth chip | Bluetooth flyout | Pairing prompts stay inside the flyout. |
| Notifications | unread dot (optional) | unread count chip (optional) | top-right notification cards, not the island | Cards never take keyboard focus. |
| Workspace switch | — | — | — | OSD only; automatic but transient and non-focusable. |
| Night light | warm-tint dot | Display chip state | Display flyout Kelvin control | The full-screen tint is a passive overlay, not an artifact. |
| Theme change | — | — | — | OSD only. |
| Session/power | — | — | Session flyout | Destructive actions keep the inline arm/confirm step. |
| Modules/settings | — | — | Settings flyout | User-invoked only. |
| Lock/auth | — | — | — | Modal: full-screen lock or the island auth card. May take focus. |
| Future: timer/alarm | timer dot | countdown digits | timer card with pause/cancel | OSD on completion. |
| Future: download/update | progress dot | percentage + short label | download list/card | No focus until opened. |
| Future: call | caller avatar dot | caller name + duration | call card with answer/decline | Ringing may raise a compact state, never an automatic expanded card. |

## Media, the reference implementation

Media is the first artifact that follows this model end to end:

- `services/Media.qml` exposes the MPRIS state.
- The idle pill renders a compact 18×18 album-art tile with a playing dot
  (`NotchD.qml`, `mediaPill`). It does not change `IslandState.mode`.
- Track/title/play-state changes no longer call `peekMedia()`. They update the
  tile in place.
- `Mod+Alt+M`, the hub now-playing chip, the `m` key, and the `openMedia` IPC
  call open the expanded media card (`mode === "media"`,
  `mediaReturnMode === "hub"`). Only that path takes keyboard focus.
- Hardware media keys still call `mediaPeek()`: the user pressed a key, so a
  short expanded peek is intentional feedback. It remains pointer-only
  (`mediaReturnMode === "idle"`).

If you add a new artifact, copy this split: a passive compact binding, an
explicit expanded entry point, and no focus in between.

## Implementation map

| Concern | Where |
|---|---|
| Mode and focus flags | `IslandState.qml` — `mode`, `interactive`, `keyboardInteractive` |
| Layer focus | `shell.qml` — `WlrLayershell.keyboardFocus` follows `keyboardInteractive` |
| QML key handling | `NotchD.qml` — `focus: state.keyboardInteractive` |
| Pill and compact indicator | `NotchD.qml` — `targetW`, `mediaPill` |
| Expanded media | `components/MediaSurface.qml` |
| Hub chips | `components/HubSurface.qml` |
| OSD | `components/OsdSurface.qml` |
| Notifications | `NotificationPopups.qml` |
| Lock/auth | `LockScreen.qml`, `components/AuthCard.qml` |

## Checklist for a new artifact

- [ ] Does it represent an ongoing task, system state, or direct feedback? If
      not, it is a notification, not an artifact.
- [ ] What is its minimal form: one glyph or one dot?
- [ ] What is its compact form: one datum that fits beside the clock?
- [ ] What does expanded add, and why does the user need to open it?
- [ ] Does it ever open itself? It must not.
- [ ] Does it ever request keyboard focus outside an explicit user action? It
      must not.
- [ ] Does it end when the task ends, and what happens to stale state?
- [ ] Is anything sensitive visible while locked or screen-sharing?
- [ ] Does it respect the 11 px type floor and the Theme size scale?

## References

- Apple HIG, Live Activities: <https://developer.apple.com/design/human-interface-guidelines/live-activities>
- Apple ActivityKit, displaying live data: <https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities>
- Apple ActivityKit push updates: <https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications>
