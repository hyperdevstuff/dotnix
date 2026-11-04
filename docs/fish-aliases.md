# Fish aliases on dotnix

Defined in `home/shell.nix`. This file is the readable reference; `home/shell.nix`
is the source of truth.

## Imported from the old dotfiles (NixOS-adapted)

### Basics
| Alias | Expands to | Notes |
| --- | --- | --- |
| `n` | `nvim` | |
| `mk` | `mkdir` | |
| `..` | `cd ..` | |
| `...` | `cd ../..` | |
| `rel` | `source ~/.config/fish/config.fish` | reload fish after editing |

### Typo fixes
| Alias | Expands to |
| --- | --- |
| `gti` / `gut` | `git` |
| `claer` | `clear` |

### Safe operations
| Alias | Expands to |
| --- | --- |
| `rm` | `rm -Ii` |
| `cp` | `cp -i` |
| `mv` | `mv -i` |

### Modern CLI replacements
| Alias | Expands to | Notes |
| --- | --- | --- |
| `cat` | `bat --style=auto` | keep `bat` for reading files |
| `grep` | `rg` | ripgrep via `programs.ripgrep` |
| `top` | `btop` | |

### New eza listings (on top of the existing `ls`/`ll`/`la`/`lla`/`lt`)
| Alias | Expands to |
| --- | --- |
| `lS` | `eza --long --icons --sort=size --reverse` | biggest first |
| `lm` | `eza --long --icons --sort=modified --reverse` | newest first |
| `lG` | `eza --long --icons --git` | git status column |
| `tree` | `eza --tree --level=3 --icons --color=auto --group-directories-first` | |

### Git
| Alias | Expands to |
| --- | --- |
| `g` | `git` |
| `gs` | `git status` |
| `gst` | `git status --short` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gcm` | `git commit -m` |
| `gcam` | `git commit -am` |

> Note: `gc` stays `sudo nix-collect-garbage -d` (existing NixOS alias).
> `git commit` is `gcm` / `gcam`.
| `gp` | `git push` |
| `gpl` | `git pull` |
| `gd` | `git diff` |
| `gco` | `git checkout` |
| `gb` | `git branch` |
| `glog` | `git log --oneline --graph --all` |
| `lg` | `lazygit` | `pkgs.lazygit` is installed |

### fzf power tools
| Alias | Expands to |
| --- | --- |
| `ff` | `fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'` |
| `nf` | `fzf -m --preview='bat --color=always {}' --bind 'enter:become(nvim {+})'` |
| `fcd` | `cd (fd -t d | fzf)` |

### System info
| Alias | Expands to |
| --- | --- |
| `ports` | `ss -tulpn` |
| `wtf3000` | `fuser -v 3000/tcp` | what is using port 3000 |
| `psg` | `ps aux \| rg` | grep processes |
| `size` | `du -sh --block-size=MB` | |

## Deliberately dropped from the old config

| Old alias | Why |
| --- | --- |
| `yain` / `yaup` / `yarem` / `yasr` / `yaclean` / `yaorph` | pacman/yay — not on NixOS; use `rebuild`, `flake-update`, `gc` |
| `clip` / `paste` / `open` / `o` / `exp` | WSL (`win32yank`, `wsl-open`, `explorer.exe`) — not applicable |
| `alias c clear`, `alias x/q exit` | too aggressive for little gain |
| `diff → difftastic` | difftastic is not installed; re-add via Nix if wanted |
| `cp -i` shadowed twice, `mv` duplicates | unified under "Safe operations" |
| docker group | no docker on this machine |
| bun group | bun is not installed system-wide |
| `nd` (`nvim -c Oil`) | oil.nvim may not be in the LazyVim plugins yet; check `:Lazy` |
| oh-my-posh (dropped earlier) / starship | replaced by **hydro** (fish-native, async git, no process spawn); starship config removed from `home/shell.nix` |

## NixOS-specific (already present, unchanged)
| Alias | Expands to |
| --- | --- |
| `rebuild` | `sudo nixos-rebuild switch --flake ~/dotnix#LOQ` |
| `rebuild-boot` | `sudo nixos-rebuild boot --flake ~/dotnix#LOQ` |
| `flake-update` | `nix flake update --flake ~/dotnix` |
| `gc` | `sudo nix-collect-garbage -d` |
