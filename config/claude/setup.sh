#!/usr/bin/env bash

DOTFILES="${DOTFILES:-$(realpath "$(dirname "$0")/../..")}"
source "$DOTFILES/dots/.logging"

if ! command -v claude &>/dev/null; then
  log.warning "Claude Code is not installed. Skipping plugin setup."
  return 0 2>/dev/null || exit 0
fi

# Marketplaces (added once, idempotent)
CLAUDE_MARKETPLACES=(
  nextlevelbuilder/ui-ux-pro-max-skill
)
for marketplace in "${CLAUDE_MARKETPLACES[@]}"; do
  claude plugins marketplace add "$marketplace" 2>/dev/null
done

# Plugins from official marketplace
CLAUDE_PLUGINS=(
  stripe
)
for plugin in "${CLAUDE_PLUGINS[@]}"; do
  log.info "Installing Claude Code plugin: $plugin"
  claude plugins install "$plugin@claude-plugins-official" --scope user 2>/dev/null \
    && log.success "Installed $plugin" \
    || log.error "Failed to install $plugin"
done

# Plugins from third-party marketplaces
CLAUDE_PLUGINS_THIRDPARTY=(
  "ui-ux-pro-max@ui-ux-pro-max-skill"
)
for plugin in "${CLAUDE_PLUGINS_THIRDPARTY[@]}"; do
  log.info "Installing Claude Code plugin: $plugin"
  claude plugins install "$plugin" --scope user 2>/dev/null \
    && log.success "Installed $plugin" \
    || log.error "Failed to install $plugin"
done
