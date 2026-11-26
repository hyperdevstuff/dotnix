{
  age,
  bun,
  lib,
  nodejs,
  python3,
  sops,
  symlinkJoin,
  util-linux,
  writeShellScriptBin,
}:

let
  installDir = "$HOME/.bun";

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
    name:
    writeShellScriptBin name ''
      executable="${installDir}/bin/${name}"
      if [[ ! -x "$executable" ]]; then
        echo '${name} is missing. Run agent-tools-update to install it.' >&2
        exit 127
      fi
      export PATH=${
        lib.makeBinPath [
          nodejs
          bun
        ]
      }:"$PATH"
      exec ${lib.optionalString (name != "codex") "${lib.getExe secrets} run ${name} "}"$executable" "$@"
    '';

  update = writeShellScriptBin "agent-tools-update" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [ nodejs ]}:"$PATH"
    mkdir -p "${installDir}"
    exec 9>"${installDir}/update.lock"
    ${lib.getExe' util-linux "flock"} -x 9

    ${lib.getExe bun} add --global --ignore-scripts \
      @openai/codex@latest @earendil-works/pi-coding-agent@latest @oh-my-pi/pi-coding-agent@latest
    # OpenCode's documented postinstall selects its published native binary.
    ${lib.getExe bun} add --global --trust @opencode/cli@latest
  '';
in
symlinkJoin {
  name = "inference-tools";
  paths = [
    secrets
    update
    age
    sops
  ]
  ++ map wrapAgent [
    "codex"
    "opencode"
    "omp"
    "pi"
  ];
}
