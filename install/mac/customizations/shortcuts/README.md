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

## Sandboxed Apple Apps

Some Apple apps (Mail, Calendar, Notes, etc.) use **DataVault-protected containers**, which prevents `defaults write` from setting `NSUserKeyEquivalents`. For these apps, shortcuts are set via a macOS configuration profile (`sandboxed-apps-shortcuts.mobileconfig`) that uses managed preferences (MCX) to bypass the restriction.

To add shortcuts for a sandboxed app, edit `sandboxed-apps-shortcuts.mobileconfig` and add a new entry inside `PayloadContent` — the file contains inline instructions and examples. After editing, re-run `shortcuts.sh` to install the updated profile.

Special keys in the profile use XML character references (e.g. `&#x000d;` for Enter/Return). See the comment block at the top of the `.mobileconfig` file for a full reference.

**Note:** Shortcuts set via the profile **will not appear** in System Settings > Keyboard > App Shortcuts. They work correctly inside the apps, but the UI only shows shortcuts stored in the app's user preferences domain (which is DataVault-protected for these apps). If a shortcut can apply globally (e.g. "Send"), prefer adding it to the `NSGlobalDomain` section in `shortcuts.sh` instead — those appear in the UI and work everywhere.

## Important Notes

- **System Settings must be reopened** to see the shortcuts in the UI. If you had the Keyboard Shortcuts pane open while running the script, close and reopen System Settings.
- **Full Disk Access** is required for the terminal running this script. The script needs to write to `com.apple.universalaccess` to register apps in the shortcuts UI. Without this, shortcuts are written but won't appear or work. `mac.sh` checks for this before running.
- Chromium shortcuts are automatically applied to all Chrome/Brave variants, including custom apps created by `duplicate-apps`.
