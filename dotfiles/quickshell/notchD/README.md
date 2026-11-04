# notchD

Minimal Dynamic Island / ColorOS-style top-center pill for Niri on Wayland, built with Quickshell 0.3.2.

## What it is

- A small pill anchored to the top edge of the primary screen.
- Shows **only the current time** (`HH:mm`).
- Hide/show is **total**: when hidden, nothing remains on screen.
- Clicking the pill or pressing `Mod+Shift+Space` hides/shows it.

The earlier expanded info panel (battery, volume, workspace indicator, theme dots) has been removed. If you want panel content again later, see **TODO** below.

## Keybindings

Related Niri bindings (defined in `../../dotfiles/niri/config.kdl`):

| Binding | Action |
| --- | --- |
| `Mod+Shift+Space` | Hide/show the notch via `quickshell ipc -c notchD call notchD toggle` |

Interactions:

| Input | Effect |
| --- | --- |
| Click on pill | Hide/show the notch |

Niri workspace changes no longer pop up anything.

## Files

- `shell.qml` — `ShellRoot`, primary-screen `PanelWindow`, and the `notchD` IPC handler.
- `NotchD.qml` — the pill and its hide/show/theme logic.
- `themes.js` — colour themes (Black is the default).
- `README.md` — this file.

No workspace/battery/volume/weather processes are started anymore.

## Quick test

This config is registered as `programs.quickshell.configs.notchD` with
`activeConfig = "notchD"` (see `../../home/quickshell.nix`) and bound to
`Mod+Shift+Space`. For an isolated test against the working tree:

```sh
quickshell --path "$PWD"
```

## IPC

```sh
# Hide/show the whole notch; nothing is left on screen while hidden
quickshell ipc -c notchD call notchD toggle
quickshell ipc -c notchD call notchD hide
quickshell ipc -c notchD call notchD show

# Theme management (not exposed in the UI; useful for reloading/testing)
quickshell ipc -c notchD call notchD setTheme gruvbox
quickshell ipc -c notchD call notchD setTheme eink
quickshell ipc -c notchD call notchD setTheme vercel
quickshell ipc -c notchD call notchD cycleTheme
quickshell ipc -c notchD call notchD currentTheme

# Hard reload of the shell without restarting the process
quickshell ipc -c notchD call notchD reload
```

## Themes

Themes are ordinary JS objects in `themes.js`. Current themes:

| Name | Style |
| --- | --- |
| `gruvbox` | Gruvbox Dark with warm accent |
| `eink` | Light near-white paper / e-ink |
| `vercel` | Black (Vercel/Linear inverse e-ink), default |

Theme selection persists across Quickshell reloads via `PersistentProperties`.

## Mouse interactions and future potential

Currently implemented:

- **Click on pill** — hide/show the notch.

Ideas that could be added later (not implemented):

- **Hover enter/leave** — reveal quick controls or toggle the pill without clicking; needs a slightly wider invisible hit area if the visible pill stays small.
- **Hover position** — detect which part of the pill was hovered (if it is widened) to show icons/tooltips.
- **Scroll over pill** — switch Niri workspaces (`niri msg action focus-workspace-up/down`); could also adjust volume or brightness over dedicated zones.
- **Right-click pill** — open a small context menu (theme picker, mute/unmute, hide).
- **Middle-click pill** — cycle themes quickly.
- **Double-click pill** — launch fuzzel or toggle the notch.
- **Press and hold pill** — hide the notch; a different hold gesture could restore it.
- **Drag down from pill** — "pull to dismiss" style gesture; same effect as `toggle()`.
- **Hover tooltips** — show workspace name/index if the workspace indicator is re-added.

Limits:

- Hover only works while the pointer is over the pill; it does not work when the notch is hidden.
- Two-finger trackpad scroll is delivered as `wheel` events; three/four-finger swipes are compositor-level and are not exposed to Quickshell as mouse events.
- If an expanded panel returns later, keep its hit area reasonably large and add a hover-leave delay so it does not flicker.

## Reloading the config

```sh
# Reloads the running notchD (nearest thing Quickshell has to a refresh)
systemctl --user restart quickshell
quickshell ipc -c notchD call notchD reload
```

The IPC reload only exists after applying a generation that includes it. A shell restart loads whatever is currently registered under `~/.config/quickshell/notchD`; it does not include unapplied edits from the working tree.

## Notes

- The pill width/height (`targetWidth`/`targetHeight`) are set in `NotchD.qml`.
- `hidden` is handled by the PanelWindow's `visible` property; hidden means completely gone from the screen.
- Niri's workspace event stream is intentionally not used anymore, so the pill does not change when you switch workspaces.
