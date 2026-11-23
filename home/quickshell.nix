{ pkgs, ... }:

let
  systemctl = "${pkgs.systemd}/bin/systemctl";
  pauseGamingServices = pkgs.writeShellScript "pause-gaming-services" ''
    set -eu
    for unit in hex.service cliphist-watch.service cliphist-image-watch.service; do
      if ${systemctl} --user is-active --quiet "$unit"; then
        printf '%s\n' "$unit" >> "$RUNTIME_DIRECTORY/paused-services"
        ${systemctl} --user stop "$unit"
      fi
    done
  '';
  resumeGamingServices = pkgs.writeShellScript "resume-gaming-services" ''
    set -eu
    if [[ -s "$RUNTIME_DIRECTORY/paused-services" ]] &&
       ${systemctl} --user is-active --quiet graphical-session.target &&
       [[ -z $(${systemctl} --user show -P Job graphical-session.target) ]]; then
      mapfile -t units < "$RUNTIME_DIRECTORY/paused-services"
      ${systemctl} --user --job-mode=fail start "''${units[@]}"
    fi
  '';
in
{
  home.packages = with pkgs; [ python3 grim slurp swappy wl-clipboard jq font-awesome ];
  home.file.".local/bin/notchd-metrics" = {
    source = ../dotfiles/bin/notchd-metrics;
    executable = true;
  };
  home.file.".local/bin/notchd-screenshot" = {
    source = ../dotfiles/bin/notchd-screenshot;
    executable = true;
  };
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=$HOME/Pictures/Screenshots
    save_filename_format=Screenshot-%Y%m%d-%H%M%S.png
    show_panel=true
    show_decorations=true
    line_size=4
    text_size=18
    text_font=Inter
    early_exit=false
    auto_save=false
  '';

  programs.quickshell = {
    enable = true;
    configs = {
      default = ../dotfiles/quickshell;
      notchD = ../dotfiles/quickshell/notchD;
    };
    activeConfig = "notchD";

    systemd = {
      enable = true;
      target = "niri.service";
    };
  };

  # The module writes this path as a plain symlink. `force` makes activation
  # replace whatever is there (for example a development symlink into this
  # repo) instead of aborting with "Existing file ... would be clobbered".
  xdg.configFile."quickshell/notchD".force = true;

  # Quickshell lives in the niri session; stop it when niri goes away.
  systemd.user.services.quickshell.Unit.PartOf = [ "niri.service" ];
  # The shell is a config symlink: restart it whenever the QML tree changes,
  # otherwise the session keeps running the old store path until logout.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${../dotfiles/quickshell/notchD}"
  ];
  systemd.user.services.quickshell.Unit.X-SwitchMethod = "restart";

  systemd.user.services.notchd-game-mode = {
    Unit = {
      Description = "notchD Game Mode";
      PartOf = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "notchd-game-mode";
      RuntimeDirectoryMode = "0700";
      ExecStart = pauseGamingServices;
      ExecStopPost = resumeGamingServices;
    };
  };
}
