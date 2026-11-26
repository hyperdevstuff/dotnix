{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = [ pkgs.matugen ];

  # Both shells can use these templates to keep app colors in sync.
  xdg.configFile."matugen" = {
    source = ../dotfiles/matugen;
    recursive = true;
  };

  # The desktop shell can update these files as its appearance changes.
  # Use Home Manager's GTK settings as defaults for new files.
  xdg.configFile."gtk-3.0/settings.ini".enable = false;
  xdg.configFile."gtk-4.0/settings.ini".enable = false;

  home.activation.seedGtkSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    lib.concatMapStringsSep "\n"
      (
        version:
        let
          path = "gtk-${version}.0/settings.ini";
          target = lib.escapeShellArg "${config.xdg.configHome}/${path}";
          directory = lib.escapeShellArg "${config.xdg.configHome}/gtk-${version}.0";
          source = lib.escapeShellArg (toString config.xdg.configFile.${path}.source);
        in
        ''
          if [[ ! -e ${target} && ! -L ${target} ]]; then
            run mkdir -p ${directory}
            run cp -T --update=none --no-preserve=mode ${source} ${target}
          fi
        ''
      )
      [
        "3"
        "4"
      ]
  );

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
    if [ ! -f "$HOME/.config/matugen/generated/kitty-colors.conf" ]; then
      run mkdir -p "$HOME/.config/matugen/generated"
      wall="$(find "$HOME/Pictures/walls" -type f | shuf -n 1)"
      if [ -n "$wall" ]; then
        run ${pkgs.matugen}/bin/matugen image "$wall" --type scheme-tonal-spot --mode smart || true
      fi
    fi
  '';
}
