{
  config,
  lib,
  pkgs,
  ...
}:

let
  inferenceTools = pkgs.callPackage ../pkgs/inference-tools.nix { };
  t3codeLocal = pkgs.callPackage ../pkgs/t3code-local.nix { };
  t3DesktopId = "com.t3tools.T3Code.Nightly";
  t3Schemes = [
    "x-scheme-handler/t3code"
    "x-scheme-handler/t3code-dev"
  ];
  t3Associations = lib.genAttrs t3Schemes (_: [ "${t3DesktopId}.desktop" ]);
in
{
  home.packages = [ inferenceTools ];

  # Stable executable paths for shells and ADE provider settings.
  home.file =
    lib.genAttrs' [ "agent-tools-update" "codex" "opencode" "omp" "pi" ] (
      name: lib.nameValuePair ".local/bin/${name}" { source = "${inferenceTools}/bin/${name}"; }
    )
    // {
      ".local/bin/t3code".source = lib.getExe t3codeLocal;
    };

  xdg.desktopEntries.${t3DesktopId} = {
    name = "T3 Code (Nightly)";
    exec = "${config.home.homeDirectory}/.local/bin/t3code %U";
    icon = "${config.xdg.dataHome}/icons/com.t3tools.T3Code.desktop.png";
    categories = [ "Development" ];
    mimeType = t3Schemes;
    settings = {
      Keywords = "t3;t3code;agent;";
      StartupWMClass = "t3code";
    };
  };

  xdg.mimeApps = {
    defaultApplications = t3Associations;
    associations.added = t3Associations;
  };
}
