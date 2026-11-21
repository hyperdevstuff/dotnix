{ pkgs, ... }:

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
}
