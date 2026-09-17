# Battery level jumps after a trip through recovery

Parked investigation. The symptom is real and reproducible on V6: the reported
charge level jumps after rebooting into recovery and back into the system. The
mechanism is identified from dmesg; the proposed fix is untested.

## What actually happens

From dmesg on a recovery boot:

```
fg_check_bootmode: size:0x10 tag:0x41000802 bootmode:0x2 boottype:0x2
fg_swocv_v prop == NULL, len=0
fg_swocv_i prop == NULL, len=0
shutdown_time prop == NULL, len=0
fg_check_lk_swocv swocv_v:0 swocv_i:0 shutdown_time:0
fg_custom_init_from_dts swocv_v:39760 swocv_i:-22 shutdown_time:0
[fgr_dod_init]rtcui=0 case,init_swocv=39510,OCV_to_SOC_c=5722 ui:[5722 5722] con0_soc=[1 0]
```

Reading it in order:

- `bootmode:0x2` - recovery boot mode
- the bootloader passes **no** `fg_swocv_v`, `fg_swocv_i` or `shutdown_time`,
  which it does pass on a normal boot
- `rtcui=0` - the fuel gauge finds no saved UI charge level in the RTC, so it
  takes the `rtcui=0 case` branch: measure open-circuit voltage
  (`init_swocv=39510`, 3.951 V), convert to a percentage
  (`OCV_to_SOC_c=5722`) and declare the level to be 57.22%

So **every entry into recovery re-derives the charge level from voltage**.
Voltage is inflated while charging, so the estimate is off; back in Android the
system re-derives it again, and the user sees it move twice.

This is the bootloader plus the fuel-gauge driver, not the recovery GUI. Which
is why board flags cannot help - see the note at the end.

## Why a fix looks possible

`/sys/class/power_supply/battery/` on this device:

```
-r--r--r--  capacity    read-only, currently 85
--w-------  uisoc       WRITE-ONLY, root
```

`uisoc` is write-only: the driver exposes it deliberately as a setter for the
UI charge level. That is exactly the value missing when leaving recovery.

`/proc/mtk_battery_cmd/` holds only `current_cmd`, `en_power_path`,
`en_safety_timer`, `set_cv`; `/sys/kernel/debug/mtk_battery/` does not exist.
Do not touch `reset` in the sysfs directory - that resets the gauge.

## Proposed fix - no source patch needed

`TWFunc::tw_reboot()` already runs optional scripts before rebooting:

```cpp
check_and_run_script("/system/bin/rebootsystem.sh", "reboot system");
check_and_run_script("/system/bin/rebootrecovery.sh", "reboot recovery");
```

So this can be a file in the tree at `recovery/root/system/bin/rebootsystem.sh`:

```sh
#!/sbin/sh
cat /sys/class/power_supply/battery/capacity > /sys/class/power_supply/battery/uisoc
```

Revert by deleting the file. No patch, no C++.

## What is unproven

Writing `uisoc` sets the level inside the driver. Whether the driver then
persists it to the RTC - which is what `rtcui` reads on the next boot - is
unknown. One test settles it:

1. in recovery, write the value as above
2. reboot back into recovery
3. `dmesg | grep fgr_dod_init` - if `rtcui` is no longer 0, the mechanism works

If `rtcui` stays 0, the level is only persisted by the driver's own shutdown
path and this cannot be fixed from recovery at all.

## Ruled out

`TW_CUSTOM_BATTERY_PATH` and `OF_BATTERY_PATH`, which another fork added for
this, cannot affect any of the above:

- `TW_CUSTOM_BATTERY_PATH` is read in `twrp.cpp` only inside
  `#ifdef TW_USE_LEGACY_BATTERY_SERVICES`, which no tree here defines, so that
  code is compiled out. Its only live consumer is `TWFunc::Wait_For_Battery()`,
  whose `#else` default is already `/sys/class/power_supply/battery` - the same
  value.
- `OF_BATTERY_PATH` does not appear anywhere in the recovery sources or in the
  OrangeFox vendor build script. It is not a flag.

The displayed charge comes from `GetBatteryInfo()` via the health HAL, so a
path setting could not change it either way. If that fork's build really does
not show the jump, the credit belongs to its V7 kernel modules - every charger
and gauge module differs there, including `mt6358_battery.ko`, the gauge that
computes the percentage. Those cannot be transplanted: their vermagic is
`5.10.237-android12-9-g5ae907723135` against `5.10.218-android12-9-g21e1557e971d`
here, so they would refuse to load.
