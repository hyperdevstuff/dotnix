{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 12;
    };

    settings = {
      cursor_shape = "beam";
      cursor_trail = 1;
      cursor_trail_decay = "0.07 0.28";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

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

    keybindings = {
      "kitty_mod+1" = "goto_tab 1";
      "kitty_mod+2" = "goto_tab 2";
      "kitty_mod+3" = "goto_tab 3";
      "kitty_mod+4" = "goto_tab 4";
      "kitty_mod+5" = "goto_tab 5";
      "kitty_mod+6" = "goto_tab 6";
      "kitty_mod+7" = "goto_tab 7";
      "kitty_mod+8" = "goto_tab 8";
      "kitty_mod+9" = "goto_tab 9";
      "kitty_mod+0" = "goto_tab 10";
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
