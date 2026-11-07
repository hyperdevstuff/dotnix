{ config, pkgs, ... }:

{
  # MPD is the player: a small daemon with no GUI, no Electron and no media
  # indexer of its own. `mpc` scripts it, `rmpc` is the TUI, and mpdris2-rs
  # exposes MPRIS so notchD's now-playing card and the media keys keep working.
  services.mpd = {
    enable = true;
    musicDirectory = "/mnt/library/Music";

    # Socket activation: MPD only runs while something is talking to it. The
    # first `mpc` call starts it; it idles out again afterwards.
    network.startWhenNeeded = true;

    extraConfig = ''
      # PipeWire is already the session's sound server.
      audio_output {
          type "pipewire"
          name "PipeWire"
      }

      # Disabled: the library lives on a slow NTFS HDD and auto-scanning
      # causes avoidable spin-ups/I/O. Run `mpc update` (or `mpc update
      # /path`) after adding or changing files.
      auto_update "no"
    '';
  };

  services.mpdris2-rs = {
    enable = true;
    # notchD shows the current track; mako notifications for every song change
    # would be noise.
    notifications.enable = false;
  };

  home.packages = with pkgs; [
    mpc
    rmpc
  ];

  home.file.".local/bin/music-shuffle" = {
    source = ../dotfiles/bin/music-shuffle;
    executable = true;
  };

  # rmpc's default theme uses ANSI color names, so matugen's kitty palette
  # (written from the wallpaper) colors it too. Only layout/behaviour is set.
  xdg.configFile."rmpc/config.ron".source = ../dotfiles/rmpc/config.ron;

  # Library-wide exclusions for `music-shuffle` (scores, soundtracks, ...).
  xdg.configFile."music/ignore".source = ../dotfiles/music/ignore;
}
