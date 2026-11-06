{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
}:

# Paper only ships an AppImage for Linux. The download URL is stable but the
# payload is versioned, so bump `version` and the hash together when it moves.
appimageTools.wrapType2 (finalAttrs: {
  pname = "paper-desktop";
  version = "0.5.16";

  src = fetchurl {
    url = "https://download.paper.design/linux/appImage/x64";
    hash = "sha256-TxJ8+a8bb2XOGv7YzDoPcQ5RZ794nzbAFvRCr5aECrk=";
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
  '';

  desktopItems = [
    (makeDesktopItem {
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
    })
  ];

  meta = {
    description = "Design app for creating visuals and user interfaces";
    homepage = "https://paper.design";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "paper-desktop";
  };
})
