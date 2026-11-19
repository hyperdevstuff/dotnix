{ config, pkgs, ... }:

let
  # Dolphin is the only KDE app here and NixOS does not run Plasma, so the KDE
  # platform theme and the Breeze widget style have to travel with its wrapper.
  # Without them Qt falls back to Fusion and never reads kdeglobals.
  dolphin = pkgs.kdePackages.dolphin.overrideAttrs (old: {
    qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
      "--set"
      "QT_QPA_PLATFORMTHEME"
      "kde"
      "--prefix"
      "QT_PLUGIN_PATH"
      ":"
      "${pkgs.kdePackages.plasma-integration}/lib/qt-6/plugins"
      "--prefix"
      "QT_PLUGIN_PATH"
      ":"
      "${pkgs.kdePackages.breeze}/lib/qt-6/plugins"
    ];
  });
in
{
  programs.niri = {
    enable = true;

    # Nautilus is only needed for the GNOME portal's file chooser.
    # We use the GTK portal instead, so skip the Nautilus closure.
    useNautilus = false;

    # Backport the upstream niri-session fix: `systemctl --user
    # import-environment` without a variable list is deprecated. Upstream
    # main replaced it with dbus-update-activation-environment --all.
    package = pkgs.niri.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace resources/niri-session \
          --replace-fail 'systemctl --user import-environment' \
            'dbus-update-activation-environment --systemd --all'
      '';
    });
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings.default_session = {
      # Use programs.niri.package (the patched derivation), not pkgs.niri,
      # otherwise the session bypasses the niri-session import-environment fix.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p' --greeting 'Welcome to nixos' --asterisks --remember --remember-user-session --cmd ${config.programs.niri.package}/bin/niri-session";
      user = "greeter";
    };
  };

  # niri's module enables the portal configuration, but its default backend
  # list also names "gtk"; make sure that backend is actually installed.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  security = {
    polkit.enable = true;
    rtkit.enable = true;

    # Native Quickshell lock screen uses a dedicated PAM service. swaylock is
    # still installed as a recovery fallback and keeps its own service.
    pam.services.quickshell = { };
    pam.services.swaylock = { };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  environment.systemPackages = with pkgs; [
    # Niri starts xwayland-satellite automatically when an X11 client needs it.
    xwayland-satellite
    foot
    kitty
    ghostty
    # KDE file manager, bound to Mod+E. Themed by home/dolphin.nix.
    dolphin
    swaybg
    swaylock
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    wl-mirror
    brightnessctl
    overskride
    playerctl
    pavucontrol
    networkmanagerapplet
    libnotify
    xdg-utils
    adwaita-icon-theme
    papirus-icon-theme
  ];
}
