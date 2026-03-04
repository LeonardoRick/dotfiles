# macOS Custom Keyboard Shortcuts

This script sets custom keyboard shortcuts using `defaults write` to the `NSUserKeyEquivalents` dictionary.

The shortcuts defined in `shortcuts.sh` will appear in the macOS UI at:
**System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts**

They work exactly the same as if you had added them manually through the UI.

## Modifier Key Reference

| Symbol | Modifier | Key Equivalent |
|--------|----------|----------------|
| ⌘ | Command | `@` |
| ⌥ | Option | `~` |
| ⇧ | Shift | `$` |
| ⌃ | Control | `^` |

## Usage

Run the script directly or through `mac.sh`:

```bash
source install/mac/customizations/shortcuts/shortcuts.sh
```

Apps may need to be restarted for changes to take effect.

## Important Notes

- **System Settings must be reopened** to see the shortcuts in the UI. If you had the Keyboard Shortcuts pane open while running the script, close and reopen System Settings.
- **Full Disk Access** is required for the terminal running this script. The script needs to write to `com.apple.universalaccess` to register apps in the shortcuts UI. Without this, shortcuts are written but won't appear or work. `mac.sh` checks for this before running.
- Chromium shortcuts are automatically applied to all Chrome/Brave variants, including custom apps created by `duplicate-apps`.
