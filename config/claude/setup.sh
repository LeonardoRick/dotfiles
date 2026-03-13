#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"
source "$DOTFILES/dots/.logging"

# Skills (overwrites existing files with latest version from GitHub)
# Installed globally into ~/.claude/skills/ (shared with opencode via symlinks)
install_skills() {
  local repo="$1"; shift
  local flags=""
  for skill in "$@"; do
    flags="$flags --skill $skill"
  done
  log.info "Updating skills from $repo"
  npx skills add "$repo" --global --copy --agent claude-code $flags -y 2>/dev/null \
    && { find -L ~/.claude/skills -type f -name '*.md' -exec sed -i '' 's/[[:space:]]*$//' {} +; log.success "Skills updated from $repo"; } \
    || log.error "Failed to update skills from $repo"
}

install_skills "vercel-labs/agent-skills" \
  vercel-react-best-practices \
  vercel-composition-patterns

install_skills "nextlevelbuilder/ui-ux-pro-max-skill" \
  ui-ux-pro-max

install_skills "anthropics/claude-plugins-official" \
  stripe-best-practices
