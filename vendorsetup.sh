#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2024-2025 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#
#set -o xtrace

FDEVICE="INOI_A75"

fetch_mt6789_common_repo() {
	local URL=https://github.com/tommynok/recovery_mt6789-common.git
	local common=device/alldocube/mt6789-common
	if [ ! -d $common ]; then
		echo "Cloning $URL ... to $common"
		git clone $URL -b main $common
	else
		echo "Device common repository: \"$common\" found ..."
	fi
}

# Clone to fix build on minimal manifest
if [ ! -d external/gflags ]; then
	git clone https://android.googlesource.com/platform/external/gflags/ -b android-12.1.0_r4 external/gflags
else
	echo "external/gflags already exists, skipping clone"
fi

# mt6789-common
fetch_mt6789_common_repo

# ccache
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_MAXSIZE="10G"
export CCACHE_DIR="$HOME/.ccache"
if [ ! -d ${CCACHE_DIR} ]; then
	mkdir $CCACHE_DIR
fi

# OrangeFox build vars
# official prebuilt zstd is v1.4.7 (2020): +20% backup time, worse ratio
# vs the manually shipped 1.5.x binary in the tree - keep disabled.
# FOX_USE_ZSTD_BINARY is dead in this CI pipeline anyway (our zstd is placed
# by hand at recovery/root/sbin/zstd); left =0 for clarity, do not set =1.
export FOX_USE_ZSTD_BINARY=0

# --- device identity / partitions (migrated from BoardConfigCommon.mk;
#     FOX_* must be shell exports, not .mk declarations) ---
# FOX_VIRTUAL_AB_DEVICE=1 auto-enables FOX_AB_DEVICE and FOX_VANILLA_BUILD,
# so those are not repeated here.
export FOX_VIRTUAL_AB_DEVICE=1
export FOX_ENABLE_APP_MANAGER=1
export FOX_RECOVERY_SYSTEM_PARTITION=/dev/block/mapper/system
export FOX_RECOVERY_VENDOR_PARTITION=/dev/block/mapper/vendor
export FOX_DELETE_AROMAFM=1

# --- shell / editor ---
export FOX_USE_BASH_SHELL=1
export FOX_ASH_IS_BASH=1
export FOX_USE_NANO_EDITOR=1

# --- bundled binaries ---
export FOX_USE_TAR_BINARY=1
export FOX_USE_LZ4_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_XZ_UTILS=1
# full GNU grep (~tiny) instead of toybox grep - toybox grep lacks -P and is
# flaky with -r; we grep constantly during on-device debugging.
export FOX_USE_GREP_BINARY=1
# prebuilt fsck.erofs (/sbin/fsck.erofs) - small; lets us fsck erofs images
# in recovery. Test on-device before relying on it.
export FOX_USE_FSCK_EROFS_BINARY=1

# Magisk: FOX_USE_SPECIFIC_MAGISK_ZIP was pointing at ~/Magisk/Magisk-v28.1.zip
# (a) it's FOX_* declared in .mk = wrong scope, (b) the path doesn't exist on
# the GitHub Actions runner, so it was a dead no-op. Removed. With it unset,
# the Fox Magisk addon menu offers the current bundled Magisk (30.6) at runtime,
# which is what we actually want. Do NOT re-add unless a specific pinned version
# is required AND the zip is fetched into the runner first.

# skip adopted-storage decryption on A12+; NOTE: only kicks in when the
export OF_SKIP_DECRYPTED_ADOPTED_STORAGE=1
# KernelSU install support in Fox Addons (device eligible: VirtualAB + GKI 5.10)
# ksud (~2.3mb) is shared; all three together cost ~3mb of ramdisk
export FOX_ENABLE_KERNELSU_SUPPORT=1
export FOX_ENABLE_KERNELSU_NEXT_SUPPORT=1
export FOX_ENABLE_SUKISU_SUPPORT=1

# FRP removal addon - EXPERIMENTAL. No-op unless device has a dedicated frp
# partition. INOI A75 partition table needs to be checked before relying on this.
export OF_ENABLE_FRP_ADDON=1

# UPX-compress executables >128kb in /sbin and /system/bin - EXPERIMENTAL.
# Risk: binaries invoked directly via GUI "cmd" actions (maintainer.xml) need
# instant exec; UPX adds a self-decompress step on every launch. Test each
# affected binary (zstd, par2turbo, ksud, busybox) individually before enabling
# broadly. maintainer.xml itself is not an executable and is unaffected.
export FOX_COMPRESS_EXECUTABLES=0
