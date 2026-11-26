{
  config,
  lib,
  pkgs,
  ...
}:

let
  settingsDir = lib.escapeShellArg "${config.xdg.configHome}/dms";
  defaults = pkgs.writeText "dux-settings.json" (
    builtins.toJSON {
      lockBeforeSuspend = true;
    }
  );
in
{
  xdg.configFile."niri/shell.kdl".source = ../dotfiles/niri/dux.kdl;

  # Match LOQ's lock-before-sleep behavior on first launch. DMS owns the
  # writable settings file so preferences can be changed from its UI.
  home.activation.duxSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e ${settingsDir}/settings.json && ! -L ${settingsDir}/settings.json ]]; then
      run install -Dm600 ${defaults} ${settingsDir}/settings.json
    fi
  '';
}
