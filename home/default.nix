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
    ./clipboard.nix
    ./kitty.nix
    ./shell.nix
    ./niri.nix
    ./matugen.nix
    ./nvim.nix
    ./quickshell.nix
    ./fuzzel.nix
    ./mako.nix
    inputs.helium-browser.homeModules.default
    inputs.hex.homeManagerModules.default

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

  programs.hex = {
    enable = true;
    package = inputs.hex.packages.${pkgs.stdenv.hostPlatform.system}.default;
    autostart = false;
    installModel = false;
  };

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  xdg.enable = true;

  # Helium is the default browser (CLI also respects BROWSER below).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "helium.desktop" ];
      "application/xhtml+xml" = [ "helium.desktop" ];
      "application/xhtml_xml" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "application/pdf" = [ "helium.desktop" ];
      "x-scheme-handler/t3code" = [ "com.t3tools.T3Code.desktop" ];
    };
    associations.added = {
      "x-scheme-handler/t3code" = [ "com.t3tools.T3Code.desktop" ];
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "helium";
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
