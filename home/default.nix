{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./foot.nix
    ./shell.nix
    ./niri.nix
    ./quickshell.nix
    ./fuzzel.nix
    ./mako.nix

    # Phase 2: install OpenCode from nixpkgs only after the desktop
    # configuration has been built and booted successfully.
    # ./opencode.nix
  ];

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
    firefox
    mpv
    imv
    zathura
    yazi
    nixfmt
    papirus-icon-theme
    adwaita-icon-theme
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
