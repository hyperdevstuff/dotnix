{
  age,
  lib,
  omp,
  pi-coding-agent,
  python3,
  sops,
  symlinkJoin,
  writeShellScriptBin,
}:

let
  secrets = writeShellScriptBin "inference-secrets" ''
    export PATH=${
      lib.makeBinPath [
        age
        sops
      ]
    }:"$PATH"
    exec ${lib.getExe python3} ${../scripts/inference-secrets.py} "$@"
  '';

  wrapAgent =
    name: executable:
    writeShellScriptBin name ''
      exec ${lib.getExe secrets} run ${name} ${executable} "$@"
    '';

  # Keep the currently installed OpenCode v2 build and its updater. The
  # wrapped entry point also covers `serve`, which T3 invokes directly.
  opencode = writeShellScriptBin "opencode" ''
    executable="$HOME/.opencode/bin/opencode"
    if [[ ! -x "$executable" ]]; then
      echo "OpenCode v2 is required at $executable" >&2
      exit 127
    fi
    exec ${lib.getExe secrets} run opencode "$executable" "$@"
  '';
in
symlinkJoin {
  name = "inference-tools";
  paths = [
    secrets
    (wrapAgent "pi" "${pi-coding-agent}/bin/pi")
    (wrapAgent "omp" "${omp}/bin/omp")
    opencode
    age
    sops
    pi-coding-agent
    omp
  ];
}
