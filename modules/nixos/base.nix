{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;

  nixpkgs.config.allowUnfree = true;

  programs = {
    dconf.enable = true;
    fish.enable = true;
    nix-ld.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    curl
    btop
    fastfetch
    tree
    ripgrep
    fd
    bat
    unzip
    zip
    file
    which
    less
    pciutils
    usbutils
    lsof
    nix-output-monitor
    nix-tree
  ];

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
  };

  console.keyMap = "us";

  networking.networkmanager.enable = true;

  hardware.bluetooth = {
    enable = true;
  };

  services = {
    fstrim.enable = true;
    fwupd.enable = true;
    udisks2.enable = true;
    # Intel 12th gen: let thermald throttle gracefully before the firmware
    # hits hard limits. Helps battery and sustained boost clocks.
    thermald.enable = true;
    # With 11 GB RAM, kill memory hogs before the kernel OOM killer stalls
    # the whole session.
    earlyoom.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    dejavu_fonts
    liberation_ttf
    roboto
    inter
    nerd-fonts.jetbrains-mono
  ];
}
