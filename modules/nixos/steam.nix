{ pkgs, ... }:

{
  # Steam is an X11 client, so niri runs it through xwayland-satellite
  # (installed in modules/nixos/desktop.nix). The prerequisites are already
  # met elsewhere: nixpkgs.config.allowUnfree = true in base.nix covers the
  # unfree client, and hardware.graphics.enable32Bit = true in nvidia.nix
  # provides the 32-bit graphics stack Steam needs.
  #
  # Enabling this also turns on hardware.steam-hardware, which installs the
  # udev rules for the Steam Controller and Valve Index.
  programs.steam = {
    enable = true;

    # Steam Remote Play / Steam Link ports, in case the firewall is on.
    remotePlay.openFirewall = true;

    # Proton-GE, the community build that fixes games the bundled Proton
    # releases still break on. Pick it per game under Properties ->
    # Compatibility; NixOS exposes it via STEAM_EXTRA_COMPAT_TOOLS_PATHS.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  # Feral GameMode: opt in per game with `gamemoderun %command%` in its
  # launch options to get CPU governor and scheduler hints while it runs.
  programs.gamemode.enable = true;
}
