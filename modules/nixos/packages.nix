{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btrfs-progs
    exfatprogs
    ntfs3g
    gptfdisk
    lm_sensors
    smartmontools
    nvme-cli
    nvtopPackages.nvidia
    git
    gh
    jq
    yq
  ];
}
