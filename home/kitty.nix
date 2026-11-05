{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    settings = {
      # Imported from the old dotfiles (asked first):
      cursor_shape = "beam";
      cursor_trail = 1;
      cursor_trail_decay = "0.07 0.28";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Rice: breathing room, soft transparency, no double border (niri draws
      # the window border/rounding already), and a cinematic cursor trail.
      window_margin_width = 0;
      window_padding_width = 12;
      background_opacity = 0.94;
      dynamic_background_opacity = "yes";
      draw_minimal_borders = "no";
      window_border_width = 0;
      adjust_line_height = "110%";
      custom_shaders = "cursor-trail-motion-blur";
      scrollback_lines = 10000;
      mouse_hide_wait = 2.0;
      visual_bell_duration = 0.15;

      # Tab bar stays hidden until there are two tabs, then uses the generated
      # matugen tab colors as a bottom powerline.
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      tab_bar_edge = "bottom";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_bar_margin_height = "4 4";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
    };

    extraConfig = ''
      include /home/hyper/.config/matugen/generated/kitty-colors.conf
    '';

    # Vim-style scrolling; jump between shell prompts with p/n/o.
    # kitty_mod+1..0 focuses a split (kitty "window"); tabs get ctrl+alt+1..0.
    keybindings = {
      "ctrl+alt+1" = "goto_tab 1";
      "ctrl+alt+2" = "goto_tab 2";
      "ctrl+alt+3" = "goto_tab 3";
      "ctrl+alt+4" = "goto_tab 4";
      "ctrl+alt+5" = "goto_tab 5";
      "ctrl+alt+6" = "goto_tab 6";
      "ctrl+alt+7" = "goto_tab 7";
      "ctrl+alt+8" = "goto_tab 8";
      "ctrl+alt+9" = "goto_tab 9";
      "ctrl+alt+0" = "goto_tab 10";
      "kitty_mod+k" = "scroll_line_up";
      "kitty_mod+j" = "scroll_line_down";
      "kitty_mod+d" = "scroll_page_down";
      "kitty_mod+u" = "scroll_page_up";
      "kitty_mod+p" = "scroll_to_prompt -1";
      "kitty_mod+n" = "scroll_to_prompt 1";
      "kitty_mod+o" = "scroll_to_prompt 0";
    };
  };

  # Kitty creates a fresh NVIDIA OpenGL context per process (~90 ms of its
  # ~185 ms startup; foot has no GPU context). Keep one single-instance
  # server alive with a hidden window, so Mod+Q opens a new window in ~40 ms.
  systemd.user.services.kitty-server = {
    Unit = {
      Description = "Kitty single-instance server";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.kitty}/bin/kitty --single-instance --start-as=hidden";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
