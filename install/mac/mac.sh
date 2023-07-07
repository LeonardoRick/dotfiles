#!/usr/bin/env bash
source ~/.bashrc

# Stop alert sound when pressing Ctrl + Cmd + Arrows.
# Currently there's still an issue with Ctrl + Option + Cmd + DownArrow: https://github.com/electron/electron/issues/2617
ln -sfv $DOTFILES/config/DefaultKeyBinding.dict ~/Library/KeyBindings/DefaultKeyBinding.dict