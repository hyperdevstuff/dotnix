{
  config,
  pkgs,
  lib,
  ...
}:

{
  # KDE reads the palette name from kdeglobals and the colors themselves from
  # the data dir. Both are read-only store links; Dolphin replaces them with
  # real files when it saves a setting, and the next activation restores them.
  xdg.configFile."kdeglobals".force = true;
  xdg.configFile."kdeglobals".source = ../dotfiles/kde/kdeglobals;
  xdg.dataFile."color-schemes/Dotnix.colors".source = ../dotfiles/kde/Dotnix.colors;

  xdg.configFile."dolphinrc".force = true;
  xdg.configFile."dolphinrc".source = ../dotfiles/kde/dolphinrc;

  # With global view properties Dolphin stores the layout in an xattr on
  # ~/.local/share/dolphin/view_properties/global, not in dolphinrc. Seed it
  # once so a fresh profile opens in the details view instead of the icon grid;
  # later changes (Ctrl+1..3) are kept because the seed only runs when the
  # attribute is absent.
  home.activation.dolphinViewProps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        view_dir="$HOME/.local/share/dolphin/view_properties/global"
        if [[ ! -d "$view_dir" ]]; then
          run mkdir -p "$view_dir"
        fi
        if ! ${pkgs.attr}/bin/getfattr -n user.kde.fm.viewproperties#1 "$view_dir" >/dev/null 2>&1; then
          view_props="$(cat <<'EOF'
    [Dolphin]
    Timestamp=2026,11,19,10,00,00.000
    Version=4
    ViewMode=1
    PreviewsShown=true
    GroupedSorting=false
    SortRole=text
    SortOrder=0
    SortFoldersFirst=true
    SortHiddenLast=false
    VisibleRoles=Details_text,Details_size,Details_modificationtime,CustomizedDetails

    [Settings]
    HiddenFilesShown=false
    EOF
    )"
          run ${pkgs.attr}/bin/setfattr -n user.kde.fm.viewproperties#1 -v "$view_props" "$view_dir"
        fi
  '';
}
