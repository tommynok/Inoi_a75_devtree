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

echo "=== Theme slimming: start ==="
echo "GUI dir size before:"
du -sh "$GUI"

# --- 1. Fonts: delete-list (verified unused, 0 references in theme XML) ---
# Roboto* and GoogleSans* are BOTH required (different UI layers) - never touch.
DEAD_FONTS="DroidSansFallback.ttf NotoSansCJKjp-Regular.ttf Chococooky.ttf ae_Cortoba.ttf Roboto-Spanish.ttf FiraCode-Medium.ttf"
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

# --- 1b. Clone light fonts over heavy picker fonts (same filenames) ---
# Theme references filenames only; GoogleSans is a core UI font (Cyrillic guaranteed).
# Regular replaces Regular, Medium replaces Medium. Fully skipped if donor absent.
# To undo this trick: delete/comment this whole block (nothing else refers to it).
FDIR="$(dirname "$(find "$GUI" -name 'GoogleSans-Regular.ttf' | head -n1)")"
if [ -n "$FDIR" ] && [ -f "$FDIR/GoogleSans-Regular.ttf" ] && [ -f "$FDIR/GoogleSans-Medium.ttf" ]; then
    if [ -f "$FDIR/InterDisplay-Regular.ttf" ] && [ -f "$FDIR/InterDisplay-Medium.ttf" ]; then
        echo "SWAP: InterDisplay pair -> GoogleSans clones ($(stat -c%s "$FDIR/InterDisplay-Regular.ttf") + $(stat -c%s "$FDIR/InterDisplay-Medium.ttf") bytes freed)"
        cp -f "$FDIR/GoogleSans-Regular.ttf" "$FDIR/InterDisplay-Regular.ttf"
        cp -f "$FDIR/GoogleSans-Medium.ttf"  "$FDIR/InterDisplay-Medium.ttf"
    fi
    if [ -f "$FDIR/RobotoSlab.ttf" ]; then
        echo "SWAP: RobotoSlab -> GoogleSans clone ($(stat -c%s "$FDIR/RobotoSlab.ttf") bytes freed)"
        cp -f "$FDIR/GoogleSans-Regular.ttf" "$FDIR/RobotoSlab.ttf"
    fi
else
    echo "skip font swap: GoogleSans donor pair not found"
fi

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
