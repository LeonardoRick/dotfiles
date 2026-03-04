#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/icons"
APPS_DIR="/Applications"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Convert a PNG to an ICNS file using only built-in macOS tools (sips + iconutil)
convert_to_icns() {
    local png="$1" output="$2" tmpdir
    tmpdir=$(mktemp -d)
    local iconset="$tmpdir/icon.iconset"
    mkdir "$iconset"
    sips -z 16   16   "$png" --out "$iconset/icon_16x16.png"       >/dev/null
    sips -z 32   32   "$png" --out "$iconset/icon_16x16@2x.png"    >/dev/null
    sips -z 32   32   "$png" --out "$iconset/icon_32x32.png"        >/dev/null
    sips -z 64   64   "$png" --out "$iconset/icon_32x32@2x.png"    >/dev/null
    sips -z 128  128  "$png" --out "$iconset/icon_128x128.png"      >/dev/null
    sips -z 256  256  "$png" --out "$iconset/icon_128x128@2x.png"  >/dev/null
    sips -z 256  256  "$png" --out "$iconset/icon_256x256.png"      >/dev/null
    sips -z 512  512  "$png" --out "$iconset/icon_256x256@2x.png"  >/dev/null
    sips -z 512  512  "$png" --out "$iconset/icon_512x512.png"      >/dev/null
    sips -z 1024 1024 "$png" --out "$iconset/icon_512x512@2x.png"  >/dev/null
    iconutil -c icns "$iconset" -o "$output"
    rm -rf "$tmpdir"
}

# Return the user-data-dir root for a Chromium app (empty for non-Chromium).
# This is the single source of truth for supported Chromium browsers.
get_chromium_base_data_dir() {
    case "$1" in
        "Brave Browser") echo "$HOME/Library/Application Support/BraveSoftware/Brave-Browser" ;;
        "Google Chrome") echo "$HOME/Library/Application Support/Google/Chrome" ;;
        "Microsoft Edge") echo "$HOME/Library/Application Support/Microsoft Edge" ;;
    esac
}

# Resolve a profile display name (e.g. "REM") to its folder name (e.g. "Profile 2")
# by reading the browser's Local State file.
get_chromium_profile_dir() {
    local base_dir="$1" display_name="$2"
    local local_state="$base_dir/Local State"
    [ -f "$local_state" ] || return 0
    python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for dir_name, info in data.get('profile', {}).get('info_cache', {}).items():
    if info.get('name', '').lower() == sys.argv[2].lower():
        print(dir_name); sys.exit(0)
sys.exit(1)
" "$local_state" "$display_name" 2>/dev/null || true
}

# One-time migration: copy a profile to its own dedicated user-data-dir so the
# wrapper has a separate Chromium singleton (separate Dock icon, CMD+Tab entry).
# Subsequent runs are skipped if the dir already exists. Brave Sync keeps it in sync.
# Prints the new user-data-dir path on success.
migrate_chromium_profile() {
    local base_dir="$1" profile_name="$2" profile_dir="$3"
    local wrapper_data_dir="${base_dir}-${profile_name}"

    # Default profile — no copy needed. Point the wrapper directly at the
    # original user-data-dir so it just opens that profile as-is.
    if [ "$profile_dir" = "Default" ]; then
        echo "$base_dir"
        return 0
    fi

    # Non-default profile — one-time copy into its own user-data-dir so it gets
    # a separate Chromium singleton. Subsequent runs skip if dir already exists.
    if [ ! -d "$wrapper_data_dir/Default" ]; then
        mkdir -p "$wrapper_data_dir"
        cp -R "$base_dir/$profile_dir/" "$wrapper_data_dir/Default/"
    fi

    echo "$wrapper_data_dir"
}

# Add or overwrite a string key in a plist
plist_set() {
    local plist="$1" key="$2" value="$3"
    if /usr/libexec/PlistBuddy -c "Print :$key" "$plist" >/dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Set :$key $value" "$plist"
    else
        /usr/libexec/PlistBuddy -c "Add :$key string $value" "$plist"
    fi
}

# Create a profile wrapper app.
#
# Strategy:
#   1. APFS-clone the original .app's Contents (instant copy-on-write, near-zero disk cost).
#   2. Replace the binary with a shell launcher that passes --user-data-dir to the real
#      binary (renamed to .bin).
#   3. Patch Info.plist with a unique bundle ID so macOS treats it as a completely
#      separate app — own Dock icon, own CMD+Tab entry, own Spotlight entry.
#   4. Bake the custom icon into the bundle.
#   5. Ad-hoc sign the outer bundle so Gatekeeper accepts it.
create_wrapper() {
    local app_name="$1" profile_name="$2" icon_path="$3" user_data_dir="$4"
    local wrapper_name="$app_name ($profile_name)"
    local wrapper="$APPS_DIR/$wrapper_name.app"
    local original="$APPS_DIR/$app_name.app"
    local plist="$wrapper/Contents/Info.plist"
    local bundle_id
    bundle_id="com.custom.$(printf '%s.%s' "$app_name" "$profile_name" \
        | tr ' ' '.' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:].')"

    # Quit the wrapper app if it's running before replacing it
    if [ -d "$wrapper" ]; then
        osascript -e "tell application \"$wrapper_name\" to quit" 2>/dev/null || true
        # Wait briefly for the app to fully quit
        local retries=10
        while pgrep -f "$wrapper_name" >/dev/null 2>&1 && [ $retries -gt 0 ]; do
            sleep 0.5
            retries=$((retries - 1))
        done
    fi

    rm -rf "$wrapper"

    # Clone Contents (APFS copy-on-write — instant; falls back to real copy on non-APFS)
    mkdir -p "$wrapper"
    cp -Rc "$original/Contents" "$wrapper/Contents" 2>/dev/null \
        || cp -R  "$original/Contents" "$wrapper/Contents"

    # ── Bundle identity ────────────────────────────────────────────────────────
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "$plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleName $wrapper_name"    "$plist"
    plist_set "$plist" "CFBundleDisplayName" "$wrapper_name"
    # Prevent the localized name table from overriding our display name
    /usr/libexec/PlistBuddy -c "Set :LSHasLocalizedDisplayName 0"   "$plist" 2>/dev/null || true
    # Override display name in all localized InfoPlist.strings so Spotlight shows it correctly
    find "$wrapper/Contents/Resources" -name "InfoPlist.strings" -print0 2>/dev/null \
        | while IFS= read -r -d '' strings_file; do
            plutil -replace CFBundleDisplayName -string "$wrapper_name" "$strings_file" 2>/dev/null || true
            plutil -replace CFBundleName -string "$wrapper_name" "$strings_file" 2>/dev/null || true
        done
    # Detach from Brave's auto-updater so updates don't overwrite this copy
    /usr/libexec/PlistBuddy -c "Set :KSProductID $bundle_id"        "$plist" 2>/dev/null || true

    # ── Profile launcher ───────────────────────────────────────────────────────
    local exec_name
    exec_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$plist")
    local macos_dir="$wrapper/Contents/MacOS"

    if [ -n "$user_data_dir" ]; then
        # Rename the cloned binary to .bin and drop a shell launcher in its place.
        # Each wrapper uses its own --user-data-dir so it gets a separate Chromium
        # singleton — no more Dock grouping with the original or other wrappers.
        mv "$macos_dir/$exec_name" "$macos_dir/$exec_name.bin"
        # pgrep detects if this wrapper is already running; if so, --no-startup-window
        # tells Chromium's singleton to activate the existing window, not open a new one.
        printf '#!/bin/bash\nDIR="$(cd "$(dirname "$0")" && pwd)"\nUDD="%s"\nif pgrep -f -- "--user-data-dir=$UDD" >/dev/null 2>&1; then\n    exec "$DIR/%s.bin" --user-data-dir="$UDD" --no-startup-window "$@"\nelse\n    exec "$DIR/%s.bin" --user-data-dir="$UDD" "$@"\nfi\n' \
            "$user_data_dir" "$exec_name" "$exec_name" > "$macos_dir/$exec_name"
        chmod +x "$macos_dir/$exec_name"
    fi

    # ── Icon ───────────────────────────────────────────────────────────────────
    local icon_file
    icon_file=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$plist" 2>/dev/null || echo "app")
    icon_file="${icon_file%.icns}.icns"
    convert_to_icns "$icon_path" "$wrapper/Contents/Resources/$icon_file"

    # ── Sign & register ────────────────────────────────────────────────────────
    rm -rf "$wrapper/Contents/_CodeSignature"
    xattr -cr "$wrapper" 2>/dev/null || true

    # Deep-sign the full bundle with ad-hoc signature (no entitlements — runs
    # unsandboxed, which gives the wrapper more permissions, not fewer).
    codesign -f -s - --deep "$wrapper" 2>/dev/null || true

    # Chromium only: re-sign the browser binary with our bundle ID so Launch Services
    # treats it as a separate app in the Dock and CMD+Tab.
    if [ -n "$user_data_dir" ]; then
        codesign -f -s - --identifier "$bundle_id" \
            "$wrapper/Contents/MacOS/$exec_name.bin" 2>/dev/null || true
        # Re-sign the main bundle so its CodeResources references the updated .bin signature.
        codesign -f -s - "$wrapper" 2>/dev/null || true
    fi

    "$LSREGISTER" -f "$wrapper" 2>/dev/null || true

    # Write the icon into the resource fork via NSWorkspace so Finder/Dock/Spotlight
    # show the tinted icon immediately. Must run AFTER codesign.
    osascript -l JavaScript -e "ObjC.import('AppKit'); var img=\$.NSImage.alloc.initWithContentsOfFile('${wrapper}/Contents/Resources/${icon_file}'); \$.NSWorkspace.sharedWorkspace.setIconForFileOptions(img,'${wrapper}',0);" >/dev/null 2>&1 || true
}

# ——— Main ———

FORCE_RECREATE=false
for arg in "$@"; do
    case "$arg" in
        --force-recreate) FORCE_RECREATE=true ;;
        *) echo "Usage: bash duplicate-apps.sh [--force-recreate]"; exit 1 ;;
    esac
done

echo -e "${BLUE}Setting up app profile wrappers...${NC}"
echo ""

[ -d "$ICONS_DIR" ] || { echo -e "${RED}Error: icons directory not found at $ICONS_DIR${NC}"; exit 1; }

created=0; skipped=0; errors=0

# Remove stale wrappers whose source PNG was deleted
for app_dir in "$ICONS_DIR"/*/; do
    [ -d "$app_dir" ] || continue
    app_name=$(basename "$app_dir")
    while IFS= read -r -d '' f; do
        wrapper_base=$(basename "$f" .app)
        profile="${wrapper_base#"$app_name ("}"
        profile="${profile%")"}"
        if [ ! -f "$app_dir$profile.png" ]; then
            rm -rf "$f"
            echo -e "  ${YELLOW}removed${NC}  $(basename "$f")"
        fi
    done < <(find "$APPS_DIR" -maxdepth 1 -name "$app_name (*.app" -print0 2>/dev/null)
done

echo ""

# Create / recreate a wrapper for every PNG in every app subfolder
for app_dir in "$ICONS_DIR"/*/; do
    [ -d "$app_dir" ] || continue
    app_name=$(basename "$app_dir")

    if [ ! -d "$APPS_DIR/$app_name.app" ]; then
        echo -e "  ${YELLOW}skip${NC}  $app_name — not found in $APPS_DIR"
        skipped=$((skipped + 1))
        continue
    fi

    base_data_dir=$(get_chromium_base_data_dir "$app_name")

    for icon_path in "$app_dir"*.png; do
        [ -f "$icon_path" ] || continue
        profile_name=$(basename "$icon_path" .png)

        wrapper="$APPS_DIR/$app_name ($profile_name).app"
        if [ "$FORCE_RECREATE" = false ] && [ -d "$wrapper" ]; then
            echo -e "  ${BLUE}exists${NC}  $app_name ($profile_name).app"
            skipped=$((skipped + 1))
            continue
        fi

        user_data_dir=""
        is_fresh_instance=false
        if [ -n "$base_data_dir" ]; then
            profile_dir=$(get_chromium_profile_dir "$base_data_dir" "$profile_name")
            if [ -n "$profile_dir" ]; then
                user_data_dir=$(migrate_chromium_profile "$base_data_dir" "$profile_name" "$profile_dir")
            else
                # No matching profile found — create a fresh instance with its own user-data-dir
                user_data_dir="${base_data_dir}-${profile_name}"
                mkdir -p "$user_data_dir"
                is_fresh_instance=true
            fi
        fi

        if create_wrapper "$app_name" "$profile_name" "$icon_path" "$user_data_dir"; then
            if [ "$is_fresh_instance" = true ]; then
                echo -e "  ${GREEN}done${NC}  $app_name ($profile_name).app ${BLUE}(no existing profile found — created fresh instance)${NC}"
            else
                echo -e "  ${GREEN}done${NC}  $app_name ($profile_name).app"
            fi
            created=$((created + 1))
        else
            echo -e "  ${RED}fail${NC}  $app_name ($profile_name)"
            errors=$((errors + 1))
        fi
    done
done

echo ""
echo "Created: $created  |  Skipped: $skipped  |  Errors: $errors"

if [ $created -gt 0 ]; then
    echo ""
    echo "Clearing icon cache and restarting Dock..."
    sudo rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
    sudo find /private/var/folders -maxdepth 5 -name "fsCachedData" -exec rm -rf {} + 2>/dev/null || true
    killall iconservicesagent 2>/dev/null || true
    killall Dock   2>/dev/null || true
    killall Finder 2>/dev/null || true
    echo ""
    echo "First launch: right-click each new wrapper → Open to allow it past Gatekeeper (one-time per wrapper)."
fi
