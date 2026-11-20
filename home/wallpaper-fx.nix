{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: [ ps.numpy ps.pillow ]);
  helper = pkgs.writeShellScript "wallfx-map" ''
    exec ${python}/bin/python3 ${../dotfiles/bin/wallfx-map} "$@"
  '';
in {
  home.file.".local/bin/wallfx-map" = {
    source = helper;
    executable = true;
    force = true;
  };
}
