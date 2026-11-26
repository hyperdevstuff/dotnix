{ config, pkgs, ... }:

{
  # niri only applies `open-floating` window rules when a window first maps.
  # Browser OAuth/Google sign-in pop-ups set their real title afterwards, so
  # this event-stream helper floats them once the title appears.
  home.file.".local/bin/niri-float-popups".source = ../dotfiles/bin/niri-float-popups;
  home.file.".local/bin/niri-float-popups".executable = true;

  systemd.user.services.niri-float-popups = {
    Unit = {
      Description = "Float late-titled OAuth/sign-in pop-ups";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${config.home.homeDirectory}/.local/bin/niri-float-popups";
      Environment = [
        "PATH=${pkgs.jq}/bin:${pkgs.niri}/bin:/run/current-system/sw/bin"
      ];
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
