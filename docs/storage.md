# Storage (btrfs on the LOQ)

The machine has a single NVMe SSD:

| Partition | Size | Role |
| --- | --- | --- |
| `nvme0n1p1` | 200M | EFI system partition (vfat, mounted at `/boot`) |
| `nvme0n1p2` | 16M | not used by NixOS (do not touch) |
| `nvme0n1p3` | 251G | other OS partition, not used by NixOS (do not touch) |
| `nvme0n1p4` | 889M | not used by NixOS (do not touch) |
| `nvme0n1p5` | 224G | btrfs: NixOS root, `/home`, `/nix` |
| `nvme0n1p6` | 1G | not used by NixOS (do not touch) |

`nvme0n1p5` UUID: `f4968d5c-3b0d-46d0-a175-d2a522b6309d`
`nvme0n1p1` UUID: `0F56-6D60`

## What is configured now

The generated `/etc/fstab` contains exactly four entries:

```
UUID=f4968d5c-… /      btrfs x-initrd.mount
UUID=0F56-6D60  /boot  vfat  fmask=0077,dmask=0077
UUID=f4968d5c-… /home  btrfs subvol=home
UUID=f4968d5c-… /nix   btrfs x-initrd.mount,subvol=nix
```

So the on-disk layout is:

| Mount | Subvolume | Notes |
| --- | --- | --- |
| `/` | top-level (id 5) | no `subvol=` option |
| `/home` | `home` | separate, correct |
| `/nix` | `nix` | separate, correct |
| `/var` | — | a plain directory on the top-level root |
| `/boot` | — | vfat, separate |

## Verdict

The system **boots and works**. The `home` and `nix` subvolumes are correct and
useful: `/nix` stays out of root snapshots, and `/home` can be snapshotted
independently.

It is **not the recommended layout**, though:

1. **The root is the top-level subvolume (id 5), not a named subvolume.** A
   snapshot of `/` would have to live inside the subvolume it snapshots, and
   rolling back means pointing the root mount at the snapshot. That works, but
   it is awkward and there is no `@` / `@snapshots` convention for tooling to
   follow.
2. **`/var` is not isolated.** Logs, caches, systemd state and databases live
   in the root, so every root snapshot diverges immediately and rollback can
   lose or corrupt state.
3. **No `@snapshots` subvolume**, and no snapshot tooling (NixOS generations
   already roll back the *system*, but not user data or `/var`).
4. The subvolume names `home` / `nix` are non-standard (`@home` / `@nix` is the
   convention), but this is cosmetic. Leave them as they are: renaming a
   mounted subvolume is impossible, and renaming it while the current
   generation still references `subvol=home` makes the next boot fail.
5. Mount options were the defaults: no compression, `relatime`, no explicit
   discard. These are now set in `hosts/LOQ/storage.nix` (see below).

## Applied settings

`hosts/LOQ/storage.nix` appends these options to `/`, `/home` and `/nix`:

```
ssd,discard=async,noatime,compress=zstd:3
```

- `ssd` / `discard=async` are already detected/enabled by btrfs on this device;
  stating them keeps the intent explicit.
- `noatime` avoids atime writeback. `relatime` (the previous default) still
  writes on the first read after a file changes.
- `compress=zstd:3` is the normal btrfs default level. It only affects newly
  written data; existing extents are not rewritten.
- `autodefrag` is deliberately **not** used: it is an HDD optimisation and
  increases write amplification on SSDs.
- `services.btrfs.autoScrub` runs a monthly scrub. On a single device it cannot
  repair checksum mismatches, but it reports them before they spread.
- `services.fstrim` stays on for the vfat `/boot` partition. The btrfs
  filesystems already discard asynchronously, so their pass is redundant.

Rebuild and reboot for the mount options to take effect:

```bash
sudo nixos-rebuild boot --flake ~/dotnix#LOQ
sudo reboot
findmnt -no SOURCE,FSTYPE,OPTIONS /
```

## Migrating to the `@` layout (offline, live USB)

This is optional but recommended. It cannot be done from the running system:
the top-level subvolume cannot be renamed, and you cannot switch the root
subvolume while it is mounted.

**Back up anything you cannot lose first.** The steps below are atomic on
btrfs, but they change the root the firmware boots into.

### 1. Boot a NixOS live USB

Make sure the installed system is **not** mounted (`lsblk`, `findmnt`). Then
mount the top-level subvolume of the btrfs partition:

```bash
sudo mount -o subvolid=5 /dev/disk/by-uuid/f4968d5c-3b0d-46d0-a175-d2a522b6309d /mnt
sudo btrfs subvolume list /mnt
```

You should see at least `home` and `nix`.

### 2. Create `@` as a snapshot of the current root

```bash
sudo btrfs subvolume snapshot /mnt /mnt/@
sudo btrfs subvolume create /mnt/@snapshots
sudo mkdir -p /mnt/@/.snapshots
sudo btrfs subvolume list /mnt
sudo ls /mnt/@
```

A snapshot is instant, atomic and cheap: it shares extents copy-on-write. It
contains the root filesystem but **not** the contents of the nested `home` and
`nix` subvolumes — those appear as empty mount-point directories, which is
exactly what you want, because fstab mounts `subvol=home` and `subvol=nix` over
them.

If your `btrfs-progs` refuses to snapshot the top-level subvolume, use a copy
instead. The excludes are required: subvolumes share the same device, so
`rsync -x` alone would still descend into `home` and `nix`.

```bash
sudo btrfs subvolume create /mnt/@
sudo rsync -aHAXSx --info=progress2 \
  --exclude=/@ --exclude=/lost+found \
  --exclude=/home/* --exclude=/nix/* --exclude=/boot/* \
  --exclude=/proc/* --exclude=/sys/* --exclude=/dev/* \
  --exclude=/run/* --exclude=/tmp/* --exclude=/mnt/* \
  /mnt/ /mnt/@/
sudo btrfs subvolume create /mnt/@snapshots
sudo mkdir -p /mnt/@/.snapshots
```

### 3. Optional: isolate `/var`

Still in the same live-USB session, with the installed system unmounted:

```bash
sudo btrfs subvolume create /mnt/@var
sudo cp -a --reflink=auto /mnt/var/. /mnt/@var/
```

Leave `/mnt/@/var` untouched for now. It is the copy inside `@` and acts as a
fallback if the new mount ever fails; it becomes hidden once `subvol=@var` is
mounted. You can empty it after verifying the boot (step 5).

### 4. Unmount and boot the installed system

```bash
sync
sudo umount /mnt
```

The current generation still mounts the top-level root, so it boots as before.
`@` simply appears as `/@`.

### 5. Point the root at `@`

Add `subvol=@` to the root options in `hosts/LOQ/storage.nix` (keep the
generated `hardware-configuration.nix` as-is). If you prepared `@var` or
`@snapshots`, add those mounts in the same edit so one reboot applies
everything:

```nix
fileSystems."/".options = lib.mkAfter ([ "subvol=@" ] ++ ssdOptions);

# only if you created @var in step 3
fileSystems."/var" = {
  device = "/dev/disk/by-uuid/f4968d5c-3b0d-46d0-a175-d2a522b6309d";
  fsType = "btrfs";
  options = [ "subvol=@var" ] ++ ssdOptions;
};

# only if you want the snapshot mount
fileSystems."/.snapshots" = {
  device = "/dev/disk/by-uuid/f4968d5c-3b0d-46d0-a175-d2a522b6309d";
  fsType = "btrfs";
  options = [ "subvol=@snapshots" ] ++ ssdOptions;
};
```

The other mounts already carry their `subvol=` option, so they are unchanged.
Then build the next generation and reboot:

```bash
sudo nixos-rebuild boot --flake ~/dotnix#LOQ
sudo reboot
```

Verify:

```bash
findmnt -no SOURCE,OPTIONS /
# … subvol=/@ …
sudo btrfs subvolume show / | head
findmnt /var 2>/dev/null || true
```

`/home` and `/nix` keep their existing names and mount correctly. The old
top-level root still exists underneath and is no longer mounted (except as the
parent of `@`, `home`, `nix`, `@snapshots`, `@var`).

Once `findmnt /var` shows `subvol=/@var`, reclaim the fallback copy:

```bash
sudo mkdir -p /run/btrfs-top
sudo mount -o subvolid=5 /dev/disk/by-uuid/f4968d5c-3b0d-46d0-a175-d2a522b6309d /run/btrfs-top
sudo find /run/btrfs-top/@/var -mindepth 1 -delete
sudo umount /run/btrfs-top
```

The live `/var` is the mounted `@var` subvolume, so this only deletes the
hidden stale copy inside `@`.

### 6. Optional: snapshots

With `/` on `@` and `/.snapshots` on its own subvolume, root snapshots are
cheap and do not recurse into themselves:

```bash
sudo btrfs subvolume snapshot -r / /.snapshots/root-$(date +%F)
sudo btrfs subvolume list /
```

NixOS generations and btrfs snapshots solve different problems: generations
roll back the system closure, snapshots roll back the filesystem. A snapshot
manager (snapper, timeshift) is not installed; plain `btrfs subvolume snapshot`
is enough unless you want automatic retention.

## Rollback

If the machine does not reach the login screen after switching to `subvol=@`:

1. At the systemd-boot menu, choose the previous NixOS generation. Its initrd
   still mounts the top-level root, so it boots the old layout.
2. From that generation, remove `subvol=@` (and the `@var` / `@snapshots`
   entries if you added them) from `hosts/LOQ/storage.nix`, then run
   `sudo nixos-rebuild boot --flake ~/dotnix#LOQ` again.
3. Delete `@` only once you are sure you no longer need it
   (`sudo btrfs subvolume delete /mnt/@` from the live USB).

Do not delete the top-level subvolume (id 5); btrfs does not allow it, and it
is the parent of everything else.

## Checking health

```bash
sudo btrfs filesystem usage /
sudo btrfs device stats /
sudo btrfs scrub status /
sudo smartctl -a /dev/nvme0n1
```

`btrfs device stats` should stay at zero for `read`, `write`, `flush` and
`corruption` errors. `smartctl` reports the SSD's own wear and error counters.
