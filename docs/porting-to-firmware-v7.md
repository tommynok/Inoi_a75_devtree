# Porting this tree to firmware V7

Notes taken from sysretq0's fork, which adapted this tree to the Indonesian
V7 firmware (`INOI_A750_ID_U_V7_20260822`) and fixed a real decryption bug
along the way. Written down here because a fork can disappear; everything below
is reproducible without it.

Source: https://github.com/sysretq0/inoi_a75_devtree, key commits
`bef6ab5` (the fix), `64fd09b`, `7922758`, `6643828`.

Nothing here is applied to this tree. Our V6 build works as it is, and the
identity and kernel modules below are V7-specific — copying them onto a V6
device would break a working build. This is a checklist for the day we move.

## The one part worth taking at any firmware version

`teed-init.sh` copies the TrustKernel device key into the recovery-only
directories that `teed` runs on (`init.tee.rc` starts it with
`--prot /mnt/vendor/persist/t6_rec --prot /mnt/vendor/protect_f/tee_rec`).
Without that copy, `teed` comes up without a device key, keymint cannot run the
operation, and a **correct** PIN is rejected — surfacing only as
`Begin Operation failed`, which is also what a wrong PIN produces.

The version in the common tree has one real weakness:

```sh
rm -rf  /mnt/vendor/persist/t6_rec/*        # destroys the copy first
cp -rfp /mnt/vendor/persist/t6/* /mnt/vendor/persist/t6_rec
```

It deletes the destination **before** checking the source at all, so a source
that is not mounted yet leaves nothing behind. That is a race, so it can come
and go between boots, and it produces exactly the symptom another builder
reported on V7: `t6` populated, `t6_rec` empty.

His replacement, placed in the **device** tree at
`recovery/root/vendor/bin/teed-init.sh` so it overrides the common one:

```sh
#!/sbin/sh

# Clone Trustkernel Device Keys for Decryption purposes
mkdir -p /mnt/vendor/persist/t6_rec /mnt/vendor/protect_f/tee_rec

if [ -d /mnt/vendor/persist/t6 ]; then
    cp -af /mnt/vendor/persist/t6/* /mnt/vendor/persist/t6_rec/ 2>/dev/null
    chown -R system:system /mnt/vendor/persist/t6_rec
    chmod -R 0700 /mnt/vendor/persist/t6_rec
fi

if [ -d /mnt/vendor/protect_f/tee ]; then
    cp -af /mnt/vendor/protect_f/tee/* /mnt/vendor/protect_f/tee_rec/ 2>/dev/null
    chown -R system:system /mnt/vendor/protect_f/tee_rec
    chmod -R 0700 /mnt/vendor/protect_f/tee_rec
fi
```

plus, in `recovery/root/init.device.rc`, an explicit invocation rather than
relying on the common tree's:

```
on post-fs
    exec u:r:recovery:s0 root root -- /vendor/bin/teed-init.sh
```

On this device `/mnt/vendor/protect_f/tee` is empty on both sides, so that half
is a no-op here — harmless, and correct to keep for devices where it is not.

### What we took and what we dropped

Only the source guard is worth taking. The `chown` and the `on post-fs` hook
were both tried here and both removed — see commit `84080bd` on the working
branch.

- **`chown -R system:system` does nothing.** init calls the script as user
  `system`, which cannot chown, so it fails silently on every boot.
- **It is not needed either.** Stock leaves the copies as `system root` and
  `teed` reads them, because `teed` runs as user `system` and the **owner**
  matches — the group is never consulted. Verified on a V6 device where
  decryption works: the gatekeeper diagnostics patch logs
  `credential accepted (code 0)` with the group still `root`:

```
/mnt/vendor/persist/t6/      drwx------ system system
/mnt/vendor/persist/t6_rec/  drwx------ system root
```

- **The `on post-fs` block existed only to give that chown root**, and it does
  not appear to fire in this recovery. With the script confirmed present on the
  device byte-for-byte, the group on `t6_rec` was still `root` afterwards and
  `dmesg | grep -i teed-init` returned nothing.
- **`chmod 0700` is kept**: `mkdir -p` creates the destination at 0755.

An earlier version of this file called the stock `system root` ownership
"accidental". That was a guess, and it was wrong — it is simply how stock
works.

## V7-specific changes — only when actually moving to V7

### Identity

`BoardConfig.mk`:

```make
TARGET_OTA_ASSERT_DEVICE := INOI_A75,A750,INOI_A75_Elegance,INOI_A750
TW_DEVICE_VERSION := INOI_A750_ID_U_V7_20260822
```

`twrp_INOI_A75.mk` — note he added BUILD_FINGERPRINT alongside the existing
PRIVATE_BUILD_DESC, and moved the incremental from 50327 to 60821:

```make
BUILD_FINGERPRINT="INOI/INOI_A75_Elegance/INOI_A75_Elegance:14/UP1A.231005.007/60821:user/release-keys" \
PRIVATE_BUILD_DESC="INOI/INOI_A75_Elegance/INOI_A75_Elegance:14/UP1A.231005.007/60821:user/release-keys"
```

`init/init_INOI_A75.cpp`:

```cpp
property_override("ro.build.display.id", "INOI_A750_ID_U_V7_20260822_user");
property_override("ro.build.description", "INOI_A750_ID_U_V7_20260822_user");
property_override("ro.build.version.incremental", "60821");
property_override("ro.build.fingerprint", "INOI/INOI_A75_Elegance/INOI_A75_Elegance:14/UP1A.231005.007/60821:user/release-keys");
```

The numbers are for the **ID** (Indonesian) V7 build. For a NEEA V7 they come
from that firmware's own `build.prop`, not from here.

### Dynamic partitions, read off lpdump of the target firmware

```make
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := sysretq0_dynamic_partitions
BOARD_SYSRETQ0_DYNAMIC_PARTITIONS_SIZE := 9661579264
BOARD_SYSRETQ0_DYNAMIC_PARTITIONS_PARTITION_LIST := \
    odm_dlkm product system system_ext vendor vendor_dlkm
```

Take the sizes from `lpdump` on the V7 firmware being targeted. The group name
is arbitrary; keep ours rather than his.

### Battery path

```make
override TW_CUSTOM_BATTERY_PATH := "/sys/class/power_supply/battery"
override OF_BATTERY_PATH := "/sys/class/power_supply/battery"
```

### Kernel modules

Every `.ko` under `recovery/root/lib/modules/` is replaced with the V7 set. Pull
them from the V7 firmware's `vendor_boot`/`vendor_dlkm`, not from his repo — his
are the ID V7 ones and the firmware is the authoritative source either way. He
also restored a `focaltech_tp` entry in `modules.dep`/`modules.alias` (`6643828`)
that had gone missing, so check the touch panel module is listed after swapping.

## What his fork does not carry

Worth knowing before taking anything wholesale — his tree has none of our work:

- no `patch-skip-data-fsck` (the 35 s fsck on every entry stays)
- no `patch-cap-persistent-log` (the log grows unbounded again)
- no `patch-boot-timing`
- `patch-partition-update_size-cache` left as `.diff.bak`, i.e. disabled
- the `TW_BACKUP_EXCLUSIONS` / `TW_ALLOW_INTERNAL_SELF_BACKUP` block is removed
  from `BoardConfig.mk`, so backing up Internal Storage onto itself does not
  work there

His CI commits (`ci: ...`, ~25 of them) are for building an unrelated ROM and
have nothing to do with recovery.
