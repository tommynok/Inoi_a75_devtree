#!/bin/bash
set -e

echo "=== Applying custom patches ==="

# --- Путь к TWRP-теме (portrait_hdpi по авто-детекту разрешения 1080x2460) ---
THEME_FILE="bootable/recovery/gui/theme/common/portrait_hdpi.xml"

if [ ! -f "$THEME_FILE" ]; then
    echo "ERROR: $THEME_FILE not found — theme path may differ, check TW_THEME/auto-detect logic"
    exit 1
fi

# --- Бэкап оригинала в workspace (не попадёт в финальный образ) ---
cp "$THEME_FILE" "${THEME_FILE}.orig"

# --- Замена action на кнопке logo: home -> тестовый cmd ---
sed -i 's#<action function="key">home</action>#<action function="cmd">touch /data/media/0/test_button_ok.txt\ndate >> /data/media/0/test_button_ok.txt\n</action>#' "$THEME_FILE"

echo "=== Theme patched: logo button now runs test cmd ==="
echo "=== Patch script finished ==="
