{ ... }:

{
  # Foot reads include anywhere in the file; HM's ini module can't express
  # a top-level include, so the config is written by hand. foot itself is
  # installed via modules/nixos/desktop.nix.
  xdg.configFile."foot/foot.ini".text = ''
    include=/home/hyper/.config/matugen/generated/foot-colors.ini

    [main]
    font=JetBrainsMono Nerd Font:size=11
    pad=10x10
  '';
}
