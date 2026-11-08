# notchD

A low-memory control center for NixOS + niri, built with Quickshell 0.3.2.
It is a horizontal hub with sideways flyouts, plus a single downward media
card. Everything is keyboard reachable and native QML; there is no Hyprland
dependency and no extra daemon for the control center itself.

## Layout

```
┌───────────────────────────── hub ─────────────────────────────┐
│ 16:06  │ Wi-Fi │ Bluetooth │ Audio │ Battery │ Display │ Session │ ⚙ │
│ Sat 7 Nov                                                      │
└───────────────────────────────────────────────────────────────┘
        ┌──── flyout (sideways) ────┐        ┌─ media (down) ─┐
        │ detail page               │        │ album art …   │
        └───────────────────────────┘        └────────────────┘
```

- Only the media card grows downward. Every other module opens a side flyout
  that docks flush to the right edge of the hub, sharing one continuous edge.
- One flyout/media card is open at a time.
- Escape or a click outside steps back; Escape from the hub returns to the pill.
- The pill floats a few pixels below the top edge instead of sitting on the
  bezel. Notch mode stays flush on purpose.

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

The gear in the hub opens **Modules**, where modules can be enabled, disabled
and reordered. The order and enabled set are written to
`$XDG_STATE_HOME/notchD/settings.json` through a `FileView` + `JsonAdapter`, so
they survive restarts, config reloads and home-manager rebuilds. The default
order groups Wi-Fi, Bluetooth and Battery on the left of the clock; Audio,
Display and Session plus the Modules gear sit on the right.

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
- `NotchD.qml` — morphing surface, side flyout loader, downward media card.
- `IslandState.qml` — idle / osd / hub / flyout / media / auth state machine.
- `LockScreen.qml` — `WlSessionLock` + PAM lock screen.
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
- The hub is one horizontal row: clock and date, an icon+value chip per
  enabled module, a now-playing chip and the Modules gear. Module names live
  in flyout headers, so the row stays readable without a second label line.
- The clock is a single layer owned by the surface, not by a mode. It sits at
  the exact same x in the pill, the hub and a side flyout; the date fades in
  only when the hub expands. Enabled modules split evenly either side of it.
- Hub width is content-driven: `Theme.hubW` is a floor and `HubSurface`
  reports the width its wider chip group needs, so a now-playing chip or a
  long value grows the panel instead of clipping it. The surface stays centred
  while it grows. `Theme.hubSidePad` is the minimum edge breathing room.
- The panel is opaque (`#0b0b0b` dark, `#fafafa` light). The pill and the hub
  are the same black, there is no background blur and no top highlight, so
  the morph cannot pick up the wallpaper or leak a light edge.

## Theming

Global light/dark. `wp` writes the effective mode to
`~/.config/matugen/generated/mode`, and notchD follows the same file as kitty,
foot, fuzzel, mako and the niri border.

- `wp theme auto` — follow the wallpaper's brightness (default)
- `wp theme light` / `wp theme dark` — force it

The same actions are in the desktop right-click menu (Light/Dark/Auto theme).
