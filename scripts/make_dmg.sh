#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${1:-build/SleepBlocker.app}"
DMG_PATH="${2:-build/SleepBlocker.dmg}"
VOL_NAME="${3:-SleepBlocker}"

if [ ! -d "$APP_PATH" ]; then
    echo "App not found at $APP_PATH" >&2
    exit 1
fi

BUILD_DIR="$(dirname "$DMG_PATH")"
TMP_DMG="$BUILD_DIR/$(basename "$DMG_PATH" .dmg)-rw.dmg"
STAGING="$BUILD_DIR/dmg-staging"

# Clean up any previously mounted volume with the same name
if [ -d "/Volumes/$VOL_NAME" ]; then
    hdiutil detach "/Volumes/$VOL_NAME" -force >/dev/null 2>&1 || true
fi

rm -rf "$STAGING" "$TMP_DMG" "$DMG_PATH"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDRW -fs HFS+ \
    "$TMP_DMG" >/dev/null

hdiutil attach "$TMP_DMG" -readwrite -noverify -noautoopen >/dev/null

# Give the system a moment to fully register the volume with Finder
for i in 1 2 3 4 5 6 7 8; do
    if [ -d "/Volumes/$VOL_NAME" ]; then break; fi
    sleep 1
done
sleep 2

osascript <<EOF
tell application "Finder"
    activate
    delay 1
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 120, 1020, 560}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set text size of viewOptions to 14
        set position of item "SleepBlocker.app" of container window to {155, 205}
        set position of item "Applications" of container window to {465, 205}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

sync
hdiutil detach "/Volumes/$VOL_NAME" -force >/dev/null

hdiutil convert "$TMP_DMG" \
    -format UDZO -imagekey zlib-level=9 \
    -o "$DMG_PATH" >/dev/null

rm -f "$TMP_DMG"
rm -rf "$STAGING"

echo "Created $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"
