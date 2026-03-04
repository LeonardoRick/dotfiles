#!/usr/bin/env bash
source ~/.bashrc

# Check Full Disk Access (required for keyboard shortcuts setup).
# We test by writing a harmless value and removing it — reading alone doesn't verify write access.
if ! defaults write com.apple.universalaccess __fda_check true 2>/dev/null; then
    echo "Your terminal does not have Full Disk Access."
    echo "This is required for setting up keyboard shortcuts."
    echo ""
    echo "Opening Full Disk Access settings..."
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    read -rp "Grant Full Disk Access to your terminal, then press Enter to continue... "

    if ! defaults write com.apple.universalaccess __fda_check true 2>/dev/null; then
        echo "ERROR: Still no Full Disk Access. Exiting."
        exit 1
    fi
fi
defaults delete com.apple.universalaccess __fda_check 2>/dev/null

# Stop alert sound when pressing Ctrl + Cmd + Arrows.
# Currently there's still an issue with Ctrl + Option + Cmd + DownArrow: https://github.com/electron/electron/issues/2617
mkdir -p ~/Library/KeyBindings && ln -sfv $DOTFILES/config/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict

# vscode mac setup
ln -sfv $DOTFILES/config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfv $DOTFILES/config/vscode/mac-keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -sfv $DOTFILES/config/vscode/global-snippets.code-snippets ~/Library/Application\ Support/Code/User/snippets/global-snippets.code-snippets

# macOS custom keyboard shortcuts
source $DOTFILES/install/mac/customizations/shortcuts/shortcuts.sh

# pnpm setup (this just runs the first time you setup your mac and that's why it's not inside .functions/setup_nvm)
nvm install --lts # install node lts version
corepack enable
corepack prepare pnpm@latest --activate # install the latest version of pnpm
pnpm completion zsh >| ~/completion-for-pnpm.zsh
