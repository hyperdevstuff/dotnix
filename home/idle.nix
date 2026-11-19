{ pkgs, ... }:

let
  # Idle schedule, in seconds. Change these three to taste.
  #
  #   3 min  -> dim the backlight
  #   5 min  -> lock the session
  #   10 min -> suspend (logind runs `before-sleep` first, so it locks too)
  dimAfter = 180;
  lockAfter = 300;
  sleepAfter = 600;

  lockCmd = "quickshell ipc -c notchD call notchD lock";
in
{
  # Idle handling. swayidle talks to niri over ext-idle-notify-v1, so it works
  # without compositor-specific integration (hypridle is built around Hyprland
  # IPC and is not the right tool here).
  #
  # Any client holding an idle inhibitor (mpv, a browser playing video, ...)
  # postpones these timeouts, so media playback will not dim, lock or suspend.
  #
  # The unit is parsed by systemd, so a literal `%` has to be written `%%`;
  # swayidle receives `10%` after unescaping.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle management (dim, lock, sleep)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w "
        + "timeout ${toString dimAfter} 'brightnessctl -s set 10%%' resume 'brightnessctl -r' "
        + "timeout ${toString lockAfter} '${lockCmd}' "
        + "timeout ${toString sleepAfter} 'systemctl suspend' "
        + "before-sleep '${lockCmd}'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
