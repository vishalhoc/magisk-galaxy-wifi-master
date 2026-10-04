#!/system/bin/sh
# ================================================================
# Galaxy Wi-Fi Master CGI API Handler
# Author: hoc
# ================================================================

printf "Content-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nCache-Control: no-cache, no-store\r\n\r\n"

QUERY="${QUERY_STRING}"
if [ "$REQUEST_METHOD" = "POST" ] && [ -n "$CONTENT_LENGTH" ] && [ "$CONTENT_LENGTH" -gt 0 ] 2>/dev/null; then
    read -n "$CONTENT_LENGTH" POST_DATA
    if [ -n "$POST_DATA" ]; then
        QUERY="$POST_DATA"
    fi
fi

get_param() {
    raw=$(echo "$QUERY" | tr '&' '\n' | grep "^$1=" | head -n 1 | cut -d '=' -f 2- | tr -d '\r\n')
    echo "$raw" | sed 's/%2C/,/g; s/%20/ /g; s/%2B/+/g; s/%2F/\//g; s/%3A/:/g; s/%26/\&/g'
}

ACTION=$(get_param action)
VAL=$(get_param val)
KEY=$(get_param key)
SSID=$(get_param ssid)
PASS=$(get_param pass)
BAND=$(get_param band)
CHAN=$(get_param chan)
MAC=$(get_param mac)

[ -z "$ACTION" ] && ACTION="status"

WM="/data/adb/modules/galaxy-wifi-master/system/bin/wifi_master"
if [ ! -x "$WM" ]; then
    WM="/system/bin/wifi_master"
fi
if [ ! -x "$WM" ]; then
    WM="/data/local/tmp/wifi_master"
fi

case "$ACTION" in
    status)
        sh "$WM" status
        ;;
    set_qam256)
        sh "$WM" set_qam256 "$VAL"
        ;;
    set_cam)
        sh "$WM" set_cam "$VAL"
        ;;
    set_autoperf)
        sh "$WM" set_autoperf "$VAL"
        ;;
    set_dbdc)
        sh "$WM" set_dbdc "$VAL"
        ;;
    set_nss)
        sh "$WM" set_nss "$VAL"
        ;;
    set_bw5g)
        sh "$WM" set_bw5g "$VAL"
        ;;
    set_country)
        sh "$WM" set_country "$VAL"
        ;;
    set_tcp)
        sh "$WM" set_tcp "$VAL"
        ;;
    set_wlan_cfg)
        sh "$WM" set_wlan_cfg "$KEY" "$VAL"
        ;;
    set_wifi)
        sh "$WM" set_wifi "$VAL"
        ;;
    set_hotspot)
        sh "$WM" set_hotspot "$VAL"
        ;;
    set_hotspot_cfg)
        sh "$WM" set_hotspot_cfg "$SSID" "$PASS" "$BAND" "$CHAN"
        ;;
    block_mac)
        sh "$WM" block_mac "$MAC"
        ;;
    unblock_mac)
        sh "$WM" unblock_mac "$MAC"
        ;;
    apply_profile)
        sh "$WM" apply_profile "$VAL"
        ;;
    dump_cfg)
        sh "$WM" dump_cfg
        ;;
    *)
        echo "{\"success\":false,\"error\":\"Unknown action: $ACTION\"}"
        ;;
esac

exit 0
