#!/usr/bin/env bash
source ~/.bashrc

# Stop alert sound when pressing Ctrl + Cmd + Arrows.
# Currently there's still an issue with Ctrl + Option + Cmd + DownArrow: https://github.com/electron/electron/issues/2617
mkdir -p ~/Library/KeyBindings && ln -sfv $DOTFILES/config/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict

# vscode mac setup
ln -sfv $DOTFILES/config/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sfv $DOTFILES/config/vscode/mac-keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -sfv $DOTFILES/config/vscode/global-snippets.code-snippets ~/Library/Application\ Support/Code/User/snippets/global-snippets.code-snippets