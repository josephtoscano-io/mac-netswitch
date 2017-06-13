#!/bin/bash
# <swiftbar.title>Network Status</swiftbar.title>
# <swiftbar.version>1.2</swiftbar.version>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

WIFI_ICON="__WIFI_ICON__"
ETH_ICON="__ETH_ICON__"
NO_CONN_ICON="__NO_CONN_ICON__"
INSTALLED_SHA="__INSTALLED_SHA__"
REPO_DIR="__REPO_DIR__"

# ── Check for updates (rate-limited to once per hour) ─────────────────────────
CHECK_FILE="/tmp/mac-netswitch-update-check"
LATEST_SHA_FILE="/tmp/mac-netswitch-latest-sha"
now=$(date +%s)
last_check=0
[ -f "$CHECK_FILE" ] && last_check=$(cat "$CHECK_FILE")

if (( now - last_check > 3600 )); then
    latest=$(curl -s --max-time 5 "https://api.github.com/repos/josephtoscano-io/mac-netswitch/commits/master" | sed -En 's/.*"sha": "([a-f0-9]+)".*/\1/p' | head -n1)
    if [ -n "$latest" ]; then
        echo "$latest" > "$LATEST_SHA_FILE"
        echo "$now" > "$CHECK_FILE"
    fi
fi

LATEST_SHA=""
[ -f "$LATEST_SHA_FILE" ] && LATEST_SHA=$(cat "$LATEST_SHA_FILE")

update_available=false
if [ -n "$LATEST_SHA" ] && [ -n "$INSTALLED_SHA" ] && [ "$LATEST_SHA" != "$INSTALLED_SHA" ]; then
    update_available=true
fi

print_update_item() {
    if $update_available; then
        echo "---"
        echo "Update Available | color=orange sfimage=arrow.down.circle.fill bash=$REPO_DIR/update.sh terminal=true refresh=true"
    fi
}

# Badge indicator shown next to the menu bar icon when an update is available
BADGE=""
BADGE_PARAMS=""
if $update_available; then
    BADGE="•"
    BADGE_PARAMS=" color=orange"
fi

air_name=$(networksetup -listnetworkserviceorder 2>/dev/null | sed -En 's/^\(Hardware Port: (Wi-Fi|AirPort).* Device: (en[0-9]+)\)$/\2/p')
eth_names=$(networksetup -listnetworkserviceorder 2>/dev/null | sed -En 's/^\(Hardware Port: .* Device: (en[0-9]+)\)$/\1/p' | grep -v "^${air_name}$")

eth_active=false
active_eth=""
for eth in $eth_names; do
    if ifconfig "$eth" 2>/dev/null | grep -q "status: active"; then
        eth_active=true
        active_eth=$eth
        break
    fi
done

air_status=$(networksetup -getairportpower "$air_name" 2>/dev/null | awk '{print $4}')

if [ "$air_status" = "On" ]; then
    echo "$BADGE | templateImage=$WIFI_ICON$BADGE_PARAMS"
    echo "---"
    ssid=$(networksetup -getairportnetwork "$air_name" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
    echo "$ssid" | grep -q "not associated" || echo "$ssid"
    echo "---"
    echo "Open Wi-Fi Settings | bash=open param1=x-apple.systempreferences:com.apple.wifi-settings-extension terminal=false"
    echo "Turn Wi-Fi Off | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=off terminal=false refresh=true"
    print_update_item
elif $eth_active; then
    echo "$BADGE | templateImage=$ETH_ICON$BADGE_PARAMS"
    echo "---"
    echo "Open Network Settings | bash=open param1=x-apple.systempreferences:com.apple.Network-Settings.extension terminal=false"
    echo "Turn Wi-Fi On | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=on terminal=false refresh=true"
    print_update_item
else
    echo "$BADGE | templateImage=$NO_CONN_ICON$BADGE_PARAMS"
    echo "---"
    echo "Turn Wi-Fi On | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=on terminal=false refresh=true"
    print_update_item
fi
