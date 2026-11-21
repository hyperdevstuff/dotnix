# notchD

A low-memory control center for NixOS + niri, built with Quickshell 0.3.2.
The expanded hub presents media, controls and notifications in three columns.
Module details replace the dashboard; Escape steps back to the hub and
then to the pill. Ctrl+Tab switches hub tabs.

The current feature audit, remaining gaps and design rules are recorded in
[DESIGN-STATUS.md](DESIGN-STATUS.md).

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

The Settings button opens **Appearance**; its **Modules** action opens the module
registry, where modules can be enabled, disabled and reordered. The order and enabled set are written to
`$XDG_STATE_HOME/notchD/settings.json` through a `FileView` + `JsonAdapter`, so
they survive restarts, config reloads and home-manager rebuilds. The dashboard uses split Wi-Fi, Bluetooth, Audio and Night light controls. Primary
actions toggle their state; separate chevrons open details. Battery percentage
and power profile live in Performance and power details.

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
  - page 1 is the ambient clock and date, grouped halfway between the top edge and center
    of the wallpaper. Any key, click or scroll advances to page 2; that first
    key is consumed rather than typed into the password field.
  - page 2 is authentication: long date, a 96px account avatar, larger labels,
    a 64px filled password field with a 48px unlock target, Wi-Fi and
    battery in the bottom corners, and a read-only sidebar with the current
    media activity and recent notifications. Escape clears the password, or
    returns to page 1 when the field is already empty.
- The lock uses the dark matugen palette even when the desktop is in light
  mode. `components/LockContent.qml` owns presentation; the session-lock and
  PAM controller remain in `LockScreen.qml`. Short outputs scroll the sign-in
  form, and reduced motion removes page movement. The sidebar remains passive.
  Visual and keyboard checks are in
  [tests/lockscreen](../../../tests/lockscreen/README.md).
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

notchD owns the native notification server. The service runs one expiry clock
for all live notifications; cards never create competing lifetime timers.
Sender timeouts use milliseconds in Quickshell 0.3. Persistent and critical
notifications do not auto-expire, and hovering or locking pauses expiry.

Up to four popups appear at the top right. DND suppresses popups while retaining
history. The dashboard center groups up to 100 plain snapshots by date, with
clear and dismiss controls; snapshots survive toast expiry and never retain
expired notification objects. Live notifications retain their actions, while
expired history cards do not offer dead actions. History is currently in memory
and resets when the shell restarts. Transient notifications are popup-only.

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
| `Mod+Shift+S` | Select a screenshot region, then annotate, copy or save |

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
openSession / openSettings / openAppearance / openActivity / openCalendar / openTray
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
keepAwake <15|30|60> / stopKeepAwake
lock / unlock

# modules
enableModule <id> / disableModule <id> / toggleModule <id>
moveModule <id> <delta>

# appearance
toggleStyle / setStyle pill|notch
setTheme light|dark / toggleTheme
setAppearance clock12|reduceMotion <0|1>
setAppearance textScale <1.0-1.2>
setAppearance opacity <0.70-1.0>
```

`status` returns JSON with style, hidden, lock state, current surface, flyout,
hub index/kinds, media presence, theme, night-light state, module order and
registered modules.

## Files

- `shell.qml` — shell root, windows, lock/idle wiring, persistence, IPC.
- `HomeWidgets.qml` — desktop home widgets (CPU, memory, uptime, battery) on the wallpaper.
- `NotchD.qml` — morphing surface, tab pages and replacement detail loader.
- `IslandState.qml` — idle / osd / hub / flyout / media / runner / auth state machine.
- `LockScreen.qml` — two-page `WlSessionLock` + PAM lock screen.
- `components/LockSidebar.qml` — read-only lock-screen activity/notifications sidebar.
- `components/LockContent.qml` — two-page dark-matugen lock presentation.
- `Modules.qml` — built-in module registry.
- `Theme.qml` — light/dark palette, type scale and geometry tokens.
- `Motion.qml` — duration/easing tokens.
- `components/` — panel, icons, chips, sliders, OSD, auth, media, night light.
- `flyouts/` — Wi-Fi, Bluetooth, audio, battery, display, session, modules.
- `services/` — Quickshell service seams (system, network, Bluetooth, media,
  compositor, session, idle).
- `vendor/` — vendored MIT components (see `vendor/README.md`).
- `LICENSE` — MIT for the original shell; adapted components have their own
  license notices and attribution directories.

## Design

The island is tuned for the 14" 1080p panel at niri scale 1.1 (~130 logical
PPI). `Theme.qml` is the single source of truth:

- Type: nothing below 11 px (`fontLabel`), 12 px body (`fontBody`), 14 px
  titles and hub clock. Pixel sizes are written as tokens, not magic numbers,
  in the flyouts and shared components.
- Shape: shared card, control and capsule tokens, with the surface radii
  driven by the same spring as its dimensions.
- Colour: matugen semantic surfaces, foreground and accent tokens, with
  fallback palettes when generated colors are unavailable.
- Dashboard keeps media on the left, controls in the middle, and notifications
  on the right (roughly 30% / 35% / 35% of the dashboard). Top tabs select dedicated views; module details replace them
  and scroll when the available height is limited.
- The idle pill shows the clock and a compact media indicator. The hub size is
  constrained to the selected screen.
- The pill and expanded surface share a panel color. Panel opacity defaults
  to 1 and can be set between 0.70 and 1 through the command palette.

## Theming

Global light/dark. `wp` writes the effective mode to
`~/.config/matugen/generated/mode`, and notchD follows the same file as kitty,
foot, fuzzel and the niri border. Notifications are drawn by notchD itself
(`NotificationPopups.qml` + `services/Notifications.qml`) and follow `Theme`.

- `wp theme auto` — follow the wallpaper's brightness (default)
- `wp theme light` / `wp theme dark` — force it

The same actions are in the desktop right-click menu (Light/Dark/Auto theme).

The expanded island groups media, controls and notifications from left to right.
The top tabs expose Dashboard, Media and Performance; the
wallpaper button opens the picker. `quickshell ipc -c notchD call notchD openClipboard` opens
the clipboard tab, and `openWallpapers`, `toggleWallpapers`, and
`closeWallpapers` control the picker. Limits are populated only when a local
usage feed is available. The shell continues to use the matugen palette.

## Clipboard and usage

`Mod+V` opens native Quickshell clipboard history. Search, use ↑/↓ to preview,
Enter to copy, Ctrl+Delete to remove, and Escape to close. `cliphist` still stores
text and images; a terminal picker is retained for shell recovery.

Performance samples CPU/GPU, temperatures, memory, home-filesystem storage,
network traffic and uptime every two seconds while visible. Circular gauges
show current load; graphs retain the last 30 samples while the page is open.
Missing sensors remain unavailable, and sampling avoids waking suspended NVIDIA
GPUs. The `notchd-metrics` helper uses Python's standard library and an optional,
bounded `nvidia-smi` query for an already-active NVIDIA GPU.
Limits reads an optional local usage feed; see [USAGE.md](USAGE.md). No provider
API adapter is included, so unavailable limits stay explicitly unavailable.

## Wallpaper picker

Open **Wallpapers** from Dashboard, or run:

```sh
quickshell ipc -c notchD call notchD openWallpapers
```

The bottom sheet combines a large selected preview, filename and collection position,
All/Favorites filters, search and a horizontal thumbnail filmstrip. It browses
`~/Pictures/walls`; override with `NOTCHD_WALLS_DIR`. Use ←/→ to select, Enter
to apply, and Escape to close. Apply invokes the existing `wp` command, preserving awww
transitions and matugen. Favorites use the same file as `wp fav`.

The expanded control center takes visual inspiration from [pocket-dots](https://github.com/diegoMalagrida/pocket-dots) by diegoMalagrida; its implementation uses notchD services.

## Wallpaper transitions and motion

Wallpaper changes now use Pocket's contagion shader over awww. The shell
loads the old/new images and cached arrival maps before it covers the desktop,
switches awww underneath, and releases the overlay at completion. `wp` serializes
requests; both overlay and fallback writers share a lock and bounded timeouts.
A missing shell or unreadable map uses an awww fade. Character-outline/model
support is not included.

`home/wallpaper-fx.nix` installs the NumPy/Pillow map helper. The compiled
shader includes desktop OpenGL, OpenGL ES, HLSL, MSL and SPIR-V variants; the
attributed source and rebuild command are in `shaders/pocket-wallfx/`.

The pill reserves separate artwork, time and playback-indicator spaces.
Workspace feedback is a small single-line capsule. The expanding surface stays
centered and reveals the final-size content without relaying out its columns.
The playback bars indicate playing/paused state; they are not an audio spectrum.

Handoff regression tests: `python3 tests/wallfx/test_handoff.py -v` from the repo root.

### Dashboard and launcher

The top tabs switch views without collapsing the island. Ctrl+Tab cycles the
main tabs; tab focus and arrow keys also navigate the tab bar. Dashboard
provides quick settings, media and notification overview, plus Limits and
Clipboard pages. Detail pages have a Back control and preserve the current
dashboard tab. Workspace feedback remains in the compact pill rather than a
separate tab.

Mod+Space opens the integrated launcher (falling back to fuzzel if IPC fails);
Mod+D retains fuzzel. Type `>` for actions. Panel transparency is persisted
under `~/.local/state/notchD/settings.json`, with opacity clamped to 0.70–1.
The IPC methods `openRunner`, `toggleRunner` and `closeRunner` are available.
`openCalendar` and `openTray` open the calendar and background-apps pages.
The shared moving tab indicator is inspired by Caelestia Shell's dashboard.

The command palette takes keyboard focus immediately rather than waiting for
an opening morph. `> scheme` chooses wallpaper-derived or custom hex colors;
`> variant` chooses a Material variant or Automatic; `> transparency` sets
0.70–1.00 panel opacity; `> light`, `> dark` and `> auto` change appearance.
Lock and Sleep actions are available, and `> wallpaper` opens the picker.
Wi-Fi/Bluetooth details replace the dashboard and Back returns to its prior tab.

### Clock, calendar and tray

A single compact header combines Dashboard/Media/Performance navigation, local
time and date, activity indicators, background apps and Settings. Click the
clock for the month calendar; Appearance offers 12/24-hour time. The calendar
uses only the weeks needed by the selected month and the island fits its height.
Arrows move days, PageUp/PageDown change months, Home/Today returns to today,
and Escape goes back. The grid follows the locale's first weekday. It does not
sync events or calendars yet.

The background-apps button opens StatusNotifier tray entries, including passive
entries. Left-click or Enter activates an app, right-click or Menu/Shift+F10
opens its menu, middle-click invokes its secondary action, and scrolling is
forwarded to the app. Menu-only apps open their menu on activation. Attention
states get a quiet accent dot. Apps must publish a tray icon; this is not a list
of all running processes. Legacy XEmbed icons are not hosted.

Menus use matugen surfaces and the shell's typography, with separators,
check/radio states, disabled actions, recursive submenus and keyboard navigation.
`> calendar` and `> background apps` open these pages through the runner.
`openCalendar` and `openTray` are also available through IPC. Calendar and
tray integration checks are in [tests/tray-calendar](../../../tests/tray-calendar/README.md).


### Media and system details

The dashboard keeps transport controls below the track title and artist.
The played segment of the seekbar waves during playback and settles when
paused. Drag to preview and release to seek; focused seekbars accept Left/Right
in five-second steps and Home/End. Unsupported seeking stays disabled, and
unknown duration is displayed as `—:—`.

Media opens a wider artwork-and-details view with album metadata and MPRIS
source selection. Selecting a source changes which player the controls target;
if it disappears, the shell follows another available player. The pill retains
its compact playback indicator; the expanded player has no decorative bars.

Performance and power details show battery percentage and power profile with
labeled icons. Shared controls use rounded Material Symbols vectors with
consistent centering, focus, hover, pressed and disabled states.
Polish checks are documented in [tests/notchd-polish](../../../tests/notchd-polish/README.md).

### Appearance and activity

Settings offers light/dark/automatic matugen mode, 12/24-hour time, 100–120% text
size, reduced motion, pill/notch shape and panel opacity. Clock, text, motion,
shape and opacity preferences survive restarts in the same `settings.json`.

Privacy indicators identify active PipeWire microphone/camera links and niri
screen casts. The Activity page explains the source and shows app names when
available. Direct V4L2 camera access outside PipeWire cannot be detected.
Keep-awake uses a Wayland idle inhibitor for 15, 30 or 60 minutes, displays the
remaining time, and stops on expiry, explicit cancellation, hiding or locking.

### Screenshot and annotation

`Mod+Shift+S` collapses the island and starts an area selection. Escape cancels;
a completed selection opens Swappy with crop, pen, arrow, shape, text and blur
tools. Use **Copy** / `Ctrl+C` for the clipboard or **Save** / `Ctrl+S` to keep a
PNG in `~/Pictures/Screenshots`. Nothing is copied or saved automatically.
`Print` keeps niri's existing screenshot behavior. The helper rejects locked
sessions and cleans its private capture file when the editor exits.
