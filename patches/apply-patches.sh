#!/bin/bash
# Slim OrangeFox theme: remove unused fonts and all languages except en/ru.
# Usage: apply-patches.sh <fox_source_root>   (e.g. .../workspace/fox_12.1)
# Runs after source sync, before build. Deletes files only - never touches
# ui.xml or theme structure (theme version mismatch => GUI bootloop).
set -e
FOX="$1"
if [ -z "$FOX" ] || [ ! -d "$FOX/bootable/recovery/gui" ]; then
    echo "ERROR: pass fox source root as arg1 (got: '$FOX')"
    exit 1
fi
GUI="$FOX/bootable/recovery/gui"
PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 0. Fix DT2W wake-from-blanked-screen bug in gui.cpp ---
# Upstream InputHandler::processInput() only calls resetTimerAndUnblank()
# while the screen is NOT already off, so a KEY_WAKEUP event from a
# double-tap-to-wake gesture driver can never turn the screen back on.
# This patch adds an explicit exception for KEY_WAKEUP while blanked.
GUI_WAKE_PATCH="$PATCH_DIR/patch-gui-keywakeup-fox_12.1.diff"
echo "=== Applying KEY_WAKEUP unblank fix ==="
if [ ! -f "$GUI_WAKE_PATCH" ]; then
    echo "WARNING: $GUI_WAKE_PATCH not found, skipping KEY_WAKEUP fix"
elif patch -p1 --dry-run -d "$FOX/bootable/recovery" < "$GUI_WAKE_PATCH" > /dev/null 2>&1; then
    patch -p1 -d "$FOX/bootable/recovery" < "$GUI_WAKE_PATCH"
    echo "KEY_WAKEUP patch applied successfully"
else
    echo "WARNING: KEY_WAKEUP patch failed dry-run (gui.cpp upstream context may have changed) - skipping, build continues"
fi

echo "=== Theme slimming: start ==="
echo "GUI dir size before:"
du -sh "$GUI"

# --- 1. Fonts: delete-list (verified unused, 0 references in theme XML) ---
# Roboto* and GoogleSans* are BOTH required (different UI layers) - never touch.
# NOTE: FiraCode-Medium is NOT dead despite 0 static refs in theme XML:
# the font picker writes /sdcard/Fox/.theme/font.xml referencing <Name>-Medium.ttf
# dynamically; deleting it bootloops the GUI if the user ever picks FiraCode.
DEAD_FONTS="DroidSansFallback.ttf NotoSansCJKjp-Regular.ttf Chococooky.ttf ae_Cortoba.ttf Roboto-Spanish.ttf"
for f in $DEAD_FONTS; do
    found=$(find "$GUI" -type f -name "$f")
    if [ -n "$found" ]; then
        echo "$found" | while read -r p; do
            echo "DEL font: $p ($(stat -c%s "$p") bytes)"
            rm -f "$p"
        done
    else
        echo "skip (not found): $f"
    fi
done

# --- 2. Languages: keep-list (en + ru), delete the rest ---
KEEP="en.xml ru.xml"
find "$GUI" -type d -name "languages" | while read -r d; do
    echo "languages dir: $d"
    for x in "$d"/*.xml; do
        [ -e "$x" ] || continue
        base=$(basename "$x")
        keep=0
        for k in $KEEP; do
            if [ "$base" = "$k" ]; then keep=1; fi
        done
        if [ "$keep" = "1" ]; then
            echo "KEEP lang: $x"
        else
            echo "DEL  lang: $x ($(stat -c%s "$x") bytes)"
            rm -f "$x"
        fi
    done
done

# --- 3. Sanity: en.xml must survive somewhere, warn if ru.xml absent ---
if [ -z "$(find "$GUI" -path '*languages*' -name 'en.xml')" ]; then
    echo "ERROR: en.xml missing after cleanup - aborting build"
    exit 1
fi
if [ -z "$(find "$GUI" -path '*languages*' -name 'ru.xml')" ]; then
    echo "WARNING: ru.xml not found in source theme - build will be English-only"
fi

echo "GUI dir size after:"
du -sh "$GUI"
echo "=== Theme slimming: done ==="
