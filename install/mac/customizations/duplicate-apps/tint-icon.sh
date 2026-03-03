#!/bin/bash
# Generate a hue-rotated variant of an app icon and save it as a profile PNG.
#
# Interactive mode (no arguments — requires fzf):
#   bash tint-icon.sh
#
# Non-interactive mode:
#   bash tint-icon.sh <AppName> <ProfileName> <HueDegrees>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Interactive mode ───────────────────────────────────────────────────────────
if [ $# -eq 0 ]; then
    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf is required for interactive mode. Install it with: brew install fzf"
        echo "Or use non-interactive mode: bash tint-icon.sh <AppName> <ProfileName> <HueDegrees>"
        exit 1
    fi

    APP_NAME=$(find /Applications -maxdepth 1 -name "*.app" -print0 \
        | xargs -0 -n1 basename \
        | sed 's/\.app$//' \
        | sort \
        | fzf --prompt="Select app: " --height=20 --reverse) \
        || { echo "Cancelled."; exit 1; }

    HUE_LINE=$(printf '%s\n' \
        "green           (90°)" \
        "teal / cyan     (150°)" \
        "blue-purple     (200°)" \
        "pink / magenta  (270°)" \
        "red             (330°)" \
        | fzf --prompt="Select color: " --height=8 --reverse) \
        || { echo "Cancelled."; exit 1; }

    # Extract degrees from the selected line, e.g. "(200°)" → 200
    HUE_DEGREES=$(echo "$HUE_LINE" | grep -o '[0-9]*°' | tr -d '°')

    echo ""
    read -rp "Alias name (appears as \"${APP_NAME} (<alias>)\"): " PROFILE_NAME
    if [ -z "$PROFILE_NAME" ]; then
        echo "Alias cannot be empty"; exit 1
    fi
    echo ""

# ── Non-interactive mode ──────────────────────────────────────────────────────
elif [ $# -eq 3 ]; then
    APP_NAME="$1"
    PROFILE_NAME="$2"
    HUE_DEGREES="$3"
else
    echo "Usage: bash tint-icon.sh [<AppName> <ProfileName> <HueDegrees>]"
    exit 1
fi

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

iconutil -c iconset "$ICNS_PATH" -o "$TMPDIR/icon.iconset" 2>/dev/null || true

# Pick the largest available PNG from the iconset
SRC=$(ls -S "$TMPDIR/icon.iconset/"*.png 2>/dev/null | head -1)
if [ -z "$SRC" ]; then
    # iconutil failed or produced no PNGs — fall back to sips conversion
    sips -s format png "$ICNS_PATH" --out "$TMPDIR/fallback.png" >/dev/null 2>&1
    SRC="$TMPDIR/fallback.png"
fi

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
