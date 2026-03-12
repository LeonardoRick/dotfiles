#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"

mkdir -p ~/.config/opencode
ln -sfv $DOTFILES/dots/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
ln -sfv $DOTFILES/dots/.config/opencode/tui.json ~/.config/opencode/tui.json
ln -sfv $DOTFILES/dots/.config/opencode/diff.jsonc ~/.config/opencode/diff.jsonc
