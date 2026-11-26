# Trying Dux Modular Shell (DMS) without giving up dotnix

DMS is not a distro or a compositor. It is a complete Wayland desktop shell
(Quickshell + a Go backend called `dms`) that expects to own the same layer of
the desktop that dotnix currently hand-builds: bar, launcher, notifications,
lock screen, clipboard, control center, OSDs, wallpaper/theming, and the
polkit agent. niri keeps running exactly as it does now.

Upstream: <https://github.com/duxlabs-dev/dux-shell> · docs:
<https://duxlabs.dev/docs/dms/nixos-flake>

There are two useful ways to try it. Do the nested trial first; it costs
nothing and shows whether the shell is worth a few days of real use.

## 1. Nested trial (zero risk, no rebuild)

```bash
./scripts/try-dux          # or: try-dux once home-manager has installed it
```

What it does:

- fetches `nixpkgs#dux-shell` (2.1.x, already on `cache.nixos.org`) and
  `nixpkgs#quickshell`;
- starts a nested niri in a window with its own D-Bus session;
- runs `dms run` inside it.

Because the nested session has a private D-Bus bus, DMS cannot take over
`org.freedesktop.Notifications`, the polkit agent, or the clipboard from
notchD. The real desktop keeps running underneath. Mod is Alt inside the
window; `Alt+Shift+E` quits.

This is enough to explore the bar/island layouts, dashboard, settings, and
`dms ipc` commands, but it does not tell you how DMS feels as a daily driver
(lock screen, idle, theming, startup ordering).

`DUX_SOURCE=flake ./scripts/try-dux` uses the upstream flake instead of the
nixpkgs package. That version builds from source the first time.

## 2. Daily-driver trial on LOQ-dux

`LOQ` and `LOQ-dux` are two configurations for the same laptop. They share
the LOQ hostname, hardware, storage, NVIDIA, greetd, portals, PipeWire,
gaming setup, and Home Manager apps. They also share niri's display settings,
layout, window rules, and window-management shortcuts.

`LOQ` starts notchD, cliphist, swayidle, and awww. `LOQ-dux` uses the pinned
Nixpkgs Dux Shell package and starts DMS with the niri session. DMS owns the
bar, launcher, notifications, clipboard history, wallpaper, idle handling,
screen lock, and polkit prompt. Its own niri fragment wires the shell keys
to DMS. `Mod+D` or `Mod+Space` opens the launcher, `Mod+N` opens
notifications, and `Mod+V` opens clipboard history.

Both profiles retain dotnix's Matugen templates for apps such as Kitty,
foot, and Dolphin. The Dux profile also reads DMS's generated niri colors
when enabled in DMS settings. DMS preferences are writable from its UI.
The first launch defaults to locking before suspend, and existing DMS
preferences take precedence. Select `~/Pictures/walls` from the DMS
wallpaper picker to use the existing wallpaper library.

## 3. Boot and return

When ready to try the desktop, review the dry build before preparing a
boot generation.

```bash
nixos-rebuild dry-build --flake ~/dotnix#LOQ-dux
sudo nixos-rebuild boot --flake ~/dotnix#LOQ-dux
```

Reboot into the `LOQ-dux` generation. To return, select the earlier LOQ
generation from systemd-boot or prepare a new LOQ generation with
`sudo nixos-rebuild boot --flake ~/dotnix#LOQ` and reboot. Both profiles
use the same home directory, so application data and DMS preferences
remain available across boots.

## 4. What is worth learning from DMS

DMS is a good reference for ideas that can be adopted without adopting the
whole shell:

- **IPC surface**: one Go binary exposing a stable `dms ipc call <target>
  <fn>` API for every widget. dotnix currently drives notchD with ad-hoc
  QML IPC calls; a small versioned command table would make the niri binds
  more portable.
- **Settings as data**: DMS keeps `settings.json`, `session.json`,
  `clsettings.json`, and plugin settings as plain JSON, and its Nix modules
  generate them with `pkgs.formats.json`. The same pattern would let dotnix
  expose notchD options declaratively without hand-writing QML constants.
- **Diagnostics**: `dms doctor` checks compositor features, optional
  dependencies, PAM, portal, and cache state in one command. A `dotnix doctor`
  could assert that notchD, awww, matugen, and the PAM service are healthy.
- **Niri integration as files**: `dms setup` deploys small `include`-able KDL
  fragments (`binds`, `colors`, `layout`, `windowrules`) instead of owning the
  whole config. That is a cleaner pattern than generating `config.kdl`.
- **Theming pipeline**: matugen → per-app templates → compositor colors is the
  same idea as `wp`; DMS's template layout and `dank16` are worth copying.
- **Bar as a data-driven layout**: bars/docks/islands are configurable
  instances with selectors, not hard-coded QML. notchD could grow a small
  layout description without a rewrite.
