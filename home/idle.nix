{ pkgs, ... }:

let
  # notchD owns idle lock, display-off and suspend. swayidle dims the
  # backlight and requests a lock before lid-close or explicit suspend.
  dimAfter = 180;

  lockCmd = "quickshell ipc -c notchD call notchD lock";
in
{
  # Idle handling. swayidle talks to niri over ext-idle-notify-v1, so it works
  # without compositor-specific integration (hypridle is built around Hyprland
  # IPC and is not the right tool here).
  #
  #
  # The unit is parsed by systemd, so a literal `%` has to be written `%%`;
  # swayidle receives `10%` after unescaping.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle backlight dimming and sleep lock hook";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w "
        + "timeout ${toString dimAfter} 'brightnessctl -s set 10%%' resume 'brightnessctl -r' "
        + "before-sleep '${lockCmd}'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
