# Local packages as a package set, so they can be evaluated outside the NixOS
# configuration:
#
#   nix build -f pkgs ardia
#   nix-update -f pkgs ardia --version unstable --version-regex '(v0\..*)'
#
# The flake re-exports this set as `packages.x86_64-linux`, but passes its own
# nixpkgs so `nix build .#ardia` matches the system. `nix-update` uses the
# `<nixpkgs>` default, which is fine because it only reads versions and
# computes fixed-output hashes.
{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:
{
  antigravity-acp = pkgs.callPackage ./antigravity-acp.nix { };
  ardia = pkgs.callPackage ./ardia.nix { };
  hex-bin = pkgs.callPackage ./hex-bin.nix { };
  paper-desktop = pkgs.callPackage ./paper-desktop.nix { };
  t3code-nightly = pkgs.callPackage ./t3code-nightly.nix { };
}
