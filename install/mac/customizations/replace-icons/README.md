# replace-icons

Creates lightweight launcher apps in `/Applications` for each app profile defined
in the `icons/` folder. No external dependencies — only built-in macOS tools (`sips`, `iconutil`).

## Folder structure

```
icons/
  <App Name>/          ← must match the .app name in /Applications exactly
    <ProfileName>.png  ← one file per profile/variant you want
    <ProfileName>.png
```

**Example — three Brave Browser profiles:**

```
icons/
  Brave Browser/
    REM.png
    Uptrackr.png
    Work.png
```

Running the script produces:

```
/Applications/Brave Browser (REM).app
/Applications/Brave Browser (Uptrackr).app
/Applications/Brave Browser (Work).app
```

Each wrapper carries the custom icon and opens Brave directly in the matching profile.

## How to run

```sh
bash replace-icons.sh
```

The script always recreates everything from scratch, so re-running it after adding,
removing, or replacing a PNG is all that's needed.

## First launch (one-time per wrapper)

Because the wrappers are ad-hoc signed (not notarized), macOS Gatekeeper will block
the very first launch. Do this once per wrapper:

1. Open `/Applications` in Finder
2. Right-click the wrapper → **Open** → click **Open** in the dialog

After that the wrapper launches normally from Spotlight, the Dock, or anywhere else.

**Keychain prompt:** On the first run, macOS will ask *"Brave Browser (X) wants to
access key 'Brave Safe Storage' in your keychain"*. Enter your **macOS login password**
and click **Always Allow**. This grants the wrapper permanent access to the same
encrypted storage as the original app (saved passwords, cookies, etc.).

## How it works

Each generated `.app` is an APFS copy-on-write clone of the original app bundle
(`cp -Rc`). This means macOS shares the actual disk blocks between the original app
and each wrapper — only the few modified files take up real extra space (a few hundred
KB per wrapper, not the ~500 MB a full Brave copy would cost). Three things are modified
in the clone:

- **`Info.plist`** — unique `CFBundleIdentifier` and display name so the wrapper
  appears as a separate app in Spotlight, the Dock, and Alt-Tab.
- **Launcher script** — the original binary is renamed to `.bin`; a small shell script
  takes its place and passes `--profile-directory="..."` when exec-ing the real binary.
- **Icon** — the PNG from `icons/` is converted to ICNS and baked into both the bundle
  resources and the macOS resource fork (via `NSWorkspace.setIcon`) so Finder and the
  Dock display it immediately.

For **Chromium-based browsers** (Brave Browser, Google Chrome, Microsoft Edge) the
profile directory name (e.g. `Profile 2`) is resolved automatically by reading the
browser's `Local State` file. The PNG filename must match the profile's display name
as set inside the browser (case-insensitive).

For **other apps** the wrapper simply opens the app; the icon is the only customisation.

## Dock, Spotlight & CMD+Tab

| Feature | Works? |
|---|---|
| Custom icon in Dock | ✓ Pin each wrapper to the Dock |
| Spotlight search by profile name | ✓ |
| Click to open the right profile | ✓ |
| CMD+Tab showing separate entries | ✓ Each wrapper shows its own icon |

Each wrapper gets a unique `CFBundleIdentifier` and runs with its own `--user-data-dir`,
so macOS treats them as separate applications in the Dock and in CMD+Tab.

## Sync behavior

Because each wrapper runs a separate Chromium user-data-dir (migrated from the original
profile), **bookmarks/favorites sync** across instances via Brave Sync as expected.

**Tabs do not sync** between instances. This is expected — the intended workflow is to
migrate to the new profile wrapper and use it going forward, not to keep two instances
in sync for the same browsing session.

## Adding a new profile

1. Add `<ProfileName>.png` inside the matching app subfolder in `icons/`.
2. Re-run `bash replace-icons.sh` — it removes all existing wrappers for that app and rebuilds them.

## Generating tinted icons

`tint-icon.sh` creates a hue-rotated variant of an app's own icon and saves it directly
into the right `icons/` subfolder, ready to be picked up by `replace-icons.sh`.

```sh
bash tint-icon.sh "<AppName>" "<ProfileName>" <HueDegrees>
```

| Argument | Description |
|---|---|
| `AppName` | Must match the subfolder in `icons/` and the `.app` in `/Applications` |
| `ProfileName` | Output filename — saved as `icons/<AppName>/<ProfileName>.png` |
| `HueDegrees` | Hue rotation in degrees (0–360) |

Hue reference relative to Brave's orange lion:

| Degrees | Color |
|---|---|
| `90` | green |
| `150` | teal |
| `200` | blue-purple |
| `270` | pink / magenta |
| `330` | red |

**Example — green icon for the REM profile:**

```sh
bash tint-icon.sh "Brave Browser" REM 90
```

After generating the PNG, re-run `bash replace-icons.sh` to rebuild the wrapper apps.

## Notes

- **App updates reset custom icons.** When the original app updates (App Store, Homebrew,
  or its own updater), the wrappers are unaffected — they point to the updated binary and
  keep their custom icons. No action needed after an update.
- Wrappers are registered with Launch Services on creation, so Spotlight indexes them
  immediately without needing a logout.
- Re-running the script is safe and idempotent.
