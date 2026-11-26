{ config, pkgs, ... }:

{
  imports = [
    ./clipboard.nix
    ./polkit.nix
    ./idle.nix
    ./wallpaper-fx.nix
    ./quickshell.nix
    ./fuzzel.nix
  ];

  xdg.configFile."niri/shell.kdl".source = ../dotfiles/niri/notchd.kdl;
  home.packages = [ pkgs.awww ];

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
      Wants = [ "awww-daemon.service" ];
      After = [
        "niri.service"
        "awww-daemon.service"
      ];
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
}
