#!/bin/bash
# mac-netswitch uninstaller

echo ""
echo "mac-netswitch uninstaller"
echo "========================="
echo ""

read -r -p "Uninstall auto Wi-Fi toggle? [y/n] " remove_toggle
remove_toggle="${remove_toggle:-Y}"

if [[ "$remove_toggle" =~ ^[Yy]$ ]]; then
    launchctl bootout "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist" 2>/dev/null || true
    rm -f "$HOME/Library/Scripts/mac-netswitch.sh"
    rm -f "$HOME/Library/LaunchAgents/com.mine.mac-netswitch.plist"
    # Also clean up the old system-wide install if present (pre-user-level migration)
    if [ -f /Library/LaunchAgents/com.mine.mac-netswitch.plist ]; then
        sudo launchctl unload /Library/LaunchAgents/com.mine.mac-netswitch.plist 2>/dev/null || true
        sudo rm -f /Library/Scripts/mac-netswitch.sh
        sudo rm -f /Library/LaunchAgents/com.mine.mac-netswitch.plist
    fi
    rm -f /var/tmp/prev_eth_on /var/tmp/prev_air_on /var/tmp/prev_mac_netswitch_run
    echo "✓ Auto Wi-Fi toggle removed."
fi

echo ""

read -r -p "Uninstall SwiftBar plugin? [y/n] " remove_swiftbar
remove_swiftbar="${remove_swiftbar:-Y}"

if [[ "$remove_swiftbar" =~ ^[Yy]$ ]]; then
    rm -f "$HOME/swiftbar-plugins/network-status.2s.sh"
    echo "✓ SwiftBar plugin removed."
fi

echo ""
echo "Done!"
