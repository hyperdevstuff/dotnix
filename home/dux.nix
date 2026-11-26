{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  settingsDir = lib.escapeShellArg "${config.xdg.configHome}/dms";
  setupPath = lib.makeBinPath [
    osConfig.programs.dux-shell.package
    osConfig.programs.niri.package
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
  ];
  defaults = pkgs.writeText "dux-settings.json" (
    builtins.toJSON {
      lockBeforeSuspend = true;
    }
  );
in
{
  # Save and replace the old link before Home Manager removes it. Future
  # activations leave DMS's writable files alone.
  home.activation.duxNiri = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
    run env PATH=${setupPath} \
      XDG_CONFIG_HOME=${lib.escapeShellArg config.xdg.configHome} \
      XDG_STATE_HOME=${lib.escapeShellArg config.xdg.stateHome} \
      ${pkgs.bash}/bin/bash ${../scripts/setup-dux-niri}
  '';

  # Match LOQ's lock-before-sleep behavior on first launch. DMS owns the
  # writable settings file so preferences can be changed from its UI.
  home.activation.duxSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -e ${settingsDir}/settings.json && ! -L ${settingsDir}/settings.json ]]; then
      run install -Dm600 ${defaults} ${settingsDir}/settings.json
    fi
  '';
}
