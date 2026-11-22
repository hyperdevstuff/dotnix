{ config, pkgs, ... }:

let
  # Apply the session fix to the launcher while using the cached compositor.
  niriSession = pkgs.runCommandLocal "niri-session" { } ''
    mkdir -p "$out/bin"
    substitute ${config.programs.niri.package}/bin/niri-session "$out/bin/niri-session" \
      --replace-warn 'systemctl --user import-environment' \
        '${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all'
    chmod +x "$out/bin/niri-session"
  '';

  # Load KDE's platform theme and Breeze alongside the cached Dolphin binary.
  kde = pkgs.kdePackages;
  dolphin = pkgs.symlinkJoin {
    name = "dolphin-themed";
    paths = [ kde.dolphin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/dolphin"
      makeWrapper ${kde.dolphin}/bin/dolphin "$out/bin/dolphin" \
        --set QT_QPA_PLATFORMTHEME kde \
        --prefix QT_PLUGIN_PATH : ${kde.plasma-integration}/lib/qt-6/plugins \
        --prefix QT_PLUGIN_PATH : ${kde.breeze}/lib/qt-6/plugins

      for service in share/dbus-1/services/org.kde.dolphin.FileManager1.service \
                     share/systemd/user/plasma-dolphin.service; do
        rm "$out/$service"
        substitute "${kde.dolphin}/$service" "$out/$service" \
          --replace-fail "${kde.dolphin}/bin/dolphin" "$out/bin/dolphin"
      done
    '';
  };
in
{
  programs.niri = {
    enable = true;

    # Nautilus is only needed for the GNOME portal's file chooser.
    # We use the GTK portal instead, so skip the Nautilus closure.
    useNautilus = false;
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p' --greeting 'Welcome to nixos' --asterisks --remember --remember-user-session --cmd ${niriSession}/bin/niri-session";
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
    # Launch JACK clients with pw-jack to load the PipeWire JACK libraries.
    config.services.pipewire.package.jack
    # Resolve niri-session to the same launcher from the greeter and the profile.
    (lib.hiPrio niriSession)
    # Niri starts xwayland-satellite automatically when an X11 client needs it.
    xwayland-satellite
    foot
    kitty
    ghostty
    # KDE file manager, available on Mod+Alt+E during the Dux Files trial.
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
