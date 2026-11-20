# notchD

A low-memory control center for NixOS + niri, built with Quickshell 0.3.2.
The expanded hub presents media, controls and notifications in three columns.
Module details open in the middle column; Escape steps back to the hub and
then to the pill. Ctrl+Tab switches hub tabs.

## Modules

`Modules.qml` is a built-in registry, not a binary plugin ABI. Each manifest
has an id, title, icon, description and a flyout component. `NotchD.qml` maps
ids to lazy `Component` instances, so a disabled module unloads its page while
the shared Quickshell services stay alive.

| Module | Backend |
|---|---|
| Wi-Fi | `Quickshell.Networking` (NetworkManager), inline WPA/WEP prompt |
| Bluetooth | `Quickshell.Bluetooth` + short-lived `bluetoothctl` pairing |
| Audio | `Quickshell.Services.Pipewire`, MPRIS in the same page |
| Battery | `Quickshell.Services.UPower` + power-profiles-daemon |
| Display | `brightnessctl`, night-light tint overlay, niri `power-off-monitors` |
| Session | logind / systemctl, native lock screen |

The Settings button in the hub opens **Modules**, where modules can be enabled, disabled
and reordered. The order and enabled set are written to
`$XDG_STATE_HOME/notchD/settings.json` through a `FileView` + `JsonAdapter`, so
they survive restarts, config reloads and home-manager rebuilds. The default grid order is Wi-Fi, Bluetooth, Battery, Audio, Display and Session.

### Advanced fallbacks

These remain installed for genuinely advanced tasks, not the normal path:

- `pavucontrol` — `Mod+Alt+A`
- `nm-connection-editor` — `Mod+Alt+Shift+N`
- `overskride` — Bluetooth passkey/agent edge cases
- `swaylock` — recovery if Quickshell ever fails to start

## Lock screen and idle

- `LockScreen.qml` uses `WlSessionLock` and covers every screen. It is the
  primary locker; `Super+Alt+L`, the Session flyout and lid close all invoke
  it through `quickshell ipc`.
- The lock has two pages:
  - page 1 is the ambient clock: time only, over the dotted wallpaper. Any
    key, click or scroll advances to page 2.
  - page 2 is authentication: long date, account, password field, Wi-Fi and
    battery in the bottom corners, and a read-only sidebar with the current
    media activity and recent notifications. Escape clears the password, or
    returns to page 1 when the field is already empty.
- Notification expiry is paused while locked, so the sidebar keeps whatever
  arrived; expiry resumes on unlock. The sidebar is read-only: cards there
  cannot invoke actions or dismiss anything.
- The lock surface draws its own wallpaper (`~/Pictures/walls/dotted.png` by
  default, override with `NOTCHD_LOCK_WALLPAPER`) and darkens it locally. No
  wallpaper daemon is involved: `awww` keeps rendering the session wallpaper,
  `swaybg` is an alternative, and `hyprpaper` is Hyprland-specific.
- No extra lockscreen utility is needed. `WlSessionLock` holds the session
  lock; `swaylock` remains installed as a recovery fallback.
- Authentication uses `PamContext` with the dedicated `quickshell` PAM
  service (`security.pam.services.quickshell` in `modules/nixos/desktop.nix`).
- `services/Idle.qml` uses `IdleMonitor` (`ext-idle-notify-v1`):
  - lock after 5 minutes
  - displays off after 10 minutes
  - suspend after 20 minutes, only on battery
- Idle inhibitors are respected by default.

## Night light

The Display flyout controls a 1700–6500 K slider with 2700/3400/4500/5500 K
presets. The value is persisted in `settings.json` and moving the control
enables the effect.

This machine's NVIDIA output advertises `zwlr_gamma_control_v1` but answers
`failed()`, and `gammastep` hangs forever on that failure. Night light is
therefore a full-screen, click-through warm tint (`components/NightLight.qml`)
rather than a gamma ramp. The tint colour comes from a blackbody
approximation and its opacity scales with warmth, so it also lifts blacks
slightly. The UI labels it as a tint, not calibrated colour.

## OSD

Volume, microphone, brightness, battery, workspace, night light and theme OSDs
render inside the pill surface. They are transient and never replace an open
hub or flyout. OSD values come from the shared service singletons; modules can
also call `showOsd(kind, {...})`.

## Notifications

There is no separate notification daemon. `services/Notifications.qml` wraps
`Quickshell.Services.Notifications.NotificationServer`, so notchD itself owns
`org.freedesktop.Notifications`; `NotificationPopups.qml` draws up to four
cards in a top-right overlay. Card timeouts follow the sender's `expire-time`
(`0` never expires, `-1` uses 8 s), critical notifications never expire, and
hovering pauses the timer. Left-click invokes the default action, the close
button dismisses. Cards are hidden while the shell is locked and while the
hub is open; they stay tracked and appear when it closes. While
locked they are shown read-only in the lock screen sidebar, and expiry is
paused until unlock.

Cost: zero extra processes and no steady-state CPU. Four cards peak at about
5 MiB of additional memory in the already-running shell.

## Desktop home widgets

`HomeWidgets.qml` paints a small 2×2 cluster of stat tiles (CPU, memory,
uptime, battery) on the wallpaper. It is a `WlrLayer.Bottom` surface with an
empty input mask, so it sits above the wallpaper but below normal windows and
never steals clicks: right-clicking the desktop still opens `DesktopMenu`.

Niri keeps an always-empty workspace above the first one
(`empty-workspace-above-first`). `Mod+0` focuses it; `Mod+1..9` focus the
normal workspaces (positions 2..10). The widget surface is only mapped while
that home workspace is focused, so the spare empty workspace niri keeps at
the bottom stays plain wallpaper. `Mod+Alt+H` (or the `toggleHome` IPC call)
enables/disables the widgets; `status.home` reports that toggle.

## Keybindings

Defined in `dotfiles/niri/config.kdl`:

| Binding | Action |
|---|---|
| `Mod+N` | Open the hub, or close it again if it is already open |
| `Mod+Shift+N` | Show/hide the island |
| `Mod+Shift+Space` | Show/hide the island |
| `Super+Alt+L` | Lock with notchD |
| `Mod+Shift+A` | Audio flyout |
| `Mod+Alt+A` | Advanced audio (`pavucontrol`) |
| `Mod+Alt+N` | Wi-Fi flyout |
| `Mod+Alt+Shift+N` | Advanced networks (`nm-connection-editor`) |
| `Mod+Alt+S` | Session flyout |
| `Mod+Alt+M` | Now playing |
| `Mod+Alt+H` | Toggle the desktop home widgets |
| `Mod+Shift+B` | Brightness 60% + OSD |

The hub is also fully keyboard driven: arrows move between chips, `1`–`6`
open a module directly, `m` opens now playing, `s` opens Modules, Enter opens
the focused chip and Escape steps back. `quickshell ipc -c notchD call notchD
toggleStyle` switches between the pill and notch shapes without a dedicated
binding.

Media, volume and brightness hardware keys keep their fast CLI action and then
call notchD for the visual feedback, so they still work while the shell is
restarting.

## IPC

```sh
quickshell ipc -c notchD call notchD status

# surfaces
expand / collapse / back / toggleExpanded
openHub / openWifi / openBluetooth / openAudio / openBattery / openDisplay
openSession / openSettings
toggleHome / showHome / hideHome

# media
openMedia / closeMedia / mediaPeek
mediaPlayPause / mediaNext / mediaPrevious

# OSD
showVolume / showMic / showBrightness / showBattery / showWorkspace
showNightLight / toggleNightLight
setNightLightTemp <1700-6500> / nightLightWarmer / nightLightCooler

# actions
volumeUp / volumeDown / toggleMute / toggleMic
brightnessUp / brightnessDown
lock / unlock

# modules
enableModule <id> / disableModule <id> / toggleModule <id>
moveModule <id> <delta>

# appearance
toggleStyle / setStyle pill|notch
setTheme light|dark / toggleTheme
```

`status` returns JSON with style, hidden, lock state, current surface, flyout,
hub index/kinds, media presence, theme, night-light state, module order and
registered modules.

## Files

- `shell.qml` — shell root, windows, lock/idle wiring, persistence, IPC.
- `HomeWidgets.qml` — desktop home widgets (CPU, memory, uptime, battery) on the wallpaper.
- `NotchD.qml` — morphing surface and middle-column detail loader.
- `IslandState.qml` — idle / osd / hub / flyout / media / auth state machine.
- `LockScreen.qml` — two-page `WlSessionLock` + PAM lock screen.
- `components/LockSidebar.qml` — read-only lock-screen activity/notifications sidebar.
- `Modules.qml` — built-in module registry.
- `Theme.qml` — light/dark palette, type scale and geometry tokens.
- `Motion.qml` — duration/easing tokens.
- `components/` — panel, icons, chips, sliders, OSD, auth, media, night light.
- `flyouts/` — Wi-Fi, Bluetooth, audio, battery, display, session, modules.
- `services/` — Quickshell service seams (system, network, Bluetooth, media,
  compositor, session, idle).
- `vendor/` — vendored MIT components (see `vendor/README.md`).
- `LICENSE` — MIT.

## Design

The island is tuned for the 14" 1080p panel at niri scale 1.1 (~130 logical
PPI). `Theme.qml` is the single source of truth:

- Type: nothing below 11 px (`fontLabel`), 12 px body (`fontBody`), 14 px
  titles and hub clock. Pixel sizes are written as tokens, not magic numbers,
  in the flyouts and shared components.
- Shape: exactly three radii — 16 px cards, 10 px controls, 18 px pill.
- Colour: one accent (status dots only); everything else is foreground,
  muted, hairline and surface. `muted` is `#a1a1aa` in dark mode because
  `#8f8f8f` fails contrast at 11 px.
- The hub keeps media on the left, tabs and module controls in the middle,
  and actionable notifications on the right. Module details scroll in the
  middle column when the available height is limited.
- The idle pill shows the clock and a compact media indicator. The hub size is
  constrained to the selected screen.
- The panel is opaque (`#0b0b0b` dark, `#fafafa` light). The pill and the hub
  are the same black, there is no background blur and no top highlight, so
  the morph cannot pick up the wallpaper or leak a light edge.

## Theming

Global light/dark. `wp` writes the effective mode to
`~/.config/matugen/generated/mode`, and notchD follows the same file as kitty,
foot, fuzzel and the niri border. Notifications are drawn by notchD itself
(`NotificationPopups.qml` + `services/Notifications.qml`) and follow `Theme`.

- `wp theme auto` — follow the wallpaper's brightness (default)
- `wp theme light` / `wp theme dark` — force it

The same actions are in the desktop right-click menu (Light/Dark/Auto theme).

The expanded island groups media, controls and notifications from left to right.
The center tabs expose Controls, Performance, Limits and Clipboard; the
wallpaper button opens the picker. `qs ipc call notchD openClipboard` opens
the clipboard tab, and `openWallpapers`, `toggleWallpapers`, and
`closeWallpapers` control the picker. Limits are populated only when a local
usage feed is available. The shell continues to use the matugen palette.

## Clipboard and usage

`Mod+V` opens native Quickshell clipboard history. Search, use ↑/↓ to preview,
Enter to copy, Delete to remove, and Escape to close. `cliphist` still stores
text and images; a terminal picker is retained for shell recovery.

Performance samples CPU, memory and uptime every five seconds while visible.
Limits reads an optional local usage feed; see [USAGE.md](USAGE.md). No provider
API adapter is included, so unavailable limits stay explicitly unavailable.

## Wallpaper picker

Open **Wallpapers** from Controls, or run:

```sh
quickshell ipc -c notchD call notchD openWallpapers
```

The bottom preview and thumbnail strip browse `~/Pictures/walls`; override
with `NOTCHD_WALLS_DIR`. Search by filename, use ←/→ to select, Enter to apply,
and Escape to close. Apply invokes the existing `wp` command, preserving awww
transitions and matugen. Favorites use the same file as `wp fav`.
