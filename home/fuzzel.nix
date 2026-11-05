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
    font=JetBrainsMono Nerd Font:size=11
    icon-theme=Papirus-Dark
    layer=overlay
    prompt="> "
    width=40
    lines=12
    horizontal-pad=18
    vertical-pad=14
    inner-pad=10

    [border]
    width=2
    radius=12
  '';
}
