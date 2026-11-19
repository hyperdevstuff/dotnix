{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
}:

# Paper only ships an AppImage for Linux. The download URL is stable but the
# payload is versioned, so bump `version` and the hash together when it moves.
let
  # `appimageTools.wrapType2` is a buildFHSEnv wrapper and silently drops the
  # `desktopItems` argument, so the launcher is installed explicitly below.
  # Without this the package has no .desktop file and fuzzel never sees it.
  desktopItem = makeDesktopItem {
    name = "paper-desktop";
    desktopName = "Paper";
    exec = "paper-desktop --no-sandbox %U";
    icon = "paper-desktop";
    comment = "Design app for creating visuals and user interfaces";
    categories = [
      "Graphics"
      "Development"
    ];
    startupWMClass = "Paper";
    mimeTypes = [
      "x-scheme-handler/paper"
      "x-scheme-handler/paper-dev"
    ];
  };
in
appimageTools.wrapType2 (finalAttrs: {
  pname = "paper-desktop";
  # `download.paper.design/linux/appImage/x64` is a moving "latest" URL. The
  # pinned hash currently resolves to 0.5.19; bump this label when the hash is
  # refreshed, since the AppImage itself carries the real version.
  version = "0.5.19";

  src = fetchurl {
    url = "https://download.paper.design/linux/appImage/x64";
    hash = "sha256-YKZUYnYHCJ8ARLLPjEY20bAZ2Qdx0PrsrteDdLJa4Es=";
  };

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
    install -Dm444 ${finalAttrs.contents}/usr/share/icons/hicolor/1024x1024/apps/paper-desktop.png \
      $out/share/icons/hicolor/1024x1024/apps/paper-desktop.png

    install -Dm444 ${desktopItem}/share/applications/paper-desktop.desktop \
      $out/share/applications/paper-desktop.desktop
  '';

  meta = {
    description = "Design app for creating visuals and user interfaces";
    homepage = "https://paper.design";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "paper-desktop";
  };
})
