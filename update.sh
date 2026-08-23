#!/bin/bash
# mac-netswitch updater — pulls latest and refreshes installed components silently

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "mac-netswitch updater"
echo "====================="
echo ""

echo "→ Pulling latest from GitHub..."
git fetch origin
git reset --hard origin/master
echo ""

# Re-launch with the freshly pulled script so new placeholders/logic take effect
if [ "${1:-}" != "--post-pull" ]; then
    exec "$0" --post-pull
fi

# ── Refresh auto Wi-Fi toggle if installed ─────────────────────────────────────
USER_PLIST="$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist"
if [ -f "$USER_PLIST" ]; then
    echo "→ Updating auto Wi-Fi toggle..."
    cp "$SCRIPT_DIR/mac-netswitch.sh" "$HOME/Library/Scripts/mac-netswitch.sh"
    chmod 755 "$HOME/Library/Scripts/mac-netswitch.sh"
    cp "$SCRIPT_DIR/com.mine.mac-netswitch.plist" "$USER_PLIST"
    SCRIPT_PATH_ESCAPED=$(echo "$HOME/Library/Scripts/mac-netswitch.sh" | sed 's|/|\\/|g')
    sed -i '' "s/__SCRIPT_PATH__/$SCRIPT_PATH_ESCAPED/" "$USER_PLIST"
    launchctl bootout "gui/$(id -u)" "$USER_PLIST" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$USER_PLIST"
    echo "✓ Auto Wi-Fi toggle updated."
elif [ -f /Library/LaunchAgents/com.mine.mac-netswitch.plist ]; then
    echo "→ Migrating auto Wi-Fi toggle to user space (may prompt for password one last time)..."
    sudo launchctl unload /Library/LaunchAgents/com.mine.mac-netswitch.plist 2>/dev/null || true
    sudo rm -f /Library/Scripts/mac-netswitch.sh /Library/LaunchAgents/com.mine.mac-netswitch.plist
    mkdir -p "$HOME/Library/Scripts" "$HOME/Library/LaunchAgents"
    cp "$SCRIPT_DIR/mac-netswitch.sh" "$HOME/Library/Scripts/mac-netswitch.sh"
    chmod 755 "$HOME/Library/Scripts/mac-netswitch.sh"
    cp "$SCRIPT_DIR/com.mine.mac-netswitch.plist" "$USER_PLIST"
    SCRIPT_PATH_ESCAPED=$(echo "$HOME/Library/Scripts/mac-netswitch.sh" | sed 's|/|\\/|g')
    sed -i '' "s/__SCRIPT_PATH__/$SCRIPT_PATH_ESCAPED/" "$USER_PLIST"
    launchctl bootstrap "gui/$(id -u)" "$USER_PLIST"
    echo "✓ Migrated to user-level LaunchAgent — no more password prompts on future updates."
fi

# ── Refresh SwiftBar plugin if installed ───────────────────────────────────────
PLUGIN="$HOME/swiftbar-plugins/network-status.2s.sh"
if [ -f "$PLUGIN" ]; then
    echo "→ Updating SwiftBar plugin..."

    # Load custom icon paths (if any were set during install)
    CONFIG_FILE="$HOME/.config/mac-netswitch/icons.conf"
    CUSTOM_ETH_ICON=""
    CUSTOM_WIFI_STRONG_ICON=""
    CUSTOM_WIFI_MEDIUM_ICON=""
    CUSTOM_WIFI_WEAK_ICON=""
    CUSTOM_NO_CONN_ICON=""
    CUSTOM_SEARCHING_ICON=""
    [ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE"

    # Use custom icons if configured, otherwise pull fresh from repo
    eth_icon="${CUSTOM_ETH_ICON:-$SCRIPT_DIR/ethernet-icon.png}"
    wifi_strong_icon="${CUSTOM_WIFI_STRONG_ICON:-$SCRIPT_DIR/wifi-icon.png}"
    wifi_medium_icon="${CUSTOM_WIFI_MEDIUM_ICON:-$SCRIPT_DIR/wifi_2bars_icon.png}"
    wifi_weak_icon="${CUSTOM_WIFI_WEAK_ICON:-$SCRIPT_DIR/wifi_1bar_icon.png}"
    no_conn_icon="${CUSTOM_NO_CONN_ICON:-$SCRIPT_DIR/no_connection-icon.png}"
    searching_icon="${CUSTOM_SEARCHING_ICON:-$SCRIPT_DIR/wifi_searching_icon.png}"

    cp "$SCRIPT_DIR/swiftbar/network-status.2s.sh" "$PLUGIN"

    WIFI_STRONG_B64=$(base64 -i "$wifi_strong_icon")
    WIFI_MEDIUM_B64=$(base64 -i "$wifi_medium_icon")
    WIFI_WEAK_B64=$(base64 -i "$wifi_weak_icon")
    ETH_B64=$(base64 -i "$eth_icon")
    NO_CONN_B64=$(base64 -i "$no_conn_icon")
    SEARCHING_B64=$(base64 -i "$searching_icon")
    INSTALLED_SHA=$(git rev-parse HEAD 2>/dev/null || echo "")
    REPO_DIR_ESCAPED=$(echo "$SCRIPT_DIR" | sed 's|/|\\/|g')

    sed -i '' "s|__WIFI_STRONG_ICON__|$WIFI_STRONG_B64|" "$PLUGIN"
    sed -i '' "s|__WIFI_MEDIUM_ICON__|$WIFI_MEDIUM_B64|" "$PLUGIN"
    sed -i '' "s|__WIFI_WEAK_ICON__|$WIFI_WEAK_B64|" "$PLUGIN"
    sed -i '' "s|__ETH_ICON__|$ETH_B64|" "$PLUGIN"
    sed -i '' "s|__NO_CONN_ICON__|$NO_CONN_B64|" "$PLUGIN"
    sed -i '' "s|__SEARCHING_ICON__|$SEARCHING_B64|" "$PLUGIN"
    sed -i '' "s|__INSTALLED_SHA__|$INSTALLED_SHA|" "$PLUGIN"
    sed -i '' "s/__REPO_DIR__/$REPO_DIR_ESCAPED/" "$PLUGIN"

    chmod +x "$PLUGIN"

    # Clear the update check cache so it picks up the new SHA immediately
    rm -f /tmp/mac-netswitch-update-check /tmp/mac-netswitch-latest-sha

    echo "✓ SwiftBar plugin updated."
fi

echo ""
echo "Done!"
