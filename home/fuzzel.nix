{ pkgs, ... }:

{
  # Fuzzel reads include from the default section and keeps its own
  # section scope afterwards. HM's ini module can't express a top-level
  # include, so the config is written by hand. fuzzel itself is installed
  # via modules/nixos/desktop.nix.
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    include=/home/hyper/.config/matugen/generated/fuzzel-colors.ini

    [main]
    terminal=${pkgs.foot}/bin/foot
    font=JetBrainsMono Nerd Font:size=14
    icon-theme=Papirus-Dark
    layer=overlay
    prompt="> "
    width=56
    lines=14
    line-height=26
    horizontal-pad=26
    vertical-pad=20
    inner-pad=14

    [border]
    width=1
    radius=16
    selection-radius=10
  '';
}
