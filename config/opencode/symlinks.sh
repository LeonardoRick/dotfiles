#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"
source "$DOTFILES/dots/.functions"

# Config files
mkdir -p ~/.config/opencode
ln -sfv $DOTFILES/dots/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc
ln -sfv $DOTFILES/dots/.config/opencode/tui.json ~/.config/opencode/tui.json
ln -sfv $DOTFILES/dots/.config/opencode/diff.jsonc ~/.config/opencode/diff.jsonc
ln -sfv $DOTFILES/dots/.config/opencode/opencode-notifier.json ~/.config/opencode/opencode-notifier.json
ln -sfv $DOTFILES/dots/.config/opencode/notify.sh ~/.config/opencode/notify.sh
ln -sfv $DOTFILES/dots/.config/opencode/opencode-yolo.jsonc ~/.config/opencode/opencode-yolo.jsonc

# Agents: opencode reads from ~/.config/opencode/agents/
symlink_folder "$DOTFILES/dots/.claude/agents" ~/.config/opencode/agents "opencode agents"

# Commands: opencode reads from ~/.config/opencode/commands/
symlink_folder "$DOTFILES/dots/.config/opencode/commands" ~/.config/opencode/commands "opencode commands"
