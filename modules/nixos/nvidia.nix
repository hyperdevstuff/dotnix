{ ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # RTX 4050 (Ada) supports the open kernel modules.
    open = true;
    modesetting.enable = true;

    # nvidia-settings is X11-only and of little use on Wayland.
    nvidiaSettings = false;

    # Suspend/resume helpers can cause black screens on some laptops.
    # Enable these deliberately if suspend misbehaves.
    powerManagement.enable = false;
  };

  # Niri wiki: stop the driver hoarding VRAM in Wayland compositors.
  # https://github.com/YaLTeR/niri/wiki/Nvidia#high-vram-usage-fix
  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json".text =
    builtins.toJSON {
      rules = [
        {
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [
            {
              key = "GLVidHeapReuseRatio";
              value = 0;
            }
          ];
        }
      ];
    };
}
