# dotnix

NixOS + Home Manager configuration for `hyper`, built around:

- **NixOS unstable** (`nixos-unstable`) and **Home Manager master**
- **Niri** scrollable-tiling Wayland compositor
- **Fuzzel** application launcher
- **Quickshell** `notchD` — a minimal Dynamic-Island-style pill with the current time only
- **greetd + tuigreet** text login
- **NVIDIA open kernel modules** for the RTX 4050 Max-Q
- **PipeWire + WirePlumber**, **mako**, **swaybg**, **swaylock**

## Layout

```text
.
├── flake.nix
├── hosts/nixos/
│   ├── default.nix                    # host settings, boot, user
│   └── hardware-configuration.nix     # copied from /etc/nixos
├── modules/nixos/
│   ├── base.nix                       # nix settings, shell, fonts, basics
│   ├── nvidia.nix                     # NVIDIA driver + Niri VRAM profile
│   ├── desktop.nix                    # Niri, greetd, audio, portals
│   └── packages.nix                   # system tools
├── home/
│   ├── default.nix                    # Home Manager entry point
│   ├── shell.nix                      # fish, starship, fzf, zoxide, git
│   ├── foot.nix                       # terminal
│   ├── niri.nix                       # installs config.kdl
│   ├── quickshell.nix                 # bar + systemd service
│   ├── fuzzel.nix
│   ├── mako.nix
│   └── opencode.nix                   # phase 2, not imported yet
└── dotfiles/
    ├── niri/config.kdl
    └── quickshell/
        ├── shell.qml                  # fallback bar
        └── notchD/                    # Dynamic Island pill
```

## Build and activate

The configuration is not activated automatically. Review it first.

```bash
# Evaluate only (does not build or switch)
nix eval --raw ~/dotnix#nixosConfigurations.nixos.config.system.build.toplevel.drvPath

# Build the system closure without activating it
sudo nixos-rebuild build --flake ~/dotnix#nixos

# Install as the next boot generation, then reboot
sudo nixos-rebuild boot --flake ~/dotnix#nixos
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
| `Mod+D` / `Mod+Space` | app launcher (fuzzel) |
| `Mod+C` | close window |
| `Mod+Shift+C` | center column |
| `Mod+Shift+Space` / `Mod+Shift+N` | toggle the NotchD pill |
| `Mod+N` | show the NotchD pill |
| `Mod+Shift+B` | set brightness to 60% |
| `Mod+Shift+A` | audio settings (pavucontrol) |
| `Mod+Alt+N` | Wi-Fi / Ethernet settings |
| `Mod+Shift+E` | quit Niri |
| `Mod+Shift+Slash` | hotkey overlay |
| `Mod+O` | overview |
| `Mod+Left/Right/Up/Down`, `Mod+H/J/K/L` | focus |
| `Mod+Ctrl+H/J/K/L` | move window |
| `Mod+1..9` | workspace |
| `Mod+Ctrl+1..9` | move column to workspace |
| `Mod+R` | cycle preset column width |
| `Mod+F` | maximize column |
| `Mod+Shift+F` | fullscreen |
| `Mod+V` | toggle floating |
| `Mod+W` | tabbed column |
| `Print` | screenshot |
| `Super+Alt+L` | lock (swaylock) |
| `CapsLock` / `Escape` | swapped (`caps:swapescape`) |

`Mod` is **Super**.

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
  pavucontrol                                    # GUI (Mod+Shift+A)
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

## Quickshell themes

`notchD` ships with three themes: **gruvbox** (Gruvbox Dark), **eink**
(paper-like light), and **vercel** (Black, the default). The pill is a
minimal clock and can be hidden completely; nothing remains on screen while
hidden. See `dotfiles/quickshell/notchD/README.md` for IPC commands and
theme switching.

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
nix eval --raw ~/dotnix#nixosConfigurations.nixos.config.system.build.toplevel.drvPath
nixos-rebuild build --flake ~/dotnix#nixos
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

- **Hostname:** `LOQ` (set in `hosts/nixos/default.nix`), so future machines can
  be told apart. Change it there if you prefer a lowercase or different name.

- **Shell:** `ls`, `ll`, `la`, `lla`, and `lt` are eza aliases with icons,
  Git status, and headers. zoxide is initialised with `--cmd cd`, so plain
  `cd` uses the frecency database and `cdi` opens the interactive picker.

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
