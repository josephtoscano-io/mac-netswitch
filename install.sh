#!/bin/bash
# mac-netswitch installer

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "mac-netswitch installer"
echo "======================="
echo ""

# ── Auto Wi-Fi Toggle ──────────────────────────────────────────────────────────

read -r -p "Install auto Wi-Fi toggle (disables Wi-Fi when ethernet is connected)? [y/n] " install_toggle
install_toggle="${install_toggle:-Y}"

if [[ "$install_toggle" =~ ^[Yy]$ ]]; then
    echo "→ Installing auto Wi-Fi toggle..."
    mkdir -p "$HOME/Library/Scripts" "$HOME/Library/LaunchAgents"
    cp "$SCRIPT_DIR/mac-netswitch.sh" "$HOME/Library/Scripts/mac-netswitch.sh"
    chmod 755 "$HOME/Library/Scripts/mac-netswitch.sh"
    cp "$SCRIPT_DIR/com.mine.mac-netswitch.plist" "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist"
    SCRIPT_PATH_ESCAPED=$(echo "$HOME/Library/Scripts/mac-netswitch.sh" | sed 's|/|\\/|g')
    sed -i '' "s/__SCRIPT_PATH__/$SCRIPT_PATH_ESCAPED/" "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist"
    launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist"
    echo "✓ Auto Wi-Fi toggle installed."
fi

echo ""

# ── SwiftBar Menu Bar Icon ─────────────────────────────────────────────────────

read -r -p "Install SwiftBar menu bar icon (shows ethernet/Wi-Fi status)? [y/n] " install_swiftbar
install_swiftbar="${install_swiftbar:-Y}"

if [[ "$install_swiftbar" =~ ^[Yy]$ ]]; then

    if ! command -v swiftbar &>/dev/null && [ ! -d "/Applications/SwiftBar.app" ]; then
        echo ""
        echo "SwiftBar is not installed."
        if ! command -v brew &>/dev/null; then
            echo "Homebrew is not installed. To install the SwiftBar plugin, you need either:"
            echo "  1. Install Homebrew (https://brew.sh) and re-run this installer"
            echo "  2. Install SwiftBar manually from https://swiftbar.app and re-run this installer"
            echo ""
            echo "Skipping SwiftBar plugin."
            echo ""
            echo "Done!"
            exit 0
        fi
        read -r -p "Install SwiftBar via Homebrew? [y/n] " install_brew_swiftbar
        install_brew_swiftbar="${install_brew_swiftbar:-Y}"
        if [[ "$install_brew_swiftbar" =~ ^[Yy]$ ]]; then
            brew install --cask swiftbar
        else
            echo "Skipping SwiftBar install. Install it manually from https://swiftbar.app and re-run this installer."
            exit 0
        fi
    fi

    plugins_dir="$HOME/swiftbar-plugins"
    mkdir -p "$plugins_dir"

    eth_icon_path="$SCRIPT_DIR/ethernet-icon.png"
    wifi_strong_icon_path="$SCRIPT_DIR/wifi-icon.png"
    wifi_medium_icon_path="$SCRIPT_DIR/wifi_2bars_icon.png"
    wifi_weak_icon_path="$SCRIPT_DIR/wifi_1bar_icon.png"
    no_conn_icon_path="$SCRIPT_DIR/no_connection-icon.png"
    searching_icon_path="$SCRIPT_DIR/wifi_searching_icon.png"

    echo ""
    read -r -p "Use custom menu bar icons? [y/n] " use_custom
    use_custom="${use_custom:-N}"

    if [[ "$use_custom" =~ ^[Yy]$ ]]; then
        echo "  (leave blank on any prompt to use the default icon)"
        read -r -p "Path to ethernet icon: " custom_eth
        if [ -n "$custom_eth" ]; then
            custom_eth="${custom_eth/#\~/$HOME}"
            [ ! -f "$custom_eth" ] && { echo "Error: $custom_eth not found."; exit 1; }
            eth_icon_path="$custom_eth"
        fi

        read -r -p "Path to Wi-Fi strong icon: " custom_wifi_strong
        if [ -n "$custom_wifi_strong" ]; then
            custom_wifi_strong="${custom_wifi_strong/#\~/$HOME}"
            [ ! -f "$custom_wifi_strong" ] && { echo "Error: $custom_wifi_strong not found."; exit 1; }
            wifi_strong_icon_path="$custom_wifi_strong"
        fi

        read -r -p "Path to Wi-Fi medium icon: " custom_wifi_medium
        if [ -n "$custom_wifi_medium" ]; then
            custom_wifi_medium="${custom_wifi_medium/#\~/$HOME}"
            [ ! -f "$custom_wifi_medium" ] && { echo "Error: $custom_wifi_medium not found."; exit 1; }
            wifi_medium_icon_path="$custom_wifi_medium"
        fi

        read -r -p "Path to Wi-Fi weak icon: " custom_wifi_weak
        if [ -n "$custom_wifi_weak" ]; then
            custom_wifi_weak="${custom_wifi_weak/#\~/$HOME}"
            [ ! -f "$custom_wifi_weak" ] && { echo "Error: $custom_wifi_weak not found."; exit 1; }
            wifi_weak_icon_path="$custom_wifi_weak"
        fi

        read -r -p "Path to no-connection icon: " custom_no_conn
        if [ -n "$custom_no_conn" ]; then
            custom_no_conn="${custom_no_conn/#\~/$HOME}"
            [ ! -f "$custom_no_conn" ] && { echo "Error: $custom_no_conn not found."; exit 1; }
            no_conn_icon_path="$custom_no_conn"
        fi

        read -r -p "Path to searching icon: " custom_searching
        if [ -n "$custom_searching" ]; then
            custom_searching="${custom_searching/#\~/$HOME}"
            [ ! -f "$custom_searching" ] && { echo "Error: $custom_searching not found."; exit 1; }
            searching_icon_path="$custom_searching"
        fi
    fi

    PLUGIN="$plugins_dir/network-status.2s.sh"
    cp "$SCRIPT_DIR/swiftbar/network-status.2s.sh" "$PLUGIN"

    for icon in "$eth_icon_path" "$wifi_strong_icon_path" "$wifi_medium_icon_path" "$wifi_weak_icon_path" "$no_conn_icon_path" "$searching_icon_path"; do
        if [ ! -f "$icon" ]; then
            echo "Error: $icon not found. Check paths and try again."
            exit 1
        fi
    done

    ETH_B64=$(base64 -i "$eth_icon_path")
    WIFI_STRONG_B64=$(base64 -i "$wifi_strong_icon_path")
    WIFI_MEDIUM_B64=$(base64 -i "$wifi_medium_icon_path")
    WIFI_WEAK_B64=$(base64 -i "$wifi_weak_icon_path")
    NO_CONN_B64=$(base64 -i "$no_conn_icon_path")
    SEARCHING_B64=$(base64 -i "$searching_icon_path")
    INSTALLED_SHA=$(cd "$SCRIPT_DIR" && git rev-parse HEAD 2>/dev/null || echo "")
    REPO_DIR_ESCAPED=$(echo "$SCRIPT_DIR" | sed 's|/|\\/|g')
    sed -i '' "s|__WIFI_STRONG_ICON__|$WIFI_STRONG_B64|" "$PLUGIN"
    sed -i '' "s|__WIFI_MEDIUM_ICON__|$WIFI_MEDIUM_B64|" "$PLUGIN"
    sed -i '' "s|__WIFI_WEAK_ICON__|$WIFI_WEAK_B64|" "$PLUGIN"
    sed -i '' "s|__ETH_ICON__|$ETH_B64|" "$PLUGIN"
    sed -i '' "s|__NO_CONN_ICON__|$NO_CONN_B64|" "$PLUGIN"
    sed -i '' "s|__SEARCHING_ICON__|$SEARCHING_B64|" "$PLUGIN"
    sed -i '' "s|__INSTALLED_SHA__|$INSTALLED_SHA|" "$PLUGIN"
    sed -i '' "s/__REPO_DIR__/$REPO_DIR_ESCAPED/" "$PLUGIN"

    # Save custom icon paths (if any) for update.sh to re-use across updates
    CONFIG_DIR="$HOME/.config/mac-netswitch"
    mkdir -p "$CONFIG_DIR"
    {
        echo "CUSTOM_ETH_ICON=\"${custom_eth:-}\""
        echo "CUSTOM_WIFI_STRONG_ICON=\"${custom_wifi_strong:-}\""
        echo "CUSTOM_WIFI_MEDIUM_ICON=\"${custom_wifi_medium:-}\""
        echo "CUSTOM_WIFI_WEAK_ICON=\"${custom_wifi_weak:-}\""
        echo "CUSTOM_NO_CONN_ICON=\"${custom_no_conn:-}\""
        echo "CUSTOM_SEARCHING_ICON=\"${custom_searching:-}\""
    } > "$CONFIG_DIR/icons.conf"

    # Clear update-check caches so a fresh install doesn't show a stale "update available"
    rm -f /tmp/mac-netswitch-update-check /tmp/mac-netswitch-latest-sha

    chmod +x "$PLUGIN"
    echo "✓ SwiftBar plugin installed to $plugins_dir"

    echo ""
    echo "  Next steps:"
    echo "  1. Open SwiftBar and set your plugins folder to: $plugins_dir"
    echo "  2. Hide the system Wi-Fi icon: System Settings → Control Center → Wi-Fi → Don't Show in Menu Bar"
fi

echo ""
echo "Done!"
