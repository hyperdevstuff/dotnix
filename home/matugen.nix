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
  home.file.".local/bin/wp-pick".source = ../dotfiles/bin/wp-pick;
  home.file.".local/bin/wp-pick".executable = true;

  # niri has no variables: matugen writes an include file that config.kdl
  # pulls in. A missing include is a fatal config error, so seed a neutral
  # palette before niri starts. `wp` overwrites it with the real one.
  home.activation.niriColorsSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    niri_dir="$HOME/.config/niri/generated"
    if [ ! -f "$niri_dir/colors.kdl" ]; then
      run mkdir -p "$niri_dir"
      cat > "$niri_dir/colors.kdl" <<'EOF'
// Seed palette. `wp` replaces this with wallpaper colors.
layout {
    background-color "#101010"

    border {
        active-color "#a0a0a0"
        inactive-color "#3a3a3a"
        urgent-color "#ff6b6b"
    }

    tab-indicator {
        active-color "#a0a0a0"
        inactive-color "#3a3a3a"
        urgent-color "#ff6b6b"
    }
}
EOF
    fi
  '';

  # First rebuild only: generate the initial colors from a random wallpaper
  # so the app `include`s resolve before the user runs `wp`.
  # Scheme follows the wallpaper's brightness: light walls get light chrome.
  home.activation.matugenSeed = lib.hm.dag.entryAfter [ "niriColorsSeed" ] ''
    if [ ! -f "$HOME/.config/matugen/generated/mako-colors" ]; then
      run mkdir -p "$HOME/.config/matugen/generated"
      wall="$(find "$HOME/Pictures/walls" -type f | shuf -n 1)"
      if [ -n "$wall" ]; then
        run ${pkgs.matugen}/bin/matugen image "$wall" --type scheme-tonal-spot --mode smart || true
      fi
    fi
  '';
}
