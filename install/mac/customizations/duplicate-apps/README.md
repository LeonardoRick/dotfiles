# duplicate-apps

Creates lightweight duplicate apps in `/Applications` with custom icons. Each duplicate
gets a unique bundle ID so macOS treats it as a completely separate application — own
Dock icon, own CMD+Tab entry, own Spotlight entry.

No external dependencies — only built-in macOS tools (`sips`, `iconutil`).

## Supported apps

| App type | What happens |
|---|---|
| **Chromium browsers** (Brave, Chrome, Edge) | Full profile isolation via `--user-data-dir`. If the PNG name matches an existing profile, it migrates it; otherwise creates a fresh instance. |
| **Other non-sandboxed apps** | Custom icon, separate instance if the app supports running multiple copies. |
| **App Store / sandboxed apps** | **Not supported.** These apps verify their bundle ID and signing identity at runtime and crash when they don't match. Ad-hoc signing can't replicate Apple's certificate chain. |

## Folder structure

```
icons/
  <App Name>/          ← must match the .app name in /Applications exactly
    <ProfileName>.png  ← one file per profile/variant you want
```

**Example:**

```
icons/
  Brave Browser/
    REM.png
    Uptrackr.png
```

Running the script produces:

```
/Applications/Brave Browser (REM).app
/Applications/Brave Browser (Uptrackr).app
```

## How to run

```sh
bash duplicate-apps.sh
```

The script always recreates everything from scratch, so re-running it after adding,
removing, or replacing a PNG is all that's needed.

## First launch (one-time per wrapper)

Because the wrappers are ad-hoc signed (not notarized), macOS Gatekeeper will block
the very first launch. Do this once per wrapper:

1. Open `/Applications` in Finder
2. Right-click the wrapper → **Open** → click **Open** in the dialog

After that the wrapper launches normally from Spotlight, the Dock, or anywhere else.

**Keychain prompt (Chromium only):** On the first run, macOS will ask *"Brave Browser (X)
wants to access key 'Brave Safe Storage' in your keychain"*. Enter your **macOS login
password** and click **Always Allow**.

**Icon in Spotlight/Raycast:** The custom icon may appear corrupted or show the original
app's blocked icon the first time you search for it. This is a caching issue — refreshing
Raycast or Spotlight (open and close it again) fixes it.

## How it works

Each generated `.app` is an APFS copy-on-write clone of the original app bundle
(`cp -Rc`). This means macOS shares the actual disk blocks between the original app
and each wrapper — only the few modified files take up real extra space (a few hundred
KB per wrapper, not the ~500 MB a full copy would cost). Three things are modified
in the clone:

- **`Info.plist`** — unique `CFBundleIdentifier` and display name so the wrapper
  appears as a separate app in Spotlight, the Dock, and CMD+Tab.
- **Launcher script** (Chromium only) — the original binary is renamed to `.bin`;
  a small shell script takes its place and passes `--user-data-dir` when exec-ing
  the real binary.
- **Icon** — the PNG from `icons/` is converted to ICNS and baked into both the bundle
  resources and the macOS resource fork (via `NSWorkspace.setIcon`) so Finder and the
  Dock display it immediately.

## Dock, Spotlight & CMD+Tab

| Feature | Works? |
|---|---|
| Custom icon in Dock | ✓ Pin each wrapper to the Dock |
| Spotlight search by profile name | ✓ |
| Click to open the right profile | ✓ |
| CMD+Tab showing separate entries | ✓ Each wrapper shows its own icon |

Each wrapper gets a unique `CFBundleIdentifier` so macOS treats them as separate
applications in the Dock and in CMD+Tab.

## Sync behavior (Chromium)

Because each wrapper runs a separate Chromium user-data-dir (migrated from the original
profile), **bookmarks/favorites sync** across instances via Brave Sync as expected.

**Tabs do not sync** between instances. This is expected — the intended workflow is to
migrate to the new profile wrapper and use it going forward, not to keep two instances
in sync for the same browsing session.

## Adding a new app/profile

1. Add `<ProfileName>.png` inside the matching app subfolder in `icons/`.
2. Re-run `bash duplicate-apps.sh` — it removes all existing wrappers for that app and rebuilds them.

## Generating tinted icons

`tint-icon.sh` creates a hue-rotated variant of an app's own icon and saves it directly
into the right `icons/` subfolder, ready to be picked up by `duplicate-apps.sh`.

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

After generating the PNG, re-run `bash duplicate-apps.sh` to rebuild the wrapper apps.

## Updating

Wrapper apps have a unique bundle ID and are detached from the original app's auto-updater.
Attempting to update from within a wrapper (e.g. `brave://settings/help`) will fail.

To update wrapper apps after the original app receives an update:

1. Update the **original** app normally (e.g. update Brave Browser)
2. Re-run `bash duplicate-apps.sh --force-recreate` to rebuild the wrappers from the updated original
3. Running wrappers will be **gracefully quit** before being replaced

Custom keyboard shortcuts and other user preferences are **not affected** by recreating
wrappers — they are stored in `~/Library/Preferences/` by bundle ID, not inside the app bundle.

## Notes

- Wrappers are registered with Launch Services on creation, so Spotlight indexes them
  immediately without needing a logout.
- Re-running the script is safe and idempotent.
