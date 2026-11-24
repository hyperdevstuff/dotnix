{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:

# Google's Antigravity ACP agent, the runtime T3 Code's Antigravity provider
# drives. This is *not* the Antigravity IDE or the interactive `agy` CLI: T3
# spawns `agy_acp_server.par` over stdio and points it at the
# `localharness_external` helper in the same directory.
#
# Registry: https://github.com/agentclientprotocol/registry/blob/main/antigravity-acp/agent.json
stdenv.mkDerivation (finalAttrs: {
  pname = "antigravity-acp";
  version = "1.5.2";

  src = fetchurl {
    url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-${finalAttrs.version}-linux-x86_64.zip";
    hash = "sha256-md2GEkUIBQEWGde4RHzjdMKJ4AVJ2FV/NnkOHdYlaFI=";
  };

  nativeBuildInputs = [
    unzip
    autoPatchelfHook
  ];

  # The distribution is a plain zip holding two executables; there is no
  # build system to run.
  unpackPhase = ''
    unzip -q $src
  '';

  # Both files must stay siblings at the same version: T3 resolves the harness
  # from the ACP executable's directory.
  installPhase = ''
    install -Dm755 agy_acp_server.par \
      $out/libexec/antigravity-acp/agy_acp_server.par
    install -Dm755 localharness_external \
      $out/libexec/antigravity-acp/localharness_external

    # T3 discovers `agy_acp_server.par` on PATH, then follows the symlink to
    # find localharness_external next to the real file.
    mkdir -p $out/bin
    ln -s $out/libexec/antigravity-acp/agy_acp_server.par $out/bin/agy_acp_server.par
  '';

  # agy_acp_server.par is a 800+ MiB PyInstaller archive with debug info.
  # Stripping it is slow and can break the appended archive.
  dontStrip = true;

  meta = {
    description = "Google Antigravity ACP agent runtime for T3 Code";
    homepage = "https://antigravity.google/docs/ide/extensions";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
