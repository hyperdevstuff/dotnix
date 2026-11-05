{ pkgs, ... }:

{
  # cliphist history: text and images, stored in $XDG_CACHE_HOME/cliphist/db.
  xdg.configFile."cliphist/config".text = ''
    max-items 1000
    max-store-size 25MB
  '';

  home.file.".local/bin/clipmenu" = {
    source = ../dotfiles/bin/clipmenu;
    executable = true;
  };

  # Keep the watcher alive for the niri session, like quickshell/mako.
  systemd.user.services.cliphist-watch = {
    Unit = {
      Description = "cliphist clipboard history watcher (text)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };

  # Browser copies of images usually offer text/html too; wl-paste prefers
  # text, so capture the image variant explicitly.
  systemd.user.services.cliphist-image-watch = {
    Unit = {
      Description = "cliphist clipboard history watcher (images)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
