{ ... }:

{
  services.mako = {
    enable = true;

    settings = {
      anchor = "top-right";
      default-timeout = 8000;
      width = 360;
      height = 160;
      margin = 10;
      padding = 12;
      border-size = 2;
      border-radius = 10;
      font = "JetBrainsMono Nerd Font 10";
      progress-color = "over #89b4fa";
      icons = true;
      max-icon-size = 48;
      layer = "overlay";
      group-by = "app-name";
    };

    # Colors come from matugen (wallpaper-first theming); appended last so
    # they win over anything above.
    extraConfig = ''
      include=/home/hyper/.config/matugen/generated/mako-colors
    '';
  };
}
