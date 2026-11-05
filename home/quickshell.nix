{ ... }:

{
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

  # Quickshell lives in the niri session; stop it when niri goes away.
  systemd.user.services.quickshell.Unit.PartOf = [ "niri.service" ];
  # The shell is a config symlink: restart it whenever the QML tree changes,
  # otherwise the session keeps running the old store path until logout.
  systemd.user.services.quickshell.Unit.X-Restart-Triggers = [
    "${../dotfiles/quickshell/notchD}"
  ];
  systemd.user.services.quickshell.Unit.X-SwitchMethod = "restart";
}
