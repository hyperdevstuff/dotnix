# dotnix

NixOS + Home Manager configuration for `hyper`, built around:

- **NixOS unstable** (`nixos-unstable`) and **Home Manager master**
- **Niri** scrollable-tiling Wayland compositor
- **Fuzzel** application launcher
- **Quickshell** `notchD` — Dynamic-Island-style pill and hub (media, audio, network, session)
- **greetd + tuigreet** text login
- **NVIDIA open kernel modules** for the RTX 4050 Max-Q
- **PipeWire + WirePlumber**, **native Quickshell notifications**, **awww**, **native Quickshell lock**
- **MPD + rmpc** for the music library, **Yazi** for files

## Layout

```text
.
├── flake.nix
├── hosts/LOQ/
│   ├── default.nix                    # host settings, boot, user
│   ├── storage.nix                    # btrfs mount options + scrub
│   └── hardware-configuration.nix     # copied from /etc/nixos
├── modules/nixos/
│   ├── base.nix                       # nix settings, shell, fonts, basics
│   ├── nvidia.nix                     # NVIDIA driver + Niri VRAM profile
│   ├── desktop.nix                    # Niri, greetd, audio, portals
│   └── packages.nix                   # system tools
├── home/
│   ├── default.nix                    # Home Manager entry point
│   ├── shell.nix                      # fish (vi mode), hydro, fzf, zoxide, git
│   ├── foot.nix                       # terminal
│   ├── kitty.nix                      # terminal + single-instance server
│   ├── niri.nix                       # installs config.kdl
│   ├── quickshell.nix                 # bar, notifications, systemd service
│   ├── dev.nix                        # Rust, Node/Bun, QML tooling
│   ├── dolphin.nix                    # Dolphin palette, rc files, view seed
│   ├── fuzzel.nix                     # app launcher
│   ├── clipboard.nix                  # cliphist watchers + fzf picker
│   ├── music.nix                      # MPD + mpc + rmpc + MPRIS bridge
│   ├── yazi.nix                       # Yazi config and plugins
│   └── opencode.nix                   # phase 2, not imported yet
└── dotfiles/
    ├── bin/                           # clipmenu, music-shuffle, helpers
    ├── music/ignore                   # score/soundtrack exclusions
    ├── rmpc/config.ron
    ├── niri/config.kdl
    ├── kde/                           # Dolphin rc, kdeglobals, Dotnix palette
    └── quickshell/
        ├── shell.qml                  # fallback bar
        └── notchD/                    # Dynamic Island pill
```

## Build and activate

The configuration is not activated automatically. Review it first.

```bash
# Evaluate only (does not build or switch)
nix eval --raw ~/dotnix#nixosConfigurations.LOQ.config.system.build.toplevel.drvPath

# Build the system closure without activating it
sudo nixos-rebuild build --flake ~/dotnix#LOQ

# Install as the next boot generation, then reboot
sudo nixos-rebuild boot --flake ~/dotnix#LOQ
```

Use `switch` instead of `boot` only once the graphical session is known to work.

### Rollback

At the systemd-boot menu, pick the previous NixOS generation. From a running
system you can also use:

```bash
sudo nixos-rebuild switch --rollback
```

## Key bindings

`Mod` is **Super**.

| Binding | Action |
| --- | --- |
| `Mod+Return` / `Mod+T` | terminal (foot) |
| `Mod+Q` | terminal (kitty) |
| `Mod+B` | browser (Helium) |
| `Mod+E` | file manager (Dolphin) |
| `Mod+Shift+E` | file manager (Yazi, in kitty) |
| `Mod+V` | clipboard history (cliphist + fzf in a floating kitty) |
| `Mod+Alt+V` | toggle floating |
| `Mod+Shift+V` | focus floating/tiling |
| `Mod+D` / `Mod+Space` | app launcher (fuzzel) |
| `Mod+C` | close window |
| `Mod+Shift+C` | center column |
| `Mod+Shift+Space` / `Mod+Shift+N` | show/hide the NotchD pill |
| `Mod+N` | open/close the NotchD hub |
| `Mod+Shift+B` | set brightness to 60% |
| `Mod+Shift+A` | audio controls (notchD) |
| `Mod+Alt+A` | advanced audio (pavucontrol) |
| `Mod+Alt+N` | Wi-Fi / Ethernet controls (notchD) |
| `Mod+Alt+Shift+N` | advanced networks (nm-connection-editor) |
| `Mod+Alt+S` | session and power (notchD) |
| `Mod+Alt+M` | now playing (notchD) |
| `Mod+Shift+Q` | quit Niri |
| `Mod+Shift+Slash` | hotkey overlay |
| `Mod+O` | overview |
| `Mod+Left/Right/Up/Down`, `Mod+H/J/K/L` | focus |
| `Mod+Ctrl+H/J/K/L` | move window |
| `Mod+1..9` | workspace |
| `Mod+Ctrl+1..9` | move column to workspace |
| `Mod+R` | cycle preset column width |
| `Mod+F` | maximize column |
| `Mod+Shift+F` | fullscreen |
| `Mod+Ctrl+Shift+F` | windowed fullscreen (fake) |
| `Mod+W` | tabbed column |
| `Mod+Shift+M` | center window |
| `Mod+G` | focus previous window |
| `Mod+Ctrl+Comma` / `Mod+Ctrl+Period` | swap window left/right |
| `Mod+Ctrl+BracketLeft` / `Mod+Ctrl+BracketRight` | wrapping column focus |
| `Mod+Shift+D` / `Mod+Ctrl+D` | dynamic cast window / monitor |
| `Mod+Ctrl+Shift+D` | clear dynamic cast target |
| `Mod+Shift+Print` | screenshot window to clipboard |
| `Print` | screenshot |
| `Super+Alt+L` | lock (native Quickshell lock) |
| `CapsLock` / `Escape` | swapped (`caps:swapescape`) |

`Mod` is **Super**.

An interactive niri keybind/capability reference lives at `docs/niri.html` — open it in any browser (`xdg-open docs/niri.html`).

## Display, audio, network

- **Brightness:** the laptop keys change it in 10% steps. To jump to 60%,
  press `Mod+Shift+B`, or run:

  ```bash
  brightnessctl set 60%
  brightnessctl get          # current value in raw units
  brightnessctl --help       # more info
  ```

- **Volume:** the media keys use `wpctl`. Manual control:

  ```bash
  wpctl status
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+     # raise 10%
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5      # set 50%
  wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle
  pavucontrol                                    # GUI (Mod+Alt+A)
  ```

- **Wi-Fi / Ethernet:** NetworkManager is enabled. Use the tray applet or:

  ```bash
  nmtui                       # terminal UI
  nm-connection-editor        # GUI (Mod+Shift+N)
  nmcli device status
  nmcli device wifi list
  nmcli device wifi connect "SSID" password "PASSWORD"
  nmcli connection show
  ```

## Storage

The system disk is an NVMe SSD with btrfs. `hosts/LOQ/storage.nix` adds
`ssd,discard=async,noatime,compress=zstd:3` to `/`, `/home` and `/nix`, and
enables a monthly scrub.

The current layout is **working but not the recommended one**: the root is the
top-level btrfs subvolume (not `@`), and `/var` is not isolated. Root snapshots
and rollback are therefore not set up. Moving to `subvol=@` is an offline
migration from a live USB, not a config-only change — the full procedure,
verification and rollback steps are in **[`docs/storage.md`](docs/storage.md)**.

Quick checks:

```bash
findmnt -no SOURCE,FSTYPE,OPTIONS /
sudo btrfs filesystem usage /
sudo btrfs device stats /
sudo btrfs scrub status /
```

## Development

`home/dev.nix` installs the toolchains:

| Tool | Version source |
| --- | --- |
| Rust (`rustc`, `cargo`, `rustfmt`, `clippy`, `rust-analyzer`) | matching nixpkgs 1.99.0 |
| Node.js (`node`, `npm`, `npx`, `corepack`) | nixpkgs `nodejs` |
| Bun | nixpkgs `bun` |
| QML (`qml`, `qmllint`, `qmlls`, `qmlformat`, `qmlscene`) | `qt6.qtdeclarative` |

The store is read-only, so global JS packages are redirected into the home
directory: `npm i -g` writes to `~/.local` (`~/.local/bin` is on `PATH`) and
`bun add -g` writes to `~/.bun/bin`. Native addons use the `python3`/`gnumake`
from the same file; `gcc`, `cmake` and `pkg-config` are already available.

QML tooling resolves Quickshell's modules through `QML_IMPORT_PATH`, so this
works from any directory (`-E` tells the tools to read that variable):

```bash
qmllint -E ~/dotnix/dotfiles/quickshell/notchD/shell.qml
qmlls -E      # editor integration
```

Leave `RUST_SRC_PATH` unset — the nixpkgs `rust-analyzer` wrapper already
points at the stdlib sources.

## File manager

Dolphin is set up as a dense, File Pilot-style browser rather than the stock
KDE default:

- The KDE platform theme and Breeze widget style are baked into Dolphin's
  wrapper in `modules/nixos/desktop.nix`. NixOS does not run Plasma here, so
  without that the app would fall back to Fusion and ignore `kdeglobals`.
- `dotfiles/kde/kdeglobals` picks the neutral `Dotnix` palette
  (`dotfiles/kde/Dotnix.colors`), Inter 10 and Papirus-Dark icons.
- `dotfiles/kde/dolphinrc` turns on the details view with 16 px icons, 32 px
  previews, tighter side padding, always-visible tabs, the small status bar and
  no menu bar or expandable-folder tree.
- The details view is a global view property, which Dolphin stores as a
  `user.kde.fm.viewproperties#1` xattr. `home/dolphin.nix` seeds it once, and
  only when it is missing, so a later `Ctrl+1/2/3` choice sticks.

Handy keys: `Ctrl+L` edits the path, `Ctrl+I` filters the current folder,
`F11` toggles the information panel, `F3` toggles split view.

Both rc files are read-only store links, so a rebuild restores them and drops
runtime tweaks such as the last window size.

In Yazi the outer rounded frame came from the `full-border` plugin and has been
removed; the pane separators are still drawn.

## Music library

> **Disabled on this install:** the NTFS data disk is not attached, so the
> `/mnt/library` mount, `home/music.nix`, and the `music`/`shuffle`/`lib`
> aliases are commented out. Re-enable them (and fix the UUID if it changed)
> once the disk is connected.

The NTFS data disk is mounted by UUID at **`/mnt/library`** (systemd
automount, released after 15 idle minutes), so scripts do not depend on the
`New Volume` label or its spaces:

```bash
ls /mnt/library
cd /mnt/library            # `lib` alias
mpc update                 # force a full rescan (MPD also auto-updates)
shuffle                    # or press S in rmpc
music                      # rmpc TUI
```

`music-shuffle` clears the MPD queue and re-adds the whole library with a
filter expression, excluding film/TV scores and soundtracks listed in
`~/.config/music/ignore` (installed from `dotfiles/music/ignore`). It then
turns random mode on and plays. MPD, `mpc` and `rmpc` are already about as
light as a music player gets: MPD is a small daemon, `mpc` is a CLI, and rmpc
is a TUI capped at 30 fps. No Electron player or browser tab is involved.

Renaming the NTFS label is optional now (the mount uses the UUID). If you
still want to:

```bash
# unmount first; the drive is not mounted while idle most of the time
sudo ntfslabel /dev/sda2 library
```

## Clipboard

`Mod+V` opens `cliphist` history in a floating kitty window running `fzf`.
Unlike fuzzel's one-line dmenu mode, fzf wraps long clips and shows a preview:
text is rendered by `bat`, images by `chafa`, and binary clips get a short
placeholder. `Ctrl+D` in the picker deletes the highlighted entry.
`wl-clip-persist` keeps the current clipboard alive after the owning app exits.

## Quickshell themes

`notchD` ships with three themes: **gruvbox** (Gruvbox Dark), **eink**
(paper-like light), and **vercel** (Black, the default). It is now a small
Dynamic-Island hub (media, audio, network, session, lock) rather than only a
clock; hide it completely with `Mod+Shift+N`. See
`dotfiles/quickshell/notchD/README.md` for IPC commands and theme switching.

## Troubleshooting

```bash
# Niri
niri msg outputs
niri msg workspaces
journalctl --user -u niri -b

# Quickshell / NotchD
quickshell --version
quickshell ipc -c notchD call notchD toggle
quickshell ipc -c notchD call notchD reload
journalctl --user -u quickshell -b

# Login manager
journalctl -u greetd -b

# Build-time checks (no activation)
nix eval --raw ~/dotnix#nixosConfigurations.LOQ.config.system.build.toplevel.drvPath
nixos-rebuild build --flake ~/dotnix#LOQ
```


## Notes

- **Git:** this directory is a Git repository. Flakes only see files tracked by
  Git, so `git add` any new or renamed file before rebuilding. Set your identity
  and make the first commit:

  ```bash
  git config user.name "Your Name"
  git config user.email "you@example.com"
  git commit -m "initial dotnix configuration"
  ```

- **Hostname:** `LOQ` (set in `hosts/LOQ/default.nix`), so future machines can
  be told apart. Change it there if you prefer a lowercase or different name.

- **Shell:** `ls`, `ll`, `la`, `lla`, `lt`, `lS`, `lm`, `lG` are eza aliases with
  icons, Git status, and headers. zoxide is initialised with `--cmd cd`, so plain
  `cd` uses the frecency database and `cdi` opens the interactive picker. The
  prompt is **hydro** (fish-native, async Git). Fish uses vi key bindings:
  `Ctrl+E` opens Yazi and returns to the directory it exited in, `Ctrl+Y`
  accepts an autosuggestion, and `Escape` enters normal mode. See
  `docs/fish-aliases.md` for the full alias and keybinding reference.

- **Neovim:** LazyVim config imported into `dotfiles/nvim` (2026-11-05), symlinked
  to `~/.config/nvim`. Lazy.nvim clones its plugins on first launch (needs network).

- **Terminals:** foot is the primary (Catppuccin Mocha), kitty has beam cursor,
  cursor trail, 8px margins and vim-scroll binds, ghostty is installed as fallback.

- **Keyboard:** CapsLock and Escape are swapped for Niri via the
  `caps:swapescape` XKB option.

- **NVIDIA:** `hardware.nvidia.open = true` selects NVIDIA's *open kernel
  modules* (not nouveau). The RTX 4050 is Ada Lovelace and is supported by
  them; they are the recommended choice for recent cards on Wayland. Set it to
  `false` to use the proprietary kernel modules instead. Modesetting is on, and
  the Niri-recommended VRAM application profile is installed under
  `/etc/nvidia/nvidia-application-profiles-rc.d/`.
- **Suspend:** `hardware.nvidia.powerManagement.enable` is off initially.
  Turn it on deliberately if suspend/resume behaves incorrectly.
- **Home Manager backups:** existing dotfiles are renamed with a `.backup`
  suffix (`home-manager.backupFileExtension`).
- **OpenCode:** intentionally **not** installed yet. The npm installation in
  `~/.opencode/bin` still shadows Nix; `home/shell.nix` keeps that directory on
  `PATH` temporarily so the current binary keeps working. Once the desktop is
  stable, import `home/opencode.nix`, remove the temporary `fish_add_path`
  block, and remove the npm install. `pkgs.opencode` on unstable is v2.
- **OpenCode mouse scrolling:** `~/.config/opencode/cli.json` enables terminal
  mouse capture, sets scroll speed, and enables the transcript scrollbar. This
  file is intentionally not Home-Manager-managed so the TUI can edit it.
- **Secrets:** never commit passwords or keys. This repository is copied to the
  world-readable Nix store.
- `/etc/nixos` is intentionally left untouched as a fallback until this
  configuration has booted successfully.
