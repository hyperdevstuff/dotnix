{
  lib,
  ...
}:

let
  # The system disk is an NVMe SSD (SOLIDIGM SSDPFINW512GZL, nvme0n1p5).
  # btrfs enables SSD mode, async discard and space_cache=v2 automatically on
  # non-rotational devices, but writing them down keeps the intent clear and
  # survives a device that misreports its rotational flag.
  #
  # Do NOT add `autodefrag`: it is an HDD optimisation and increases write
  # amplification on SSDs. `compress=zstd:3` is the normal default level, and
  # `noatime` avoids atime writeback without changing application behaviour
  # (relatime, the previous default, still writes on the first read).
  ssdOptions = [
    "ssd"
    "discard=async"
    "noatime"
    "compress=zstd:3"
  ];
in
{
  fileSystems."/".options = lib.mkAfter ssdOptions;
  fileSystems."/home".options = lib.mkAfter ssdOptions;
  fileSystems."/nix".options = lib.mkAfter ssdOptions;

  # Scrub reads every block and repairs it from a copy if checksums disagree.
  # On a single-device btrfs it cannot repair, but it still surfaces bit rot
  # early. Monthly is the usual desktop cadence.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # `fstrim.timer` stays enabled for the vfat /boot partition. The btrfs
  # filesystems already issue discards asynchronously (`discard=async`), so
  # the timer's btrfs pass is a no-op; it is not harmful, just redundant.
  #
  # Current layout on this disk (from /etc/fstab and /proc/mounts):
  #
  #   /      top-level btrfs subvolume (subvolid 5), no `subvol=` option
  #   /home  subvol=home
  #   /nix   subvol=nix
  #   /var   not isolated; it is a directory on the top-level root
  #
  # That boots and runs, but the root is not a named subvolume, so root
  # snapshots/rollbacks are awkward and /var (logs, caches, databases) shares
  # the root. The recommended layout is:
  #
  #   /      subvol=@
  #   /home  subvol=home       (or @home)
  #   /nix   subvol=nix        (or @nix)
  #   /var   subvol=@var       (optional but recommended)
  #   /.snapshots  a separate subvolume for snapshots
  #
  # Do NOT add `subvol=@` here before that subvolume exists: the initrd will
  # not find the root and the machine drops to an emergency shell. The move is
  # an offline migration from a live USB, not a config-only change. The exact
  # commands, verification and rollback steps are in docs/storage.md.
}
