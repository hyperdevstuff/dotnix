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

      # TEMPORARY: keep the existing npm OpenCode v2 usable until the Nix
      # package is enabled in phase 2.
      if test -x /home/hyper/.opencode/bin/opencode
          fish_add_path --move --prepend /home/hyper/.opencode/bin
      end
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
    };
  };

  programs = {
    fzf.enable = true;

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = [ "--cmd" "cd" ];
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
        init.defaultBranch = "main";
        pull.rebase = false;
        core.editor = "nvim";
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
