{ pkgs, ... }:

let
  # The tagged release is a Python script and SVG assets. Copy them verbatim
  # and give the script the Nix Python interpreter.
  iconsSource = pkgs.fetchurl {
    url = "https://codeload.github.com/duxlabs-dev/dux-icons/tar.gz/refs/tags/v0.2.0";
    hash = "sha256-x8Grfj42d9vRKDXpeSjjF6NsWVU61M42SiQu5m5qnxM=";
  };
  icons = pkgs.runCommandLocal "dux-icons-0.2.0" { } ''
    tar -xf ${iconsSource} --strip-components=1
    install -Dm755 scripts/build.py "$out/share/dux-icons/scripts/build.py"
    install -Dm644 index.theme.in "$out/share/dux-icons/index.theme.in"
    cp -R src "$out/share/dux-icons/src"
    install -Dm644 LICENSE "$out/share/licenses/dux-icons/LICENSE"
    install -Dm644 NOTICE "$out/share/licenses/dux-icons/NOTICE"
    substituteInPlace "$out/share/dux-icons/scripts/build.py" \
      --replace-fail '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
    mkdir -p "$out/bin"
    ln -s ../share/dux-icons/scripts/build.py "$out/bin/dux-icons"
  '';
  trialTheme = "Dux-Trial";
  refreshIcons = pkgs.writeShellScriptBin "dux-files-refresh-icons" ''
    generated="''${XDG_CONFIG_HOME:-$HOME/.config}/matugen/generated"
    iconDir="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/${trialTheme}"
    colors=()
    if [[ -r "$generated/mode" && -r "$generated/notchd-colors.json" ]]; then
      mode=$(<"$generated/mode")
      if palette=$(${pkgs.jq}/bin/jq -cer --arg mode "$mode" '
        .[$mode] | [.primary, .on_primary] |
        select(all(.[]; type == "string" and test("^#[0-9a-fA-F]{6}$")))
      ' "$generated/notchd-colors.json"); then
        tile=$(${pkgs.jq}/bin/jq -r '.[0]' <<< "$palette")
        glyph=$(${pkgs.jq}/bin/jq -r '.[1]' <<< "$palette")
        colors=(--tile "$tile" --glyph "$glyph")
      fi
    fi
    exec ${icons}/bin/dux-icons --out "$iconDir" --name 'Dux Icons (trial)' --shape squircle "''${colors[@]}"
  '';
  launcher = pkgs.writeShellScriptBin "dfiles" ''
    settings="''${XDG_CONFIG_HOME:-$HOME/.config}/dfiles/ui-settings.json"
    if [[ ! -e "$settings" ]]; then
      mkdir -p "$(dirname "$settings")"
      (umask 077; set -o noclobber; printf '%s\n' '{"registerFileManager":false}' > "$settings")
    fi
    iconDir="''${XDG_DATA_HOME:-$HOME/.local/share}/icons/${trialTheme}"
    if [[ ! -r "$iconDir/index.theme" ]]; then
      ${refreshIcons}/bin/dux-files-refresh-icons >&2 || true
    fi
    if [[ -r "$iconDir/index.theme" ]]; then
      export QS_ICON_THEME=${trialTheme}
    fi
    exec ${pkgs.dux-files}/bin/dfiles "$@"
  '';
in
{
  # Only publish the launcher and its app icon for the trial. The stock Dux
  # package also contains session file-manager and file chooser activation files.
  home.file.".local/bin/dfiles".source = "${launcher}/bin/dfiles";
  home.file.".local/bin/dux-icons".source = "${icons}/bin/dux-icons";
  home.file.".local/bin/dux-files-refresh-icons".source = "${refreshIcons}/bin/dux-files-refresh-icons";
  xdg.dataFile."applications/dev.duxlabs.files.desktop".source = "${pkgs.makeDesktopItem {
    name = "dev.duxlabs.files";
    desktopName = "Dux Files";
    genericName = "File Manager";
    exec = "${launcher}/bin/dfiles open %U";
    icon = "dev.duxlabs.files";
    categories = [ "System" "FileManager" ];
  }}/share/applications/dev.duxlabs.files.desktop";
  xdg.dataFile."icons/hicolor/scalable/apps/dev.duxlabs.files.svg".source =
    "${pkgs.dux-files}/share/icons/hicolor/scalable/apps/dev.duxlabs.files.svg";
}
