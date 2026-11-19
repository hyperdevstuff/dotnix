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

    # NVIDIA power management for suspend/resume. With the open modules and
    # driver 595+, NixOS defaults kernelSuspendNotifier = true, which sets
    # NVreg_UseKernelSuspendNotifiers=1 and NVreg_PreserveVideoMemoryAllocations=1
    # instead of installing the legacy nvidia-suspend/resume services.
    powerManagement.enable = true;

    # The driver saves the VRAM snapshot to NVreg_TemporaryFilePath (default
    # /tmp) on every suspend. /dev/shm is tmpfs and survives s2idle, so keep
    # the snapshot in RAM instead of writing it to disk.
    # Tradeoff: if a GPU workload ever allocates more than the free tmpfs
    # (currently ~5.8G), suspend may fail; remove this line if that happens.
    moduleParams.nvidia.NVreg_TemporaryFilePath = "/dev/shm";

    dynamicBoost.enable = true;
  };

  # This laptop's ACPI S3 (deep) path hard-hangs in the open NVIDIA driver's
  # device-suspend callbacks; the journal stops right after "OOM killer
  # disabled". s2idle is the recoverable sleep state on this hardware.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

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
