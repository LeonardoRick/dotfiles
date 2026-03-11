#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"
source "$DOTFILES/dots/.logging"

# Config files
ln -sfv $DOTFILES/dots/.claude/settings.json ~/.claude/settings.json
ln -sfv $DOTFILES/dots/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sfv $DOTFILES/dots/.claude/keybindings.json ~/.claude/keybindings.json

# Agents — symlink whole folder if empty or already a symlink, warn otherwise
if [ -L ~/.claude/agents ]; then
  ln -sfv $DOTFILES/dots/.claude/agents ~/.claude/agents
elif [ -d ~/.claude/agents ] && [ -z "$(ls -A ~/.claude/agents 2>/dev/null)" ]; then
  rmdir ~/.claude/agents
  ln -sfv $DOTFILES/dots/.claude/agents ~/.claude/agents
elif [ ! -d ~/.claude/agents ]; then
  ln -sfv $DOTFILES/dots/.claude/agents ~/.claude/agents
else
  log.warning "~/.claude/agents/ exists and is not empty. Skipping symlink — merge manually."
fi

# Skills — symlink whole folder if empty or already a symlink, warn otherwise
if [ -d "$DOTFILES/dots/.claude/skills" ]; then
  if [ -L ~/.claude/skills ]; then
    ln -sfv $DOTFILES/dots/.claude/skills ~/.claude/skills
  elif [ -d ~/.claude/skills ] && [ -z "$(ls -A ~/.claude/skills 2>/dev/null)" ]; then
    rmdir ~/.claude/skills
    ln -sfv $DOTFILES/dots/.claude/skills ~/.claude/skills
  elif [ ! -d ~/.claude/skills ]; then
    ln -sfv $DOTFILES/dots/.claude/skills ~/.claude/skills
  else
    log.warning "~/.claude/skills/ exists and is not empty. Skipping symlink — merge manually."
  fi
fi
