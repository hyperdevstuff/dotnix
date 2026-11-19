{ config, pkgs, lib, ... }:

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

  # awww's daemon is supervised here instead of being backgrounded by
  # `wp-boot`, so it restarts if it dies and the rotation timer below cannot
  # write to a stale socket. niri-session exports WAYLAND_DISPLAY into the
  # user manager before starting niri.service, so ordering after it is enough.
  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  # Rotate the wallpaper every 30 minutes. `wp random` also re-runs matugen,
  # so kitty/foot/fuzzel/niri/notchD follow each new wall. OnActiveSec counts
  # from when the timer starts (login), and `wp-boot` already themed the
  # session at startup. Wanted by timers.target rather than niri.service so a
  # `home-manager switch` starts it in the running session instead of waiting
  # for the next login.
  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate the wallpaper and regenerate the desktop theme";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" "awww-daemon.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/wp random";
    };
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit = {
      Description = "Rotate the wallpaper every 30 minutes";
      PartOf = [ "niri.service" ];
    };
    Timer = {
      OnActiveSec = "30min";
      OnUnitActiveSec = "30min";
      # Keep the change off the exact half hour.
      RandomizedDelaySec = "2min";
    };
    Install.WantedBy = [ "timers.target" ];
  };

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
