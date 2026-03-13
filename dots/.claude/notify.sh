#!/usr/bin/env bash
# Claude Code notification wrapper — suppresses when the same project is focused
#
# Suppression logic:
#   - Standalone terminal (iTerm2, Alacritty, etc.) is focused → suppress
#   - VS Code is focused AND the window title starts with this project name → suppress
#   - VS Code is focused but a different project window → notify
#   - Any other app focused (browser, Slack, etc.) → notify
#
# Usage: notify.sh <message>

MESSAGE="$1"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

ACTIVE_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

# Suppress if a standalone terminal is focused
case "$ACTIVE_APP" in
  Terminal|iTerm2|Alacritty|kitty|WezTerm|Ghostty)
    exit 0
    ;;
esac

# Suppress if VS Code is focused on the same project window
if [[ "$ACTIVE_APP" == "Code" || "$ACTIVE_APP" == "Visual Studio Code" ]]; then
  WINDOW_TITLE=$(osascript -e 'tell application "System Events" to get name of first window of (first application process whose frontmost is true)' 2>/dev/null)
  if [[ "$WINDOW_TITLE" == "$PROJECT_NAME"* ]]; then
    exit 0
  fi
fi

/opt/homebrew/bin/terminal-notifier \
  -title "Claude Code" \
  -message "$MESSAGE" \
  -execute "open -a 'Visual Studio Code' '$PROJECT_DIR'"
