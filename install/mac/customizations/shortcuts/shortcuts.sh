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

# Write shortcuts for a given domain and register it
write_shortcuts() {
    local domain="$1"
    shift
    defaults write "$domain" NSUserKeyEquivalents -dict-add "$@"
    register_custommenu_app "$domain"
}

# ============================================
# All Applications (NSGlobalDomain)
# ============================================
write_shortcuts NSGlobalDomain \
    "Show Help menu" "@$/" \
    "Move Tab to New Window" "^$M" \
    "Lock Screen" "@$L" \
    "New Window" "@$N" \
    "Search Tabs..." "^~@$A" \
    "Delete" "@$D"

# ============================================
# Microsoft OneNote
# ============================================
write_shortcuts com.microsoft.onenote.mac \
    "Numbering" "^;" \
    "Set Proofing Language..." "~@L"

# ============================================
# Chromium browsers (Chrome, Brave, and all duplicate-app variants)
# ============================================
chromium_shortcuts=(
    "Duplicate Tab" "^~D"
    "Search Tabs..." "^~$@L"
    "Move Tab to New Window" "^~M"
)

for domain in $(defaults domains | tr ',' '\n' | grep -i -E 'chrome|brave' | tr -d ' '); do
    write_shortcuts "$domain" "${chromium_shortcuts[@]}"
    echo "  Applied shortcuts to $domain"
done

# ============================================
# Figma
# ============================================
write_shortcuts com.figma.Desktop \
    "Copy as SVG" "^~@C"

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
    read -rp "Grant Full Disk Access to your terminal, then press Enter to retry... "

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
