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

    shellAliases = {
      ls = "eza ${ezaArgs}";
      ll = "eza -l ${ezaArgs}";
      la = "eza -a ${ezaArgs}";
      lla = "eza -la ${ezaArgs}";
      lt = "eza --tree --level=2 ${ezaArgs}";
      rebuild = "sudo nixos-rebuild switch --flake ${config.home.homeDirectory}/dotnix#LOQ";
      rebuild-boot = "sudo nixos-rebuild boot --flake ${config.home.homeDirectory}/dotnix#LOQ";
      flake-update = "nix flake update --flake ${config.home.homeDirectory}/dotnix";
      gc = "sudo nix-collect-garbage -d";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";
    };
  };

  programs = {
    fzf.enable = true;

    zoxide = {
      enable = true;
      enableFishIntegration = true;
      # Make `cd` use zoxide's frecency database.
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
