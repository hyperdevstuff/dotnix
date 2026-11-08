{ pkgs, ... }:

{
  # udisks2 is enabled system-wide. udiskie mounts removable media when it is
  # plugged in and unmounts it on unplug. No tray icon: the session has no
  # status-notifier host, and plugin notifications go through the native
  # Quickshell notification server.
  systemd.user.services.udiskie = {
    Unit = {
      Description = "Removable media automounter";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray --notify --automount";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
