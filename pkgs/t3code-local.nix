{
  appimage-run,
  gh,
  git,
  lib,
  writeShellScriptBin,
}:

writeShellScriptBin "t3code" ''
  image="$HOME/.local/opt/t3code/T3-Code-Nightly.AppImage"
  if [[ ! -x "$image" ]]; then
    echo "Install the official T3 Code Nightly AppImage at $image" >&2
    exit 127
  fi

  export PATH="$HOME/.local/bin:$HOME/.bun/bin:${
    lib.makeBinPath [
      gh
      git
    ]
  }:$PATH"
  export T3CODE_TELEMETRY_ENABLED=false
  export T3CODE_OTEL_SDK_DISABLED=true
  export T3CODE_DESKTOP_LAUNCHER_PATH="$HOME/.local/bin/t3code"
  exec ${lib.getExe appimage-run} "$image" "$@"
''
