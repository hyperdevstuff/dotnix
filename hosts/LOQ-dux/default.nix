{
  imports = [ ../LOQ ];

  system.nixos.tags = [ "LOQ-dux" ];
  programs.dux-shell.enable = true;

  # The packaged unit starts with graphical-session.target. Keep its lifetime
  # tied to niri and use the session's PATH to find Quickshell and launch apps.
  systemd.user.services.dms = {
    after = [ "niri.service" ];
    partOf = [ "niri.service" ];
    enableDefaultPath = false;
    # DMS uses TERMINAL for Terminal=true entries such as btop.
    environment.TERMINAL = "kitty";
  };
}
