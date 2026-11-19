{ pkgs, config, ... }:

let
  # qmllint/qmlls need both the Qt module tree and Quickshell's own QML modules
  # on the import path. Both come from the same nixpkgs, so the Qt version
  # matches what the running shell links against.
  qtQml = "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml";
  quickshellQml = "${pkgs.quickshell}/lib/qt-6/qml";
in
{
  home.packages = with pkgs; [
    # Rust toolchain. rustfmt and clippy are the matching 1.99.0 components,
    # so `cargo fmt` / `cargo clippy` just work. Do not set RUST_SRC_PATH:
    # the nixpkgs rust-analyzer wrapper already points at rustPlatform.rustLibSrc.
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # JavaScript/TypeScript. nodejs ships npm and corepack.
    nodejs
    bun

    # node-gyp fallbacks for native addons. gcc is in home/default.nix and
    # cmake/ninja/pkg-config are system packages.
    python3
    gnumake

    # QML tooling: qml, qmllint, qmlls, qmlformat, qmlscene, qmltestrunner.
    # qtwayland adds the Wayland platform plugin so `qml`/`qmlscene` run
    # natively instead of falling back to xcb.
    qt6.qtdeclarative
    qt6.qtwayland
  ];

  home.sessionVariables = {
    # npm cannot write to the store, so global installs go to ~/.local
    # (already on sessionPath). Bun uses ~/.bun/bin, added below.
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
    NPM_CONFIG_PYTHON = "${pkgs.python3}/bin/python3";
    QML_IMPORT_PATH = "${qtQml}:${quickshellQml}";
    QML2_IMPORT_PATH = "${qtQml}:${quickshellQml}";
  };

  home.sessionPath = [ "${config.home.homeDirectory}/.bun/bin" ];
}
