#!/usr/bin/env bash

# macOS System Defaults Setup
# Applies system-wide preferences via `defaults write`
#
# To verify a setting after running:
#   defaults read <domain> <key>
#
# To reset a setting to its default:
#   defaults delete <domain> <key>

echo "Setting up macOS defaults..."

# ============================================
# Screenshots
# ============================================
defaults write com.apple.screencapture sound -bool false           # disable screenshot sound
echo "  Applied screenshot defaults"

# ============================================
# Keyboard
# ============================================
defaults write NSGlobalDomain KeyRepeat -int 2                     # fast key repeat rate
defaults write NSGlobalDomain InitialKeyRepeat -int 15             # short delay before repeat starts
echo "  Applied keyboard defaults"

# ============================================
# Finder
# ============================================
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # list view by default
defaults write NSGlobalDomain AppleShowAllExtensions -bool true    # show all file extensions
echo "  Applied Finder defaults"

# ============================================
# Dock
# ============================================
defaults write com.apple.dock autohide -bool true                  # auto-hide dock
defaults write com.apple.dock autohide-delay -float 0              # no delay when showing dock
echo "  Applied Dock defaults"

# ============================================
# Terminal.app
# ============================================
defaults write com.apple.Terminal useOptionAsMetaKey -bool false    # option key sends special chars, not meta/esc
# also set it on the per-profile level (overrides the global setting)
/usr/libexec/PlistBuddy -c "Set ':Window Settings:Basic:useOptionAsMetaKey' false" ~/Library/Preferences/com.apple.Terminal.plist 2>/dev/null
echo "  Applied Terminal.app defaults"

# ============================================
# Restart affected services
# ============================================
killall Finder 2>/dev/null
killall Dock 2>/dev/null

echo ""
echo "macOS defaults applied! Some changes may require a logout/restart to fully take effect."
