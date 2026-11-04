{ ... }:

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
      window_margin_width = 8;
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";
    };

    # Vim-style scrolling; jump between shell prompts with p/n/o.
    keybindings = {
      "kitty_mod+k" = "scroll_line_up";
      "kitty_mod+j" = "scroll_line_down";
      "kitty_mod+d" = "scroll_page_down";
      "kitty_mod+u" = "scroll_page_up";
      "kitty_mod+p" = "scroll_to_prompt -1";
      "kitty_mod+n" = "scroll_to_prompt 1";
      "kitty_mod+o" = "scroll_to_prompt 0";
    };
  };
}
