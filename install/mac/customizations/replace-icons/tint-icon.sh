#!/bin/bash
# Generate a hue-rotated variant of an app icon and save it as a profile PNG.
#
# Usage:
#   bash tint-icon.sh <AppName> <ProfileName> <HueDegrees>
#
# Arguments:
#   AppName      — must match a subfolder inside icons/ and a .app in /Applications
#   ProfileName  — output filename (saved as icons/<AppName>/<ProfileName>.png)
#   HueDegrees   — how many degrees to rotate the hue (0–360)
#
# Common hue shifts from the original Brave orange (~30°):
#   90  → green
#   150 → teal / cyan
#   200 → blue-purple
#   270 → pink / magenta
#
# Example — create a green icon for the Uptrackr profile:
#   bash tint-icon.sh "Brave Browser" Uptrackr 90

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 3 ]; then
    echo "Usage: bash tint-icon.sh <AppName> <ProfileName> <HueDegrees>"
    exit 1
fi

APP_NAME="$1"
PROFILE_NAME="$2"
HUE_DEGREES="$3"
APP_PATH="/Applications/$APP_NAME.app"
ICON_DIR="$SCRIPT_DIR/icons/$APP_NAME"
OUTPUT="$ICON_DIR/$PROFILE_NAME.png"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found"
    exit 1
fi

# Find the .icns inside the app bundle
ICNS=$(defaults read "$APP_PATH/Contents/Info" CFBundleIconFile 2>/dev/null || true)
ICNS="${ICNS%.icns}.icns"
ICNS_PATH="$APP_PATH/Contents/Resources/$ICNS"
if [ ! -f "$ICNS_PATH" ]; then
    ICNS_PATH=$(find "$APP_PATH/Contents/Resources" -name "*.icns" | head -1)
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

iconutil -c iconset "$ICNS_PATH" -o "$TMPDIR/icon.iconset"
SRC="$TMPDIR/icon.iconset/icon_512x512@2x.png"

# Set up a throw-away venv so we don't pollute the system Python
python3 -m venv "$TMPDIR/venv"
"$TMPDIR/venv/bin/pip" install Pillow -q 2>/dev/null

mkdir -p "$ICON_DIR"

"$TMPDIR/venv/bin/python3" - "$SRC" "$OUTPUT" "$HUE_DEGREES" <<'EOF'
from PIL import Image
import colorsys, sys, math

src, dst, degrees = sys.argv[1], sys.argv[2], float(sys.argv[3])
shift = degrees / 360.0

img = Image.open(src).convert("RGBA")
pixels = img.load()
w, h = img.size

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        if a == 0:
            continue
        hh, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        hh = (hh + shift) % 1.0
        nr, ng, nb = colorsys.hsv_to_rgb(hh, s, v)
        pixels[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)

img.save(dst, "PNG")
print(f"saved → {dst}")
EOF