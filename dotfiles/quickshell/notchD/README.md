# notchD

Dynamic Island / ColorOS-style top-center pill for Niri on Wayland, built with Quickshell 0.3.2.

## Features

- Compact pill anchored to the top edge of the primary screen.
- Live clock and date, always visible in the collapsed state.
- Click the pill to toggle collapsed/expanded.
- Hide/show the pill through IPC. When hidden, only a thin sliver remains as a target for showing it again.
- Expanded state shows a large clock, date, battery, volume, workspace number and workspace indicator row.
- Niri workspace-aware temporary expansion with iOS-like width/height/radius morphing.
- Three themes defined centrally in `themes.js`: `gruvbox`, `eink`, `vercel`.
- Theme selection persists across Quickshell reloads via `PersistentProperties`.

## Files

- `shell.qml` — `ShellRoot`, primary-screen `PanelWindow`, and the `notchD` IPC handler.
- `NotchD.qml` — the pill itself, Niri event integration, battery/volume polling, animations and theme switching.
- `Workspaces.qml` — workspace indicator segment row.
- `themes.js` — all colors/themes and small theme helpers.
- `README.md` — this file.

## Quick test

```sh
quickshell --config notchD
```

Register it as your Home Manager named Quickshell config if desired; this directory is intentionally self-contained.

## IPC

Quickshell 0.3.2 exposes functions through `IpcHandler`.

```sh
# Toggle collapsed/hidden state
quickshell ipc -c notchD call notchD toggle

# Expand / collapse explicitly
quickshell ipc -c notchD call notchD expand
quickshell ipc -c notchD call notchD collapse

# Hide and show the pill
quickshell ipc -c notchD call notchD hide
quickshell ipc -c notchD call notchD show

# Switch themes
quickshell ipc -c notchD call notchD setTheme gruvbox
quickshell ipc -c notchD call notchD setTheme eink
quickshell ipc -c notchD call notchD setTheme vercel
quickshell ipc -c notchD call notchD cycleTheme
quickshell ipc -c notchD call notchD currentTheme

# Inspect workspace state
quickshell ipc -c notchD call notchD workspaceInfo
```

Bind these to keys in your Niri config as desired. This repo binds
`Mod+Shift+Space` to `toggle`.

## Themes

Themes are ordinary JS objects in `themes.js`. Edit color values there or add a new theme to the `themes` map and `names()` list.

Current themes:

| Name | Style |
| --- | --- |
| `gruvbox` | Gruvbox Dark with warm accent |
| `eink` | Light near-white paper / e-ink |
| `vercel` | Vercel/Linear-like inverse e-ink |

Theme changes happen at runtime from expanded view dots or from `setTheme()`. `PersistentProperties` keeps the selected theme across Quickshell reloads. It is not a full disk-backed application settings system, so a cold restart may rely on the default/reloadable value path.

## Font

The pill prefers `Roboto`. Qt's QML font properties do not provide per-text comma-separated family fallback strings, so the code uses `font.family: "Roboto"` and relies on fontconfig for fallback behavior when it is absent. To change fonts, edit the `font.family` strings in `NotchD.qml`; suggested replacements are `Inter`, `Noto Sans`, or `SF Pro Display`.

## Niri integration

Uses a long-running JSON event stream:

```sh
niri msg --json event-stream
```

Parsed events and fields:

### `WorkspacesChanged`
```json
{ "WorkspacesChanged": { "workspaces": [ ... ] } }
```
Used to replace the workspace list, track indices, active/focused state, output and `active_window_id`.

### `WorkspaceActivated`
```json
{ "WorkspaceActivated": { "id": 1, "focused": true } }
```
Marks the activated workspace active on its output. If `focused == true`, the pill temporarily expands to show the workspace indicator.

### `WorkspaceActiveWindowChanged`
```json
{ "WorkspaceActiveWindowChanged": { "workspace_id": 1, "active_window_id": 12 } }
```
Updates the active window for a workspace and therefore whether the workspace counts as occupied.

### `WindowsChanged`
```json
{ "WindowsChanged": { "windows": [ ... ] } }
```
Seeds the occupied-workspace calculation.

### `WindowOpenedOrChanged`
```json
{ "WindowOpenedOrChanged": { "window": { ... } } }
```
Updates one workspace's occupied state without replacing the whole list.

### `WindowClosed`
```json
{ "WindowClosed": { "id": 12 } }
```
Removes a window from the occupied-workspace calculation.

Also subscribes to:

```sh
niri msg --json workspaces
niri msg --json windows
niri msg --json outputs
```

These seed initial state and for reference. If Niri is not running or IPC fails, the widget logs a warning and keeps running; it does not crash.

## Multi-monitor behavior

Only the first screen in `Quickshell.screens` is used. This keeps the implementation simple and avoids duplicate IPC target registration. To change it, edit `primaryScreen` in `shell.qml`; to target a named output, filter `Quickshell.screens` by `name`.

## Known limitations / test at runtime

- The whole window is anchored to the top-left edge with a computed left margin; it is not a full-width transparent strip.
- `WorkspaceActivated.focused` triggers the temporary expansion. Activating a workspace on another output should not expand the primary pill.
- Workspace occupancy is inferred from `WindowsChanged`, `WindowOpenedOrChanged`, `WindowClosed` and `active_window_id`; scrolling-layout edge cases may not be perfect until Niri emits the full update.
- Theme persistence is reload-persistence, not guaranteed disk persistence across a cold Quickshell start.
- Battery reading uses the first `/sys/class/power_supply/BAT*` with a readable `capacity`.
- Volume uses `wpctl get-volume @DEFAULT_AUDIO_SINK@` and is polled every 10 seconds.
- Niri/Quickshell paths are assumed to be on `PATH` for `niri` and `wpctl`; otherwise only workspace/battery/volume features are affected.
- No compositor background blur is used; colors are solid/nearly opaque for portability.

## Validation status

This configuration was run against Quickshell 0.3.2 on Wayland and loaded
without QML errors. Its IPC surface was exercised successfully:

```sh
quickshell ipc -c notchD call notchD currentTheme   # -> gruvbox
quickshell ipc -c notchD call notchD workspaceInfo  # -> {"id":1,"idx":1,"known":true}
quickshell ipc -c notchD call notchD setTheme eink  # -> true
quickshell ipc -c notchD call notchD toggle
```

For future edits, run `quickshell --config notchD` and watch:

```sh
journalctl --user -u quickshell -f
```
