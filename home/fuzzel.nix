{ pkgs, ... }:

{
  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        terminal = "${pkgs.foot}/bin/foot";
        font = "JetBrainsMono Nerd Font:size=11";
        icon-theme = "Papirus-Dark";
        layer = "overlay";
        prompt = "> ";
        width = 40;
        lines = 12;
        horizontal-pad = 18;
        vertical-pad = 14;
        inner-pad = 10;
      };

      colors = {
        background = "1e1e2eee";
        text = "cdd6f4ff";
        match = "89b4faff";
        selection = "585b70ff";
        selection-text = "cdd6f4ff";
        selection-match = "89b4faff";
        border = "cba6f7ff";
      };

      border = {
        width = 2;
        radius = 12;
      };
    };
  };
}
