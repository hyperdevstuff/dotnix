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
gaming setup, and Home Manager apps.

`LOQ` loads the dotnix niri config from `~/.config/niri/dotnix.kdl` and
starts notchD, cliphist, swayidle, and awww. `LOQ-dux` starts the pinned
Nixpkgs Dux Shell as a user service and lets DMS edit
`~/.config/niri/config.kdl` and its `dms/` fragments. Home Manager seeds
the stock DMS config once. Migration backs up the previous config and
shell fragment under `~/.local/state/dotnix/niri-backups/` and carries
over the output settings and any existing DMS fragments with content.

Use `Mod+Space` for the launcher, `Mod+V` for clipboard history, and
`Mod+Shift+Slash` for the DMS shortcut editor. DMS settings can apply
changes to layout, input, displays, window rules, and overview effects.
Use the DMS settings UI for these changes. NixOS starts the shell through
`dms.service`.

Both profiles retain dotnix's Matugen templates for apps such as Kitty,
foot, and Dolphin. The Dux profile also reads DMS's generated niri colors
when enabled in DMS settings. DMS preferences are writable from its UI.
The first launch defaults to locking before suspend, and existing DMS
preferences take precedence. Select `~/Pictures/walls` from the DMS
wallpaper picker to use the existing wallpaper library.

## 3. Boot and return

Review the dry build before updating the boot menu. Register LOQ first
to have a fallback that uses `dotnix.kdl`, then register LOQ-dux as the
boot default.

```bash
nixos-rebuild dry-build --flake ~/dotnix#LOQ-dux
sudo nixos-rebuild boot --flake ~/dotnix#LOQ
sudo nixos-rebuild boot --flake ~/dotnix#LOQ-dux
```

Reboot into the `LOQ-dux` generation. Choose the updated LOQ entry in
systemd-boot to return to notchD. Updated generations share a home
directory and keep both niri configs. Before booting a generation from
before this change, move the writable `~/.config/niri/config.kdl` to a
backup name so that generation's Home Manager can install its link there.

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
