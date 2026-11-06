# notchD

A low-memory control center for NixOS + niri, built with Quickshell 0.3.2.
It is a horizontal hub with sideways flyouts, plus a single downward media
card. Everything is keyboard reachable and native QML; there is no Hyprland
dependency and no extra daemon for the control center itself.

## Layout

```
┌───────────────────────────── hub ─────────────────────────────┐
│ 16:06 │ Wi-Fi │ Bluetooth │ Audio │ Battery │ Display │ Session │ ⚙ │
└───────────────────────────────────────────────────────────────┘
        ┌──── flyout (sideways) ────┐        ┌─ media (down) ─┐
        │ detail page               │        │ album art …   │
        └───────────────────────────┘        └────────────────┘
```

- Only the media card grows downward. Every other module opens a side flyout
  to the right of the hub.
- One flyout/media card is open at a time.
- Escape or a click outside steps back; Escape from the hub returns to the pill.
- The pill is still a normal top-edge notch/pill and can be hidden completely.

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
| Display | `brightnessctl`, `gammastep`, niri `power-off-monitors` |
| Session | logind / systemctl, native lock screen |

The gear in the hub opens **Modules**, where modules can be enabled, disabled
and reordered. The order and enabled set are written to
`$XDG_STATE_HOME/notchD/settings.json` through a `FileView` + `JsonAdapter`, so
they survive restarts, config reloads and home-manager rebuilds.

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

## OSD

Volume, microphone, brightness, battery, workspace, night light and theme OSDs
render inside the pill surface. They are transient and never replace an open
hub or flyout. OSD values come from the shared service singletons; modules can
also call `showOsd(kind, {...})`.

## Keybindings

Defined in `dotfiles/niri/config.kdl`:

| Binding | Action |
|---|---|
| `Mod+N` | Open the hub |
| `Mod+Shift+N` | Show/hide the island |
| `Mod+Shift+Space` | Show/hide the island |
| `Super+Alt+L` | Lock with notchD |
| `Mod+Shift+A` | Audio flyout |
| `Mod+Alt+A` | Advanced audio (`pavucontrol`) |
| `Mod+Alt+N` | Wi-Fi flyout |
| `Mod+Alt+Shift+N` | Advanced networks (`nm-connection-editor`) |
| `Mod+Alt+S` | Session flyout |
| `Mod+Alt+M` | Now playing |
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

# media
openMedia / closeMedia / mediaPeek
mediaPlayPause / mediaNext / mediaPrevious

# OSD
showVolume / showMic / showBrightness / showBattery / showWorkspace
showNightLight / toggleNightLight

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
hub index/kinds, media presence, theme, module order and registered modules.

## Files

- `shell.qml` — shell root, windows, lock/idle wiring, persistence, IPC.
- `NotchD.qml` — morphing surface, side flyout loader, downward media card.
- `IslandState.qml` — idle / osd / hub / flyout / media / auth state machine.
- `LockScreen.qml` — `WlSessionLock` + PAM lock screen.
- `Modules.qml` — built-in module registry.
- `Theme.qml` — light/dark palette and geometry.
- `Motion.qml` — duration/easing tokens.
- `components/` — panel, icons, chips, sliders, OSD, auth, media.
- `flyouts/` — Wi-Fi, Bluetooth, audio, battery, display, session, modules.
- `services/` — Quickshell service seams (system, network, Bluetooth, media,
  compositor, session, idle).
- `vendor/` — vendored MIT components (see `vendor/README.md`).
- `LICENSE` — MIT.

## Theming

Global light/dark. `wp` writes the effective mode to
`~/.config/matugen/generated/mode`, and notchD follows the same file as kitty,
foot, fuzzel, mako and the niri border.

- `wp theme auto` — follow the wallpaper's brightness (default)
- `wp theme light` / `wp theme dark` — force it

The same actions are in the desktop right-click menu (Light/Dark/Auto theme).
