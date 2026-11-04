# Phase 2 - not imported yet.
#
# This flake tracks nixos-unstable, where pkgs.opencode is v2.
# Enable this only after the desktop rebuild has booted successfully,
# then remove the npm install and the fish_add_path line so the Nix
# package is the one that gets used.
{ pkgs, ... }:

{
  home.packages = [ pkgs.opencode ];
}
