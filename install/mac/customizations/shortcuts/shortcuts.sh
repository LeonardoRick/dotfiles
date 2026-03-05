#!/usr/bin/env bash

# macOS Custom Keyboard Shortcuts Setup
# Sets custom keyboard shortcuts via `defaults write`
#
# Modifier key symbols for key equivalents:
#   @ = ⌘ (Command)
#   ~ = ⌥ (Option)
#   $ = ⇧ (Shift)
#   ^ = ⌃ (Control)
#
# To verify shortcuts after running:
#   System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts

echo "Setting up macOS keyboard shortcuts..."

# Register an app's bundle ID in com.apple.universalaccess com.apple.custommenu.apps
# so macOS picks up its NSUserKeyEquivalents. Without this, shortcuts set via
# `defaults write` are ignored.
CUSTOMMENU_MISSING_APPS=()

register_custommenu_app() {
    local bundle_id="$1"
    local current
    current=$(defaults read com.apple.universalaccess com.apple.custommenu.apps 2>/dev/null || echo "()")
    if ! echo "$current" | grep -qF "$bundle_id"; then
        if ! defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "$bundle_id" 2>/dev/null; then
            CUSTOMMENU_MISSING_APPS+=("$bundle_id")
        fi
    fi
}

# Register the app first, then write its shortcuts
write_shortcuts() {
    local domain="$1"
    shift
    register_custommenu_app "$domain"
    defaults write "$domain" NSUserKeyEquivalents -dict-add "$@"
}

# ============================================
# All Applications (NSGlobalDomain)
# ============================================
write_shortcuts NSGlobalDomain \
    "Move Tab to New Window" '^$M' \
    "Lock Screen" '@$L' \
    "New Window" '@$N' \
    "Search Tabs..." '^~@$L' \
    "Delete" '@$D' \
    "Send" $'@\r'
echo "  Applied shortcuts to NSGlobalDomain"

# ============================================
# Microsoft OneNote
# ============================================
write_shortcuts com.microsoft.onenote.mac \
    "Numbering" '^;' \
    "Set Proofing Language..." '~@L'
echo "  Applied shortcuts to com.microsoft.onenote.mac"

# ============================================
# Chromium browsers (Chrome, Brave, and all duplicate-app variants)
# ============================================
chromium_shortcuts=(
    "Duplicate Tab" '^$D'
    "Search Tabs..." '^~@$L'
    "Move Tab to New Window" '^$M'
)

for domain in $(defaults domains | tr ',' '\n' | grep -i -E 'chrome|brave' | tr -d ' '); do
    write_shortcuts "$domain" "${chromium_shortcuts[@]}"
    echo "  Applied shortcuts to $domain"
done

# ============================================
# Sandboxed Apple Apps (via configuration profile)
# ============================================
# Some Apple apps (Mail, Calendar, Notes, etc.) use DataVault-protected containers,
# which prevents `defaults write` from setting NSUserKeyEquivalents. We use a
# .mobileconfig profile with managed preferences (MCX) to bypass this restriction.
# Edit sandboxed-apps-shortcuts.mobileconfig to add/modify these shortcuts.
SANDBOXED_PROFILE_ID="com.dotfiles.sandboxed-shortcuts"
SANDBOXED_PROFILE="$DOTFILES/install/mac/customizations/shortcuts/sandboxed-apps-shortcuts.mobileconfig"
if profiles list 2>/dev/null | grep -qF "$SANDBOXED_PROFILE_ID"; then
    if [ "${1:-}" = "--update-profile" ]; then
        echo "  Removing old sandboxed apps shortcuts profile..."
        profiles remove -identifier "$SANDBOXED_PROFILE_ID" 2>/dev/null
        echo "  Installing updated profile..."
        open "$SANDBOXED_PROFILE"
        echo "  Approve the profile in System Settings > General > Device Management"
        echo -n "  Press Enter after installing the profile... "
        read -r
    else
        echo "  Sandboxed apps shortcuts profile already installed (use --update-profile to reinstall)"
    fi
else
    echo "  Installing sandboxed apps shortcuts profile..."
    open "$SANDBOXED_PROFILE"
    echo "  Approve the profile in System Settings > General > Device Management"
    echo -n "  Press Enter after installing the profile... "
    read -r
fi

# ============================================
# Figma
# ============================================
write_shortcuts com.figma.Desktop \
    "Copy as SVG" '^~@C'
echo "  Applied shortcuts to com.figma.Desktop"

if [ ${#CUSTOMMENU_MISSING_APPS[@]} -gt 0 ]; then
    echo ""
    echo "Could not register some apps (com.apple.universalaccess is TCC-protected)."
    echo "Your terminal needs Full Disk Access to complete the setup."
    echo ""
    echo "Missing apps:"
    for app in "${CUSTOMMENU_MISSING_APPS[@]}"; do
        echo "  - $app"
    done
    echo ""
    echo "Opening Full Disk Access settings..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    echo -n "Grant Full Disk Access to your terminal, then press Enter to retry... "
    read -r

    # Retry registration for missing apps
    local retry_failed=()
    for app in "${CUSTOMMENU_MISSING_APPS[@]}"; do
        if ! defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "$app" 2>/dev/null; then
            retry_failed+=("$app")
        else
            echo "  Registered $app"
        fi
    done

    if [ ${#retry_failed[@]} -gt 0 ]; then
        echo ""
        echo "Still could not register these apps. You may need to add them manually in:"
        echo "  System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts"
        for app in "${retry_failed[@]}"; do
            echo "  - $app"
        done
    fi
fi

echo ""
echo "Keyboard shortcuts set! You may need to restart apps for changes to take effect."
echo "To verify, reopen System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts."
