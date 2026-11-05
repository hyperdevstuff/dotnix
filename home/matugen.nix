{ pkgs, lib, ... }:

{
  # Wallpaper-first theming: awww renders, matugen derives the palette,
  # per-app `include` directives pick up the generated files.
  home.packages = [
    pkgs.awww
    pkgs.matugen
  ];

  # Whole directory: config.toml references ./templates relative to itself.
  xdg.configFile."matugen" = {
    source = ../dotfiles/matugen;
    recursive = true;
  };

  home.file.".local/bin/wp".source = ../dotfiles/bin/wp;
  home.file.".local/bin/wp".executable = true;
  home.file.".local/bin/wp-boot".source = ../dotfiles/bin/wp-boot;
  home.file.".local/bin/wp-boot".executable = true;

  # First rebuild only: generate the initial colors from a random wallpaper
  # so the app `include`s resolve before the user runs `wp`.
  home.activation.matugenSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.config/matugen/generated/mako-colors" ]; then
      mkdir -p "$HOME/.config/matugen/generated"
      wall="$(find "$HOME/Pictures/walls" -type f | shuf -n 1)"
      if [ -n "$wall" ]; then
        ${pkgs.matugen}/bin/matugen image "$wall" --type scheme-content || true
      fi
    fi
  '';
}
