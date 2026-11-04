{ ... }:

{
  # LazyVim config, imported from the old dotfiles on 2026-11-05.
  # Lazy.nvim clones its plugins on first launch, so the first `nvim`
  # run needs network access.
  xdg.configFile."nvim" = {
    source = ../dotfiles/nvim;
    recursive = true;
  };
}
