#!/bin/bash
# <swiftbar.title>Network Status</swiftbar.title>
# <swiftbar.version>1.2</swiftbar.version>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

WIFI_STRONG_ICON="__WIFI_STRONG_ICON__"
WIFI_MEDIUM_ICON="__WIFI_MEDIUM_ICON__"
WIFI_WEAK_ICON="__WIFI_WEAK_ICON__"
ETH_ICON="__ETH_ICON__"
NO_CONN_ICON="__NO_CONN_ICON__"
SEARCHING_ICON="__SEARCHING_ICON__"
INSTALLED_SHA="__INSTALLED_SHA__"
REPO_DIR="__REPO_DIR__"

# ── Check for updates (rate-limited to once per hour) ─────────────────────────
CHECK_FILE="/tmp/mac-netswitch-update-check"
LATEST_SHA_FILE="/tmp/mac-netswitch-latest-sha"
now=$(date +%s)
last_check=0
[ -f "$CHECK_FILE" ] && last_check=$(cat "$CHECK_FILE")

if (( now - last_check > 300 )); then
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

# Wi-Fi interface is "searching" when powered on but not yet associated
air_active=false
if [ -n "$air_name" ] && ifconfig "$air_name" 2>/dev/null | grep -q "status: active"; then
    air_active=true
fi

if $eth_active; then
    echo "$BADGE | templateImage=$ETH_ICON$BADGE_PARAMS"
    echo "---"
    echo "Open Network Settings | bash=open param1=x-apple.systempreferences:com.apple.Network-Settings.extension terminal=false"
    echo "Turn Wi-Fi On | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=on terminal=false refresh=true"
    print_update_item
elif [ "$air_status" = "On" ] && $air_active; then
    # Signal quality is judged by SNR (signal - noise), which is closer to what
    # macOS itself weighs than raw RSSI. system_profiler is slow (~1-2s), so it
    # runs in the background and we read the cached SNR. Parse ONLY the current
    # network's "Signal / Noise" line (under "Current Network Information") — the
    # other such lines are nearby networks and must be ignored.
    SNR_CACHE="/tmp/mac-netswitch-snr"
    SNR_TS="/tmp/mac-netswitch-snr-ts"
    LEVEL_FILE="/tmp/mac-netswitch-wifi-level"
    snr_last=0
    [ -f "$SNR_TS" ] && snr_last=$(cat "$SNR_TS")
    if (( now - snr_last > 5 )); then
        echo "$now" > "$SNR_TS"
        (system_profiler SPAirPortDataType 2>/dev/null | awk '/Current Network Information/{f=1} f && /Signal \/ Noise/{print ($4 - $7); exit}' > "$SNR_CACHE") &
    fi
    snr=""
    [ -f "$SNR_CACHE" ] && snr=$(head -n1 "$SNR_CACHE")
    [[ "$snr" =~ ^-?[0-9]+$ ]] || snr=""

    # Map SNR to a 3-level bar count with hysteresis so the icon holds steady and
    # doesn't flicker at a boundary (like the native icon). Nominal cut points are
    # 30 dB (full) and 18 dB (medium); a +/-3 dB dead-zone must be crossed to move.
    last_level=""
    [ -f "$LEVEL_FILE" ] && last_level=$(head -n1 "$LEVEL_FILE")
    [[ "$last_level" =~ ^[123]$ ]] || last_level=""
    level=3
    if [ -n "$snr" ]; then
        if [ -z "$last_level" ]; then
            if   [ "$snr" -ge 30 ]; then level=3
            elif [ "$snr" -ge 18 ]; then level=2
            else                         level=1
            fi
        else
            case "$last_level" in
                3) if   [ "$snr" -lt 15 ]; then level=1
                   elif [ "$snr" -lt 27 ]; then level=2
                   else                         level=3
                   fi ;;
                2) if   [ "$snr" -ge 33 ]; then level=3
                   elif [ "$snr" -lt 15 ]; then level=1
                   else                         level=2
                   fi ;;
                1) if   [ "$snr" -ge 33 ]; then level=3
                   elif [ "$snr" -ge 21 ]; then level=2
                   else                         level=1
                   fi ;;
            esac
        fi
        echo "$level" > "$LEVEL_FILE"
    elif [ -n "$last_level" ]; then
        level=$last_level
    fi

    case "$level" in
        3) WIFI_ICON="$WIFI_STRONG_ICON" ;;
        2) WIFI_ICON="$WIFI_MEDIUM_ICON" ;;
        1) WIFI_ICON="$WIFI_WEAK_ICON" ;;
        *) WIFI_ICON="$WIFI_STRONG_ICON" ;;
    esac
    echo "$BADGE | templateImage=$WIFI_ICON$BADGE_PARAMS"
    echo "---"
    ssid=$(networksetup -getairportnetwork "$air_name" 2>/dev/null | sed 's/Current Wi-Fi Network: //')
    echo "$ssid" | grep -q "not associated" || echo "$ssid"
    echo "---"
    echo "Open Wi-Fi Settings | bash=open param1=x-apple.systempreferences:com.apple.wifi-settings-extension terminal=false"
    echo "Turn Wi-Fi Off | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=off terminal=false refresh=true"
    print_update_item
elif [ "$air_status" = "On" ]; then
    echo "$BADGE | templateImage=$SEARCHING_ICON$BADGE_PARAMS"
    echo "---"
    echo "Searching for network…"
    echo "---"
    echo "Open Wi-Fi Settings | bash=open param1=x-apple.systempreferences:com.apple.wifi-settings-extension terminal=false"
    echo "Turn Wi-Fi Off | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=off terminal=false refresh=true"
    print_update_item
else
    echo "$BADGE | templateImage=$NO_CONN_ICON$BADGE_PARAMS"
    echo "---"
    echo "Turn Wi-Fi On | bash=/usr/sbin/networksetup param1=-setairportpower param2=$air_name param3=on terminal=false refresh=true"
    print_update_item
fi
