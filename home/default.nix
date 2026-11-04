{
  config,
  pkgs,
  username,
  inputs,
  ...
}:

{
  imports = [
    ./foot.nix
    ./kitty.nix
    ./shell.nix
    ./niri.nix
    ./nvim.nix
    ./quickshell.nix
    ./fuzzel.nix
    ./mako.nix
    inputs.helium-browser.homeModules.default

    # Phase 2: install OpenCode from nixpkgs only after the desktop
    # configuration has been built and booted successfully.
    # ./opencode.nix
  ];

  programs.helium = {
    enable = true;

    flags = [
      "--ozone-platform-hint=wayland"
    ];

    policies = {
      "BrowserSignin" = 0;
      "SyncDisabled" = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  xdg.enable = true;

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "firefox";
  };

  home.packages = with pkgs; [
    brave-origin
    firefox
    mpv
    imv
    zathura
    yazi
    nixfmt
    t3code
    obsidian
    papirus-icon-theme
    adwaita-icon-theme
    fsearch
    lazygit
  ];

  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };
  };
}
