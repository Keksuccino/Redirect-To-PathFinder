# Redirect-To-PathFinder

Redirect-To-PathFinder is a small macOS LaunchAgent that makes Finder folder windows hand off to [Path Finder](https://www.cocoatech.io/), while keeping Apple's native Trash window in Finder.

It is meant for people who use Path Finder as their main file manager, but still rely on Finder's Desktop icons. When Finder opens a folder window, this helper captures the Finder window's position and size, closes that Finder window, opens the same folder in Path Finder, and applies the original window bounds to the Path Finder window.

## What it does

- Redirects newly opened Finder folder windows to Path Finder.
- Preserves the original Finder window position and size when opening the Path Finder window.
- Works for normal folders and folder symlinks.
- Leaves Trash native in Finder, including localized `Papierkorb` windows.
- Starts automatically at login through a per-user LaunchAgent.

## Why this exists

macOS does not provide a complete "replace Finder with another file manager" setting. Path Finder can register itself as the default file viewer, but Finder still owns Desktop icon behavior and some special system windows.

This helper uses a practical workaround:

1. Watch for newly created Finder windows.
2. Ignore windows that already existed before the helper started.
3. Ignore Trash, because Apple's Trash UI has special behavior.
4. Open the same folder in Path Finder.
5. Move the Path Finder window to the Finder window's original bounds.
6. Close the Finder window.

Because this is a redirect, a Finder window can appear very briefly before Path Finder takes over.

## Requirements

- macOS
- Path Finder installed as `/Applications/Path Finder.app`
- Permission for the helper to automate Finder and Path Finder when macOS asks

## Install

Clone the repository and run the installer:

```zsh
git clone https://github.com/Keksuccino/Redirect-To-PathFinder.git
cd Redirect-To-PathFinder
./scripts/install.sh
```

The installer copies the helper to:

```text
~/Library/Application Support/Redirect-To-PathFinder/
```

It also installs and loads this LaunchAgent:

```text
~/Library/LaunchAgents/com.keksuccino.redirect-to-pathfinder.plist
```

After installation, double-click a Desktop folder or a folder symlink. It should open in Path Finder. Opening the Trash should still show Finder's native Trash window.

## macOS permissions

The helper controls Finder and Path Finder with AppleScript. On first use, macOS may ask whether the helper may control those apps. Allow it.

If permissions get stuck, check:

```text
System Settings > Privacy & Security > Automation
```

Depending on your macOS version, the permission may appear under `osascript`, `zsh`, or the LaunchAgent's shell process.

## Uninstall

From the cloned repository:

```zsh
./scripts/uninstall.sh
```

Or manually:

```zsh
launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.keksuccino.redirect-to-pathfinder.plist"
rm -f "$HOME/Library/LaunchAgents/com.keksuccino.redirect-to-pathfinder.plist"
rm -rf "$HOME/Library/Application Support/Redirect-To-PathFinder"
```

## Configuration

The helper redirects all newly opened Finder folder windows by default. This is intentional: Desktop symlinks can resolve to targets outside `~/Desktop`, so a strict Desktop-path check would miss common symlink workflows.

If you only want to redirect Finder windows whose resolved target path starts inside `~/Desktop`, edit:

```text
~/Library/Application Support/Redirect-To-PathFinder/redirect-finder-windows.applescript
```

Change:

```applescript
property redirectAllNewFinderWindows : true
```

to:

```applescript
property redirectAllNewFinderWindows : false
```

Then restart the LaunchAgent:

```zsh
launchctl kickstart -k "gui/$(id -u)/com.keksuccino.redirect-to-pathfinder"
```

## Logs

The LaunchAgent writes logs to:

```text
~/Library/Logs/com.keksuccino.redirect-to-pathfinder.out.log
~/Library/Logs/com.keksuccino.redirect-to-pathfinder.err.log
```

The helper is intentionally quiet, so empty logs are normal.

## Notes

- Finder still owns macOS Desktop icons. This helper redirects after Finder creates a window; it does not replace Finder internally.
- Path Finder or macOS may clamp very small or off-screen window bounds.
- Trash stays in Finder because it is a special native UI, not a normal folder workflow.
