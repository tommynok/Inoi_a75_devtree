#
# Copyright (C) 2022 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/inoi/INOI_A75

# Inherit from mt6789-common
include device/alldocube/mt6789-common/BoardConfigCommon.mk

# Assert
TARGET_OTA_ASSERT_DEVICE := INOI_A75,A750,INOI_A75_Elegance

# Init
TARGET_INIT_VENDOR_LIB := libinit_INOI_A75
TARGET_RECOVERY_DEVICE_MODULES := libinit_INOI_A75

# TWRP Configs
TW_DEVICE_VERSION := INOI_A75_NEEA_U_V6_20250828


# Device Resolution
override TARGET_SCREEN_WIDTH := 1080
override TARGET_SCREEN_HEIGHT := 2460
override OF_SCREEN_H := 2460

# Language test
#override TW_DEFAULT_LANGUAGE := ru
# override TW_DEFAULT_LANGUAGE := en   # fallback, если ru не найдётся при сборке

# Statusbar
override TW_STATUS_ICONS_ALIGN := center
override TW_CUSTOM_CPU_POS := "300"
override TW_CUSTOM_CLOCK_POS := "70"
override TW_CUSTOM_BATTERY_POS := "790"

# CPU Temp
override TW_CUSTOM_CPU_TEMP_PATH := /sys/devices/virtual/thermal/thermal_zone25/temp

# Brightness
override TW_DEFAULT_BRIGHTNESS := 102
override TW_MAX_BRIGHTNESS := 255

# Backup exclusions
# Comma-separated absolute paths, consumed by TW_BACKUP_EXCLUSIONS in
# bootable/recovery (partition.cpp, "board-customisable exclusions").
#
# /data/media is already excluded from the /data backup wholesale
# (ExcludeAll(Mount_Point + "/media")), so this changes nothing there. It
# matters for the /storage bind mount added in the common tree's twrp.flags,
# which backs up internal storage as its own entry: without this, every
# previous OrangeFox backup (~25 GiB here) is dragged into the new one.
TW_BACKUP_EXCLUSIONS := /data/media/0/Fox
