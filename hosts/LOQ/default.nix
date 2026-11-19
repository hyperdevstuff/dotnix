{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./storage.nix
    ../../modules/nixos/base.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/packages.nix
  ];

  networking.hostName = "LOQ";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # The SPD5118 RAM temperature sensor fails to resume on this laptop
  # ("spd5118 0-0050: PM: dpm_run_callback(): spd5118_resume [spd5118]
  # returns -6") and adds several seconds to every resume. It is only a
  # monitoring sensor, so keep the driver from binding.
  boot.blacklistedKernelModules = [ "spd5118" ];

  # The built-in AT keyboard hangs off i8042/serio0, whose wakeup source is
  # disabled by default; only the USB (ITE) keyboard and the power button
  # could wake the machine. Enable serio0 so any built-in key wakes it.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="serio", KERNEL=="serio0", ATTR{power/wakeup}="enabled"
  '';

  # The NTFS data disk that held the music library is not attached to this
  # fresh install, so the mount is disabled for now. Re-enable this block
  # (and home/music.nix plus the music aliases in home/shell.nix) after
  # verifying the disk's UUID with `lsblk -f`:
  #
  #   fileSystems."/mnt/library" = {
  #     device = "/dev/disk/by-uuid/DE5E56785E564A03";
  #     fsType = "ntfs3";
  #     options = [
  #       "nofail"
  #       "noauto"
  #       "x-systemd.automount"
  #       "x-systemd.idle-timeout=15min"
  #       "uid=1000"
  #       "gid=100"
  #       "iocharset=utf8"
  #       "umask=0022"
  #     ];
  #   };

  time.timeZone = "Asia/Kolkata";

  # Use the UTF-8 locale explicitly. Bare "en_IN" resolves to
  # en_IN.ISO8859-1, which makes xkbcommon, fuzzel and Hex fail to find a
  # compose file ("No Compose file for locale en_IN.ISO8859-1").
  i18n.defaultLocale = "en_IN.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN.UTF-8";
    LC_IDENTIFICATION = "en_IN.UTF-8";
    LC_MEASUREMENT = "en_IN.UTF-8";
    LC_MONETARY = "en_IN.UTF-8";
    LC_NAME = "en_IN.UTF-8";
    LC_NUMERIC = "en_IN.UTF-8";
    LC_PAPER = "en_IN.UTF-8";
    LC_TELEPHONE = "en_IN.UTF-8";
    LC_TIME = "en_IN.UTF-8";
  };

  # glibc's locale list spells this one "en_IN/UTF-8" (no dot); the NixOS
  # module appends "/UTF-8" to defaultLocale, so the derived list contains
  # "en_IN.UTF-8/UTF-8", which glibc rejects. Build the archive explicitly
  # from glibc's own names — it still exposes the en_IN.UTF-8 alias at
  # runtime, which is what LANG uses.
  i18n.glibcLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "en_IN/UTF-8"
    ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users.${username} = {
    isNormalUser = true;
    description = "Hyper";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
      "input"
      "audio"
    ];
    shell = pkgs.fish;
  };

  system.stateVersion = "26.05";
}
