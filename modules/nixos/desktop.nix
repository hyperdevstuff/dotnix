{ pkgs, ... }:

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
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p' --greeting 'Welcome to nixos' --asterisks --remember --remember-user-session --cmd ${pkgs.niri}/bin/niri-session";
      user = "greeter";
    };
  };

  # niri's module enables the portal configuration, but its default backend
  # list also names "gtk"; make sure that backend is actually installed.
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  security = {
    polkit.enable = true;
    rtkit.enable = true;

    # swaylock needs a PAM service to be able to unlock the session.
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
    swaybg
    swaylock
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    brightnessctl
    playerctl
    pavucontrol
    networkmanagerapplet
    libnotify
    xdg-utils
    adwaita-icon-theme
    papirus-icon-theme
  ];
}
