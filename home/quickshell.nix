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
}
