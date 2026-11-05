# notchD

Minimal Dynamic Island for Niri on Wayland, built with Quickshell 0.3.2.
Supports both **pill** and **notch** styles (toggle via IPC or `Mod+Shift+N`).

## What it is

- A small pill anchored to the top edge of the primary screen.
- Shows the current time; hover/click expands to a panel with date, battery,
  volume, brightness, media and niri workspace dots.
- Hide/show is total: when hidden, nothing remains on screen.
- Clicking the pill or `Mod+Shift+Space` hides/shows it.
- Click pins the expanded panel; click outside or Escape collapses it.
- Volume/brightness OSD peeks via `showVolume` / `showBrightness`.

## Keybindings

Related Niri bindings (defined in `../../dotfiles/niri/config.kdl`):

| Binding | Action |
|---|---|
| `Mod+Shift+Space` | Hide/show the notch |
| `Mod+Shift+N` | Toggle pill ↔ notch style |
| `Mod+N` | Expand the notch |

OSD peeks (add to niri config):

```kdl
XF86AudioRaiseVolume { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; spawn "quickshell" "ipc" "-c" "notchD" "call" "notchD" "showVolume"; }
XF86MonBrightnessUp  { spawn "brightnessctl" "set" "+5%"; spawn "quickshell" "ipc" "-c" "notchD" "call" "notchD" "showBrightness"; }
```

## IPC

```sh
toggle / hide / show
expand / collapse
peek <surface>
showVolume / showBrightness
toggleStyle / setStyle pill|notch
status          # JSON
```

## Files

- `shell.qml` — ShellRoot, overlay PanelWindow, dismiss layer, IPC.
- `IslandState.qml` — state machine.
- `NotchD.qml` — capsule, ears, surfaces, animations.
- `Theme.qml` — black/white palette (singleton).
- `Motion.qml` — duration/easing tokens.
- `IslandWindow.qml` — (unused wrapper, kept for future multi-monitor).
- `services/Compositor.qml` — niri workspaces via ext-workspace-v1.
- `services/Media.qml` — MPRIS.
- `services/System.qml` — UPower, volume, brightness.
- `vendor/` — vendored MIT components (see `vendor/README.md`).
- `LICENSE` — MIT.

## Themes

Single Vercel-style black/white palette. No theme switching.