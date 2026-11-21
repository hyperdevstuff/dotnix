{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libpulseaudio,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  wayland,
}:

# Ardia ships a plain tarball whose install.sh copies the browser into /usr
# and chmods chrome-sandbox setuid root. Neither step works on NixOS: the
# dynamic loader has no /usr/lib to search, and setuid bits cannot exist in
# the store. This derivation performs the same install without root, and
# ardia-launch falls back to unprivileged user namespaces for Chromium's
# sandbox, which NixOS leaves enabled (AppArmor is off, so the Ubuntu-style
# userns restriction does not apply either).
#
# The tarball is a self-updating nightly. Because the store is read-only the
# in-app updater cannot replace it; bump `version` and `hash` here instead.
stdenv.mkDerivation (finalAttrs: {
  pname = "ardia";
  version = "0.2.47-nightly.9";

  src = fetchzip {
    url = "https://github.com/ardia-browser/ardia/releases/download/v${finalAttrs.version}/Ardia-${finalAttrs.version}-linux-x64.tar.xz";
    hash = "sha256-qlZi1hU+q00+OIVy6D5gKAmA0gTWg7VN+iYGl3FYzLo=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libpulseaudio
    libxcb
    libxkbcommon
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxrandr
    libxrender
    libxscrnsaver
    libxshmfence
    nspr
    nss
    pango
    systemd
  ];

  # Chromium dlopens the GL, input-method and desktop-integration libraries,
  # so DT_NEEDED alone does not put them on the binary's RUNPATH. Wayland and
  # PipeWire are the Ozone backend and WebRTC screen capture.
  runtimeDependencies = [
    gtk3
    libdrm
    libGL
    libnotify
    libpulseaudio
    libxcursor
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxshmfence
    pipewire
    wayland
  ];

  # libqt{5,6}_shim.so is Chromium's optional Qt theme integration. This is a
  # GTK desktop, so leave the shims unpatched rather than pull in all of Qt.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  dontConfigure = true;
  dontBuild = true;
  # The 300 MB Chromium binary is already stripped; re-stripping only costs
  # build time and risks breaking the crash reporter.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib $out/bin $out/share/applications \
      $out/share/icons/hicolor/256x256/apps $out/share/polkit-1/actions

    cp -R lib/ardia $out/lib/ardia
    chmod -R u+w $out/lib/ardia

    # install.sh rewrites Exec= to the install prefix. Keep it absolute so the
    # launcher also works when the profile is not on PATH.
    substitute share/applications/ardia.desktop \
      $out/share/applications/ardia.desktop \
      --replace-fail "Exec=ardia " "Exec=$out/bin/ardia "

    install -Dm644 share/icons/hicolor/256x256/apps/ardia.png \
      $out/share/icons/hicolor/256x256/apps/ardia.png
    install -Dm644 share/polkit-1/actions/dev.ardia.linux.policy \
      $out/share/polkit-1/actions/dev.ardia.linux.policy

    # Same thin launcher install.sh writes: ardia-launch picks the sandbox
    # strategy, so bin/ardia must not exec chrome directly.
    cat > $out/bin/ardia <<EOF
    #!${stdenv.shell}
    exec "$out/lib/ardia/ardia-launch" "\$@"
    EOF
    chmod 0755 $out/bin/ardia

    runHook postInstall
  '';

  meta = {
    description = "Chromium-based sidebar browser with Arc-style spaces and tabs";
    homepage = "https://ardia.dev/";
    license = lib.licenses.gpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "ardia";
  };
})
