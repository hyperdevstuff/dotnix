{ pkgs, ... }:

{
  # Idle handling. swayidle talks to niri over ext-idle-notify-v1, so it works
  # without compositor-specific integration (hypridle is built around Hyprland
  # IPC and is not the right tool here).
  #
  # Any client holding an idle inhibitor (mpv, a browser playing video, ...)
  # postpones these timeouts, so media playback will not dim or lock the screen.
  #
  #   5 min  -> dim the backlight
  #   10 min -> lock
  #   15 min -> switch the panel off
  #
  # Adjust the three `timeout` values (in seconds) to taste.
  #
  # The unit is parsed by systemd, so a literal `%` has to be written `%%`;
  # swayidle receives `10%` after unescaping.
  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle management (dim, lock, display off)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 300 'brightnessctl -s set 10%%' resume 'brightnessctl -r' timeout 600 'quickshell ipc -c notchD call notchD lock' timeout 900 'niri msg action power-off-monitors' resume 'niri msg action power-on-monitors' before-sleep 'quickshell ipc -c notchD call notchD lock'";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
