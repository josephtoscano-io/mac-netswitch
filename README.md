# mac-netswitch

Automatically turns off Wi-Fi when a wired ethernet connection is detected, and turns it back on when ethernet is unplugged. Optionally includes a SwiftBar menu bar icon that swaps between ethernet, Wi-Fi, and no-connection states, with built-in self-updating.

Tested on macOS Sequoia.

## Credits

Based on the original work by:
- [albertbori](https://gist.github.com/albertbori/1798d88a93175b9da00b) — original script
- [Calvin-LL](https://github.com/Calvin-LL/toggleairport) — Catalina+ updates

## Prerequisites

- **macOS Sequoia** (or later)
- **[Homebrew](https://brew.sh)** — required if you want the installer to set up SwiftBar automatically
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

## Install

```bash
git clone https://github.com/josephtoscano-io/mac-netswitch.git
cd mac-netswitch
./install.sh
```

The installer will ask which components you'd like:

- **Auto Wi-Fi toggle** — disables Wi-Fi when ethernet is connected, re-enables when unplugged
- **SwiftBar menu bar icon** — replaces the system Wi-Fi icon with a dynamic ethernet/Wi-Fi indicator

For the menu bar icon, [SwiftBar](https://swiftbar.app) is required. The installer can install it via Homebrew if needed.

### Menu bar icon setup

After installing the SwiftBar plugin:

1. Open SwiftBar and set your plugins folder to `~/swiftbar-plugins`
2. Hide the system Wi-Fi icon: **System Settings → Control Center → Wi-Fi → Don't Show in Menu Bar**

The icon will automatically swap between ethernet and Wi-Fi based on your connection.

### Custom icons

The installer uses the bundled icons by default. If you'd like to use your own, choose "Use custom menu bar icons" during install and provide paths to your PNG files (ethernet, Wi-Fi, and no-connection). Icons are embedded into the plugin at install time, so the source files can be deleted afterward. Custom icons persist across updates.

### Updates

The plugin checks GitHub once an hour for a new release. When one is available, an orange dot appears next to the menu bar icon and an "Update Available" item appears at the bottom of the dropdown. Click it to pull the latest version and refresh silently — no password, no re-configuration.

## Uninstall

```bash
./uninstall.sh
```

## Notes

- Do not run either script with `sudo` — everything installs at the user level (`~/Library/LaunchAgents/`)
- The auto-toggle runs every 2 seconds via a user-level LaunchAgent

