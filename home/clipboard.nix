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

  home.file.".local/bin/clipmenu-preview" = {
    source = ../dotfiles/bin/clipmenu-preview;
    executable = true;
  };

  # chafa renders image clips in the preview pane; file(1) decides whether a
  # clip is text, an image, or binary.
  home.packages = with pkgs; [
    chafa
    file
  ];

  # Keep the watcher alive for the niri session, like quickshell.
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

  # Wayland clears the clipboard as soon as the client owning it exits.
  # cliphist only keeps the *history*; this keeps the current copy alive so
  # Ctrl+V still works after closing the app it came from.
  systemd.user.services.wl-clip-persist = {
    Unit = {
      Description = "Keep the Wayland clipboard alive after clients exit";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
      Restart = "always";
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
