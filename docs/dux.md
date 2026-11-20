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

## 2. Daily-driver trial (a branch, not a replacement)

Do this on a branch so `main` stays the known-good dotnix:

```bash
git switch -c dux-trial
# edit, then:
sudo nixos-rebuild switch --flake ~/dotnix#LOQ
# to go back at any time:
git switch main
sudo nixos-rebuild switch --flake ~/dotnix#LOQ
```

DMS can be installed two ways:

| Path | Version | Build cost | Declarative settings/plugins |
| --- | --- | --- | --- |
| `programs.dux-shell.enable = true` (nixpkgs NixOS module) | 2.0/2.1 depending on the lock | prebuilt | no |
| `inputs.dux.homeModules.dank-material-shell` (upstream flake) | stable (2.1) | builds `dux-qt-base` once | yes |

For a first branch, the nixpkgs module is the cheaper experiment. Its option
set is `programs.dux-shell` (renamed from `programs.dms-shell`), and it adds
DMS plus `quickshell`, `matugen`, and `cava` system-wide.

With the upstream flake, the home-manager module is named
`homeModules.dank-material-shell` and enables the same thing per user; add
`systemd.target = "niri.service"` so it starts and dies with the session.

## 3. What has to be switched off

DMS is not additive: several dotnix services claim the same names or sockets.
On the trial branch, disable these while DMS is enabled:

| dotnix file | Provides | Why it conflicts with DMS |
| --- | --- | --- |
| `home/quickshell.nix` | notchD bar, notifications, lock, polkit agent | second Quickshell instance; DMS's unit owns `org.freedesktop.Notifications` (`BusName=` in `dms.service`) and has its own lock/polkit. Keep a Quickshell runtime installed (see below) |
| `home/fuzzel.nix` | launcher | DMS launcher replaces it (keep fuzzel only as a fallback) |
| `home/clipboard.nix` | cliphist watchers + `wl-clip-persist` | DMS has its own clipboard history; two histories diverge |
| `home/idle.nix` | swayidle: dim, lock via notchD, suspend | DMS manages idle/lock/suspend itself; two lockers race |
| `home/matugen.nix` | awww daemon, `wp` rotation, niri colors | DMS has built-in wallpaper + matugen theming and will fight over the wallpaper/socket |
| `dotfiles/niri/config.kdl` binds | notchD IPC | must call `dms ipc ...` instead; the notchD calls will fail |

Keep: `home/niri.nix`, the system-wide polkit daemon
(`security.polkit.enable`), PipeWire, greetd/tuigreet, NVIDIA, and the rest of
the system modules. DMS replaces the *shell*, not the OS.

### Keep a Quickshell runtime

The nixpkgs `dux-shell` package does not pull in `quickshell`: it is the
runtime that loads the embedded UI (the flake's 2.1 package may embed it
instead). Since `home/quickshell.nix` is what currently installs it, add one
line on the trial branch so removing that import does not remove the runtime:

```nix
home.packages = [ pkgs.quickshell ];
```

The nixpkgs NixOS module already adds `programs.dux-shell.quickshell.package`
for you. `dms doctor` reports the runtime version it found, which is the
quickest way to confirm this after a rebuild.

### niri config

Do **not** import `inputs.dux.homeModules.niri` with its default
`niri.includes` unless you are ready for it to take over
`~/.config/niri/config.kdl` (it moves the generated config to `hm.kdl`). This
repo writes that file by hand, so the low-risk route is to add include lines
and binds manually.

Generate the DMS snippets once:

```bash
dms setup binds colors cursor layout outputs windowrules
```

or deploy everything non-interactively with `dms setup headless`. They land in
`~/.config/niri/dms/`. Then add to `dotfiles/niri/config.kdl`:

```kdl
include "~/.config/niri/dms/binds" optional=true
include "~/.config/niri/dms/colors" optional=true
include "~/.config/niri/dms/windowrules" optional=true
```

Only include `binds` after reading it: it ships DMS's own keymap and will
collide with the hand-written binds at the bottom of `config.kdl`. During the
trial it is usually better to include `colors`/`windowrules` and rewrite only
the binds that currently call `quickshell ipc -c notchD ...`:

```kdl
Mod+D  { spawn "dms" "ipc" "call" "launcher" "toggle"; }
Super+Alt+L allow-when-locked=true { spawn "dms" "ipc" "call" "lock" "lock"; }
Mod+N  { spawn "dms" "ipc" "call" "notifications" "toggle"; }
Mod+Alt+S { spawn "dms" "ipc" "call" "powermenu" "toggle"; }
Mod+Alt+A { spawn "dms" "ipc" "call" "control-center" "toggle"; }
Mod+Alt+C { spawn "dms" "ipc" "call" "clipboard" "toggle"; }
```

Audio/brightness/media keys: point them at `dms ipc call audio|mic|brightness|
mpris ...` instead of the notchD OSD calls, otherwise the keys work but DMS
shows no OSD. `dms ipc list` prints every target while DMS is running.

### Lock screen PAM

DMS uses a sanitized, generated PAM service by default and does not need
`pam.services.quickshell`. `security.pam.services.quickshell` can stay
harmless, but nothing will use it while notchD is disabled. Fingerprint and
security-key unlock are opt-in in DMS settings; a dedicated
`security.pam.services.dankshell-u2f` is only needed for the U2F path.

### Wallpaper/theming

If `home/matugen.nix` is disabled, DMS owns the wallpaper and generates its own
colors under `~/.config/niri/dms/colors.kdl`. The existing
`~/.config/niri/generated/colors.kdl` include at the top of `config.kdl` will
keep its last value; leave it (niri needs the file to exist) or remove the
include on the trial branch. `dms ipc call wallpaper next` replaces `wp
random`; `dms ipc call theme toggle` replaces any light/dark switching.

## 4. Rollback

- At boot: pick the previous NixOS generation in systemd-boot.
- From a running system: `sudo nixos-rebuild switch --rollback`, or switch
  back to `main` and rebuild.
- Runtime-only: `systemctl --user stop dms` and start the old session units
  again, or simply log out.

## 5. What is worth learning from DMS

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

What is *not* worth importing blindly: the module will try to own
`~/.config/niri/config.kdl`, the notification bus, the lock screen, and the
wallpaper. dotnix's value is that those pieces are small and visible; importing
DMS wholesale would replace that with a large upstream surface and a
version-coupled flake input.
