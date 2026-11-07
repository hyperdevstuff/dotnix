{
  pkgs,
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
  # Google's ACP agent is not the Antigravity IDE or CLI. Packaging it here
  # lets T3 find it on PATH instead of downloading ~1 GiB into the home
  # directory on first use.
  antigravity-acp = pkgs.callPackage ./antigravity-acp.nix { };

  # T3 is a control plane: the agent CLIs it orchestrates must be on PATH.
  # Keep them out of the FHS closure and prepend them to the launcher instead;
  # `AppRun` preserves the inherited PATH, so child processes still see them.
  runtimePackages = [
    gh
    git
    antigravity-acp
  ];

  # appimageTools.wrapType2 ignores the `desktopItems` argument, so the item
  # is installed explicitly below. Without this the profile has no launcher
  # and fuzzel never sees T3.
  #
  # The id is deliberately not `com.t3tools.T3Code`: on every launch T3
  # rewrites `$XDG_DATA_HOME/applications/com.t3tools.T3Code.desktop` with a
  # NoDisplay=true URL-handler entry. A user-dir entry shadows the profile
  # one, so sharing the id would make this launcher disappear from fuzzel.
  desktopItem = makeDesktopItem {
    name = "com.t3tools.T3Code.Nightly";
    desktopName = "T3 Code (Nightly)";
    exec = "t3code %U";
    icon = "t3code";
    comment = "Control plane for coding agents (nightly)";
    categories = [ "Development" ];
    # fuzzel matches keywords too; "t3code" does not fuzzy-match the name
    # "T3 Code (Nightly)" because of the space.
    keywords = [
      "t3"
      "t3code"
      "agent"
      "orchestrator"
      "antigravity"
    ];
    mimeTypes = [
      "x-scheme-handler/t3code"
      "x-scheme-handler/t3code-dev"
    ];
    startupWMClass = "t3code";
  };
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
    # Make the hidden URL-handler entry T3 self-registers point at this
    # wrapper too, so t3code:// links still get the agent CLIs on PATH.
    wrapProgram $out/bin/t3code \
      --prefix PATH : ${lib.makeBinPath runtimePackages} \
      --set T3CODE_DESKTOP_LAUNCHER_PATH "$out/bin/t3code"

    install -Dm444 ${finalAttrs.contents}/usr/share/icons/hicolor/512x512/apps/t3code.png \
      $out/share/icons/hicolor/512x512/apps/t3code.png

    install -Dm444 ${desktopItem}/share/applications/com.t3tools.T3Code.Nightly.desktop \
      $out/share/applications/com.t3tools.T3Code.Nightly.desktop
  '';

  meta = {
    description = "Open-source control plane for coding agents (nightly channel)";
    homepage = "https://t3.codes";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
})
