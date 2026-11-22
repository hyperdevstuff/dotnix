{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  autoAddDriverRunpath,
  makeWrapper,
  symlinkJoin,
  alsa-lib,
  alsa-plugins,
  curl,
  ffmpeg-headless,
  fontconfig,
  libva,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxkbcommon,
  openssl,
  pipewire,
  vulkan-loader,
  wayland,
  wl-clipboard,
  wtype,
  xdg-utils,
}:

let
  alsaPluginDir = symlinkJoin {
    name = "hex-alsa-plugins";
    paths = [
      "${pipewire}/lib/alsa-lib"
      "${alsa-plugins}/lib/alsa-lib"
    ];
  };

  # The release loads these libraries dynamically for Wayland, X11 and Annotate.
  dynamicLibraries = [
    fontconfig
    libva
    libx11
    libxcb
    libxcursor
    libxi
    libxkbcommon
    pipewire
    wayland
  ];

  runtimePackages = [
    curl
    ffmpeg-headless
    wl-clipboard
    wtype
    xdg-utils
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hex-bin";
  version = "3.4.0";

  src = fetchurl {
    url = "https://github.com/anomalyco/hex/releases/download/v${finalAttrs.version}/hex-${finalAttrs.version}-linux-x64.deb";
    hash = "sha256-hibrpP9q/4cQYx5ex9mnFvMDBs/yaq2fG6ELLRcHp/c=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    autoAddDriverRunpath
    makeWrapper
  ];
  buildInputs = [
    alsa-lib
    libxkbcommon
    openssl
    stdenv.cc.cc.lib
    vulkan-loader
  ];

  preferLocalBuild = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar -xf -
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 usr/bin/hex "$out/bin/hex"
    cp -r usr/share "$out/share"
    substituteInPlace "$out/share/applications/anomaly.hex.desktop" \
      --replace-fail /usr/bin/hex "$out/bin/hex"
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram "$out/bin/hex" \
      --prefix PATH : ${lib.makeBinPath runtimePackages} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath dynamicLibraries} \
      --set ALSA_PLUGIN_DIR ${alsaPluginDir}
  '';

  meta = {
    description = "Local-first voice dictation";
    homepage = "https://anoma.ly/hex/";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "hex";
    platforms = [ "x86_64-linux" ];
  };
})
