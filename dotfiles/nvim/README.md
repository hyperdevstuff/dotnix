# nvim

LazyVim-based config, managed by Home Manager from `dotfiles/nvim`.

## Layout

- `init.lua` — loads `config.lazy`.
- `lua/config/` — options, keymaps, autocmds, lazy bootstrap.
- `lua/plugins/` — plugin overrides (blink.cmp, snacks, oil, markview, neogit, …).
- `lazyvim.json` — enabled LazyVim extras.

## Notes

- Plugin data lives in `~/.local/share/nvim` (lazy.nvim, mason tools).
- The lockfile is `~/.local/share/nvim/lazy-lock.json` because `~/.config/nvim`
  is a read-only symlink into the nix store.
- `lazyvim.json` intentionally has no AI extras; plugins are kept lean.
- LazyVim loads the kanagawa-dragon colorscheme.

## Useful

- `<leader>lu` — Lazy update
- `<leader>lx` — LazyExtras
- `<leader><space>` — smart find files
- `-` — oil file explorer
