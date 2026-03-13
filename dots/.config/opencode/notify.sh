#!/usr/bin/env bash
# OpenCode notification wrapper — matches Claude Code terminal-notifier behavior
# The plugin runs this from the project directory, so $PWD is the project path.
#
# Suppression logic:
#   - Standalone terminal (iTerm2, Alacritty, etc.) is focused → suppress
#   - VS Code is focused AND the window title starts with this project name → suppress
#   - VS Code is focused but a different project window → notify
#   - Any other app focused (browser, Slack, etc.) → notify
#
# Usage: notify.sh <event> <message>

EVENT="$1"
MESSAGE="$2"
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
  # VS Code window titles start with the folder name (e.g., "dotfiles — file.ts")
  if [[ "$WINDOW_TITLE" == "$PROJECT_NAME"* ]]; then
    exit 0
  fi
fi

/opt/homebrew/bin/terminal-notifier \
  -title "OpenCode" \
  -message "$MESSAGE" \
  -execute "open -a 'Visual Studio Code' '$PROJECT_DIR'"
