{
  config,
  pkgs,
  ...
}:

let
  # Shared eza flags. Home Manager's eza integration only attaches
  # `extraOptions` to the bare `eza` alias, so spell them out here.
  ezaArgs = "--icons auto --color auto --git --group-directories-first --header";
in
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -g fish_greeting
      set -gx EDITOR nvim
      set -gx VISUAL nvim

      # Vi-style editing everywhere, with a shape-changing cursor.
      # Escape leaves insert mode; normal/visual motions are the usual vim ones.
      fish_vi_key_bindings
      fish_vi_cursor

      function open_yazi --description 'Open Yazi and return to its last directory'
          # `y` is the wrapper Home Manager generates for programs.yazi.
          y
          commandline -f repaint
      end

      # Ctrl+E in insert mode: edit the current directory in Yazi, then come
      # back to a usable prompt in whatever directory Yazi exited from.
      bind -M insert \ce open_yazi
      # Ctrl+Y accepts the inline autosuggestion; Ctrl+P/N stay history search.
      bind -M insert \cy accept-autosuggestion
      bind -M insert \cp up-or-search
      bind -M insert \cn down-or-search

      # Keep fzf's widgets usable in vi insert mode; sourcing its bindings
      # happens before fish_vi_key_bindings, which would otherwise shadow them.
      bind -M insert \cr fzf-history-widget
      bind -M insert \ct fzf-file-widget
      bind -M insert \ec fzf-cd-widget

      # Visual-mode conveniences carried over from the old dotfiles.
      bind -M visual V beginning-of-line begin-selection end-of-line force-repaint
      bind -M visual u end-selection force-repaint
      bind -M visual \x24 end-of-line
      bind -M visual \x5e beginning-of-line
      bind -M visual 0 beginning-of-line
      bind -M visual gg beginning-of-buffer
      bind -M visual G end-of-buffer

      fish_add_path "/home/hyper/.cache/.bun/bin"
    '';

    # Hydro: fish-native prompt, async git, no process spawn per render
    # (vs starship which forks a binary every prompt).
    plugins = [
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }
    ];

    shellAliases = {
      # --- existing listing/eza aliases ---
      ls = "eza ${ezaArgs}";
      ll = "eza -l ${ezaArgs}";
      la = "eza -a ${ezaArgs}";
      lla = "eza -la ${ezaArgs}";
      lt = "eza --tree --level=2 ${ezaArgs}";
      tree = "eza --tree --level=3 ${ezaArgs}";
      lS = "eza --long --icons --sort=size --reverse --color=auto --group-directories-first";
      lm = "eza --long --icons --sort=modified --reverse --color=auto --group-directories-first";
      lG = "eza --long --icons --git --color=auto --group-directories-first";

      # --- NixOS ---
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/dotnix#LOQ";
      rebuild-boot = "sudo nixos-rebuild boot --flake ${config.home.homeDirectory}/dotnix#LOQ";
      flake-update = "nix flake update --flake ${config.home.homeDirectory}/dotnix";
      gc = "sudo nix-collect-garbage -d";
      reup = "nix flake update && sudo nixos-rebuild switch --flake ~/dotnix#LOQ";
      # --- basics ---
      n = "nvim";
      x = "exit";
      mk = "mkdir";
      ".." = "cd ..";
      "..." = "cd ../..";
      rel = "source ~/.config/fish/config.fish";

      # --- typo fixes ---
      gti = "git";
      gut = "git";
      claer = "clear";

      # --- safe operations ---
      rm = "rm -Ii";
      cp = "cp -i";
      mv = "mv -i";

      # --- modern CLI ---
      cat = "bat --style=auto";
      grep = "rg";
      top = "btop";

      # --- git ---
      g = "git";
      gs = "git status";
      gst = "git status --short";
      ga = "git add";
      gaa = "git add --all";
      gcm = "git commit -m";
      gcam = "git commit -am";
      gp = "git push";
      gpl = "git pull";
      gd = "git diff";
      gco = "git checkout";
      gb = "git branch";
      glog = "git log --oneline --graph --all";
      lg = "lazygit";

      # --- fzf power tools ---
      ff = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
      nf = "fzf -m --preview='bat --color=always {}' --bind 'enter:become(nvim {+})'";
      fcd = "cd (fd -t d | fzf)";

      # --- system info ---
      ports = "ss -tulpn";
      wtf3000 = "fuser -v 3000/tcp";
      psg = "ps aux | rg";
      size = "du -sh --block-size=MB";

      # --- music (MPD on the NTFS library) ---
      # Disabled on the fresh install: the library disk is not attached.
      # Re-enable together with home/music.nix and the mount.
      # music = "rmpc";
      # shuffle = "music-shuffle";
      # lib = "cd /mnt/library";

      # --agentic work
      oc = "opencode";
    };
  };

  programs = {
    fzf.enable = true;

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [
        "--cmd"
        "cd"
      ];
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
    };

    bat.enable = true;

    eza = {
      enable = true;
      enableFishIntegration = true;
      icons = "auto";
      colors = "auto";
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };

    git = {
      enable = true;
      settings = {
        user.name = "hyperdevstuff";
        user.email = "168334425+hyperdevstuff@users.noreply.github.com";
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "nvim";
        credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
    };
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq
    tree
  ];
}
