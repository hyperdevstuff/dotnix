{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Dolphin's rc is a read-only store link. The palette lives in kdeglobals,
  # which matugen regenerates from the wallpaper, so it is a real file in the
  # home directory rather than a Home Manager symlink.
  xdg.configFile."dolphinrc".force = true;
  xdg.configFile."dolphinrc".source = ../dotfiles/kde/dolphinrc;

  # Replace an old store symlink (or a missing file) with the neutral seed
  # before the first `wp` run. A matugen-generated kdeglobals is left alone.
  home.activation.dolphinKdeGlobals = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.config/kdeglobals"
    if [[ -L "$target" || ! -f "$target" ]]; then
      run rm -f "$target"
      run cp ${../dotfiles/kde/kdeglobals} "$target"
      run chmod 644 "$target"
    fi
  '';

  # With global view properties Dolphin stores the layout in an xattr on
  # ~/.local/share/dolphin/view_properties/global, not in dolphinrc. Seed it
  # once so a fresh profile opens in the details view instead of the icon grid;
  # later changes (Ctrl+1..3) are kept because the seed only runs when the
  # attribute is absent.
  home.activation.dolphinViewProps = lib.hm.dag.entryAfter [ "dolphinKdeGlobals" ] ''
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
