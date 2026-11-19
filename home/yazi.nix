{ pkgs, ... }:

{
  # Yazi replaces the stock `yazi` entry from home/default.nix so the config,
  # plugins and helper binaries (ffmpeg, 7zz, poppler, chafa, ...) all come
  # from the same package. `enableFishIntegration` creates the `y` wrapper
  # that changes the shell's directory when Yazi exits.
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    # Plugins that shell out need their tools on Yazi's PATH.
    extraPackages = with pkgs; [
      ouch
      rich-cli
      wl-clipboard
    ];

    settings = {
      mgr = {
        ratio = [
          1
          4
          3
        ];
        sort_by = "natural";
        sort_dir_first = true;
        show_hidden = true;
        show_symlink = true;
        scrolloff = 5;
        linemode = "size";
      };

      preview = {
        wrap = "yes";
        tab_size = 2;
        max_width = 1200;
        max_height = 900;
        # Faster than lanczos3 on this laptop's GPU and good enough at 1080p.
        image_filter = "triangle";
        image_quality = 75;
      };

      opener = {
        edit = [
          {
            run = "nvim %s";
            block = true;
            for = "unix";
          }
        ];
        play = [
          {
            run = "mpv --speed=1.25 %s";
            orphan = true;
            for = "unix";
          }
        ];
      };

      plugin = {
        prepend_fetchers = [
          {
            url = "*";
            run = "git";
            group = "git";
          }
          {
            url = "*/";
            run = "git";
            group = "git";
          }
        ];

        prepend_previewers = [
          {
            url = "*.md";
            run = "rich-preview";
          }
          {
            url = "*.json";
            run = "rich-preview";
          }
          {
            url = "*.csv";
            run = "rich-preview";
          }
          {
            url = "*.rst";
            run = "rich-preview";
          }
          {
            url = "*.ipynb";
            run = "rich-preview";
          }
        ];
      };
    };

    keymap.mgr.prepend_keymap = [
      # FilePilot-style "go to": type a name, jump there (frecent dirs via zoxide).
      # `z` still does fzf over the current tree (files + dirs); `Z` is zoxide too.
      {
        on = "<C-p>";
        run = "plugin zoxide";
        desc = "Jump to a directory (zoxide, type to filter)";
      }
      {
        on = "l";
        run = "plugin smart-enter";
        desc = "Enter the directory, or open the file";
      }
      {
        on = "p";
        run = "plugin smart-paste";
        desc = "Paste into the hovered directory or CWD";
      }
      {
        on = "F";
        run = "plugin smart-filter";
        desc = "Smart filter (enter a unique directory automatically)";
      }
      {
        on = "T";
        run = "plugin toggle-pane min-preview";
        desc = "Show or hide the preview pane";
      }
      {
        on = "M";
        run = "plugin toggle-pane max-preview";
        desc = "Maximize or restore the preview pane";
      }
      {
        on = "<C-y>";
        run = "plugin wl-clipboard";
        desc = "Copy the selection to the system clipboard";
      }
      {
        on = "C";
        run = "plugin ouch";
        desc = "Compress the selection with ouch";
      }
    ];

    plugins = {
      smart-enter = pkgs.yaziPlugins.smart-enter;
      smart-paste = pkgs.yaziPlugins.smart-paste;
      smart-filter = pkgs.yaziPlugins.smart-filter;
      toggle-pane = pkgs.yaziPlugins.toggle-pane;
      wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
      ouch = pkgs.yaziPlugins.ouch;
      rich-preview = pkgs.yaziPlugins.rich-preview;

      full-border = {
        package = pkgs.yaziPlugins.full-border;
        setup = true;
        settings.set = "rounded";
      };

      git = {
        package = pkgs.yaziPlugins.git;
        setup = true;
        settings.order = 1500;
      };

      mime-ext = {
        package = pkgs.yaziPlugins.mime-ext;
        setup = true;
      };
    };
  };
}
