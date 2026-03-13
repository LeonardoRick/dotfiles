#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"
source "$DOTFILES/dots/.functions"

# Config files
ln -sfv $DOTFILES/dots/.claude/settings.json ~/.claude/settings.json
ln -sfv $DOTFILES/dots/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sfv $DOTFILES/dots/.claude/keybindings.json ~/.claude/keybindings.json

# Agents, agents data, and skills (shared with opencode via ~/.claude/)
symlink_folder "$DOTFILES/dots/.claude/agents" ~/.claude/agents "agents"
symlink_folder "$DOTFILES/dots/.claude/agents-data" ~/.claude/agents-data "agents-data"
symlink_folder "$DOTFILES/dots/.claude/skills" ~/.claude/skills "skills"
