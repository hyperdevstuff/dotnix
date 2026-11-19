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
    ./polkit.nix
    ./udiskie.nix
    ./idle.nix
    ./kitty.nix
    ./shell.nix
    ./niri.nix
    ./matugen.nix
    ./nvim.nix
    ./quickshell.nix
    ./fuzzel.nix
    # Disabled on the fresh install: MPD points at /mnt/library, which is
    # not mounted (the NTFS data disk is not attached). Re-enable together
    # with the mount in hosts/LOQ/default.nix.
    # ./music.nix
    ./yazi.nix
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

  # The SSD (see hosts/LOQ/storage.nix) no longer needs the old page-cache
  # warm-up service that existed for the 5400 rpm USB HDD. Helium opens
  # cold in a fraction of a second now.

  programs.hex = {
    enable = true;
    package = inputs.hex.packages.${pkgs.stdenv.hostPlatform.system}.default;
    # Start the one supervised Hex through systemd at login. The old XDG
    # autostart entry has been removed so it cannot spawn a second instance.
    autostart = true;
    installModel = false;

    # niri does not expose a working GlobalShortcuts portal, so Hex's own
    # grabs do not reach the compositor. Bind its CLI in niri instead
    # (see dotfiles/niri/config.kdl) and use toggle mode, which works with
    # a single key press. The settings also keep X11 and the Hex UI in sync.
    # Hex calls Alt "option"; on Linux this is Alt+Space.
    shortcut = "option+space";
    settings = {
      shortcut_mode = "toggle";
      # F10 is the hardware touchpad-toggle key on the LOQ, so paste-last
      # lives on Ctrl+Alt+V (bound in niri's config as well).
      paste_last_hotkey = "ctrl+alt+v";
      # kitty/foot paste with Ctrl+Shift+V, not Ctrl+V.
      paste_with_shift = true;
      # Show provisional words while dictating; cheap and useful.
      "labs.live_text" = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  xdg.enable = true;

  # OpenCode uses the "system" TUI theme: it takes its ANSI colors from the
  # terminal, which matugen writes for kitty/foot. So the agent UI follows the
  # wallpaper too.
  xdg.configFile."opencode/tui.json".source = ../dotfiles/opencode/tui.json;

  # Helium is the default browser (CLI also respects BROWSER below).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "helium.desktop" ];
      "application/xhtml+xml" = [ "helium.desktop" ];
      "application/xhtml_xml" = [ "helium.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "application/pdf" = [ "helium.desktop" ];
      "x-scheme-handler/t3code" = [ "com.t3tools.T3Code.Nightly.desktop" ];
      "x-scheme-handler/paper" = [ "paper-desktop.desktop" ];
      "x-scheme-handler/paper-dev" = [ "paper-desktop.desktop" ];
      # Neovim is the default editor for text and source files.
      "text/plain" = [ "nvim.desktop" ];
      "text/markdown" = [ "nvim.desktop" ];
      "application/json" = [ "nvim.desktop" ];
      "text/x-shellscript" = [ "nvim.desktop" ];
      "text/x-python" = [ "nvim.desktop" ];
      "text/x-csrc" = [ "nvim.desktop" ];
      "text/x-rust" = [ "nvim.desktop" ];
      "text/x-lua" = [ "nvim.desktop" ];
      "text/x-nix" = [ "nvim.desktop" ];
    };
    associations.added = {
      "x-scheme-handler/t3code" = [ "com.t3tools.T3Code.Nightly.desktop" ];
      "x-scheme-handler/paper" = [ "paper-desktop.desktop" ];
      "x-scheme-handler/paper-dev" = [ "paper-desktop.desktop" ];
    };
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  # Keep the last dictation on the clipboard on purpose (Hex restores the
  # previous clipboard after pasting). Bound to Ctrl+Alt+C in niri.
  home.file.".local/bin/hexclip".source = ../dotfiles/bin/hexclip;
  home.file.".local/bin/hexclip".executable = true;

  # Esc handler: cancels a running Hex dictation, otherwise replays Escape.
  home.file.".local/bin/hex-escape".source = ../dotfiles/bin/hex-escape;
  home.file.".local/bin/hex-escape".executable = true;

  # Trial another Quickshell shell in a nested niri window.
  home.file.".local/bin/try-shell".source = ../scripts/try-shell;
  home.file.".local/bin/try-shell".executable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "helium";
  };

  home.packages = with pkgs; [
    brave-origin
    firefox
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    mpv
    imv
    zathura
    nixfmt
    (pkgs.callPackage ../pkgs/t3code-nightly.nix { })
    # pkgs.opencode-desktop
    (pkgs.callPackage ../pkgs/paper-desktop.nix { })
    obsidian
    papirus-icon-theme
    adwaita-icon-theme
    fsearch
    lazygit
    wtype
    typst
    tinymist
    typstyle
    trash-cli
    gcc
  ];

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
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
