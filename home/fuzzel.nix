{ pkgs, ... }:

{
  # Fuzzel stays the app launcher even after adding the fzf clipboard picker:
  # measured on this machine it is ~29 MB RSS / ~147 MB closure, versus
  # ~305 MB server RSS / ~985 MB closure for Vicinae and ~964 MB closure for
  # Walker. The slowness people notice is cold-cache I/O on the 5400 rpm HDD,
  # not Fuzzel itself; kitty's warm single-instance server avoids spawning a
  # fresh GPU context when Fuzzel needs a terminal.
  #
  # The config is hand-written because Home Manager's ini module cannot put a
  # top-level `include` before the `[main]` section.
  home.packages = [ pkgs.fuzzel ];

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    include=/home/hyper/.config/matugen/generated/fuzzel-colors.ini

    [main]
    terminal=${pkgs.kitty}/bin/kitty --single-instance
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
