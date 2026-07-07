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
	local URL=https://github.com/tommynok/recovery-device_alldocube_mt6789-common.git
	local common=device/alldocube/mt6789-common
	if [ ! -d $common ]; then
		echo "Cloning $URL ... to $common"
		git clone $URL -b twrp-12.1 $common
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
export CCACHE_DIR=".ccache"
if [ ! -d ${CCACHE_DIR} ]; then
	mkdir $CCACHE_DIR
fi
