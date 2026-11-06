{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
  makeWrapper,
  opencode,
  codex,
  gh,
  git,
}:

let
  # T3 is a control plane: the agent CLIs it orchestrates must be on PATH.
  # Keep them out of the FHS closure and prepend them to the launcher instead;
  # `AppRun` preserves the inherited PATH, so child processes still see them.
  runtimePackages = [
    gh
    git
  ];
in
# T3 Code nightly. The nightly channel is where Orchestrator V2 gains the
# newest provider work (Antigravity, OpenCode), so it is packaged separately
# from the stable `t3code` in nixpkgs. It uses the desktop id from nixpkgs so
# existing x-scheme-handler/t3code associations keep working.
appimageTools.wrapType2 (finalAttrs: {
  pname = "t3code";
  version = "0.1.8-nightly.20261106.4247";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${finalAttrs.version}/T3-Code-${finalAttrs.version}-x86_64.AppImage";
    hash = "sha256-1k6zH07M1nxkU7LHAjjpmyyWLI4a3lo0cFP8PjUJKzE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  extraPkgs =
    pkgs: with pkgs; [
      nss
      gtk3
      libx11
      libxcb
      libxrandr
      libxcomposite
      libxdamage
      libxfixes
      libxext
      libdbusmenu
      alsa-lib
    ];

  extraInstallCommands = ''
    wrapProgram $out/bin/t3code \
      --prefix PATH : ${lib.makeBinPath runtimePackages}

    install -Dm444 ${finalAttrs.contents}/usr/share/icons/hicolor/512x512/apps/t3code.png \
      $out/share/icons/hicolor/512x512/apps/t3code.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "com.t3tools.T3Code";
      desktopName = "T3 Code (Nightly)";
      exec = "t3code %U";
      icon = "t3code";
      comment = "Control plane for coding agents (nightly)";
      categories = [ "Development" ];
      mimeTypes = [
        "x-scheme-handler/t3code"
        "x-scheme-handler/t3code-dev"
      ];
      startupWMClass = "t3code";
    })
  ];

  meta = {
    description = "Open-source control plane for coding agents (nightly channel)";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
})
