#!/system/bin/sh
# ================================================================
# Galaxy Wi-Fi Master Late Boot Service & Continuous Guardian
# Author: hoc
# ================================================================
MODDIR=${0%/*}
LOG=/data/local/tmp/galaxy_wifi_master.log

echo "[$(date)] Galaxy Wi-Fi Master Service starting" > "$LOG"

# Wait for Android boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 3

chmod 755 "$MODDIR/system/bin/wifi_master" 2>/dev/null
chmod 755 "$MODDIR/web/cgi-bin/api.cgi" 2>/dev/null
chmod 755 "$MODDIR/action.sh" 2>/dev/null

cp "$MODDIR/system/bin/wifi_master" /data/adb/wifi_master 2>/dev/null
chmod 755 /data/adb/wifi_master 2>/dev/null

# Default configuration file
CFG_FILE="/data/adb/galaxy_wifi_master.cfg"
if [ ! -f "$CFG_FILE" ]; then
    cat <<EOF > "$CFG_FILE"
QAM256=1
CAM=0
AUTOPERF=1
DBDC=0
NSS=1
BW5G=2
TCP_CONG=bbr
COUNTRY=00
PROFILE=default
DIRECT_MODEM_HOTSPOT=1
EOF
fi

# Function to apply all settings
apply_wifi_settings() {
    [ ! -f "$CFG_FILE" ] && return
    . "$CFG_FILE" 2>/dev/null

    [ -z "$QAM256" ] && QAM256=1
    [ -z "$NSS" ] && NSS=1
    [ -z "$BW5G" ] && BW5G=2
    [ -z "$DBDC" ] && DBDC=0
    [ -z "$CAM" ] && CAM=0
    [ -z "$AUTOPERF" ] && AUTOPERF=1
    [ -z "$TCP_CONG" ] && TCP_CONG=bbr

    if [ -f /proc/net/wlan/driver ]; then
        echo "SET_NSS $NSS" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_AMPDU_TX 1" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_AMPDU_RX 1" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_AMSDU_TX 1" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_AMSDU_RX 1" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_BF 1" > /proc/net/wlan/driver 2>/dev/null
        echo "SET_QOS 1" > /proc/net/wlan/driver 2>/dev/null
        if [ "$CAM" = "1" ]; then
            echo "SET_PWR_CTRL 0" > /proc/net/wlan/driver 2>/dev/null
        fi
    fi

    if [ -f /proc/net/wlan/cfg ]; then
        echo "Probe256QAM $QAM256" > /proc/net/wlan/cfg 2>/dev/null
        echo "Nss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Ap6gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Ap5gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Ap2gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Go6gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Go5gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Go2gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Sta1Nss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Sta5gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "Sta2gNss $NSS" > /proc/net/wlan/cfg 2>/dev/null
        echo "DbdcMode $DBDC" > /proc/net/wlan/cfg 2>/dev/null
        echo "ApBw $BW5G" > /proc/net/wlan/cfg 2>/dev/null
        echo "Ap5gBw $BW5G" > /proc/net/wlan/cfg 2>/dev/null
        echo "Sta5gBw $BW5G" > /proc/net/wlan/cfg 2>/dev/null
        echo "SapOverwriteAcsChnlBw 1" > /proc/net/wlan/cfg 2>/dev/null
        echo "TxMaxAmsduInAmpduLen 8192" > /proc/net/wlan/cfg 2>/dev/null
        echo "NetifStopTh 256" > /proc/net/wlan/cfg 2>/dev/null
        echo "NetifStartTh 128" > /proc/net/wlan/cfg 2>/dev/null
    fi

    if [ -f /proc/net/wlan/setCAM ]; then
        [ "$CAM" = "1" ] && echo 1 > /proc/net/wlan/setCAM 2>/dev/null
    fi

    if [ -f /proc/net/wlan/autoPerfCfg ]; then
        echo "ForceEnable:$AUTOPERF" > /proc/net/wlan/autoPerfCfg 2>/dev/null
    fi

    echo "$TCP_CONG" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
}

# Apply initial boot settings
apply_wifi_settings
echo "[*] Initial settings applied" >> "$LOG"

# Apply Direct Modem-to-Hotspot Passthrough & Carrier Bypass
sh "$MODDIR/system/bin/wifi_master" direct_modem enable >> "$LOG" 2>&1
echo "[*] Direct modem-to-hotspot pipeline enabled" >> "$LOG"

# Start Busybox HTTPD Web Server on port 8095
start_web_daemon() {
    if ! pgrep -f "httpd.*8095" >/dev/null 2>&1; then
        pkill -9 -f "8095" 2>/dev/null
        sleep 1
        BUSYBOX="/data/adb/magisk/busybox"
        [ ! -x "$BUSYBOX" ] && BUSYBOX="/system/bin/busybox"
        if [ -x "$BUSYBOX" ]; then
            "$BUSYBOX" httpd -p 0.0.0.0:8095 -h "$MODDIR/web" -c "$MODDIR/web/httpd.conf"
            echo "[*] Web UI started on http://127.0.0.1:8095" >> "$LOG"
        fi
    fi
}

start_web_daemon

# Background Persistent Guardian Loop (runs detached)
(
    KEEPALIVE_CNT=0
    while true; do
        sleep 6

        # 1. Keep Web UI alive
        start_web_daemon

        # 2. Check and re-enforce driver settings against reversion
        if [ -f /proc/net/wlan/cfg ]; then
            if ! grep -q "D:Probe256QAM|1" /proc/net/wlan/cfg 2>/dev/null; then
                apply_wifi_settings
            fi
        fi

        # 4. Check if hostapd_swlan0.conf is running with op_class=126 and patch if needed
        CONF="/data/vendor/wifi/hostapd/hostapd_swlan0.conf"
        if [ -f "$CONF" ]; then
            if grep -q "op_class=126" "$CONF" 2>/dev/null; then
                sed -i 's/op_class=126/op_class=128/g' "$CONF" 2>/dev/null
            fi
        fi

        # 5. Maintain Direct Modem-to-Hotspot Passthrough & Upstream Routing
        DM_CFG=$(grep "^DIRECT_MODEM_HOTSPOT=" /data/adb/galaxy_wifi_master.cfg 2>/dev/null | cut -d '=' -f 2-)
        [ -z "$DM_CFG" ] && DM_CFG="1"
        if [ "$DM_CFG" = "1" ]; then
            # Sync dynamic policy routing across cellular reconnections
            sh "$MODDIR/system/bin/wifi_master" sync_direct_routing 2>/dev/null || true

            # Guarantee PURE_FORWARD and PURE_NAT remain at top of iptables
            if ! iptables -C FORWARD -j PURE_FORWARD 2>/dev/null; then
                iptables -w 2 -I FORWARD 1 -j PURE_FORWARD 2>/dev/null || true
            fi
            if ! iptables -t nat -C POSTROUTING -j PURE_NAT 2>/dev/null; then
                iptables -w 2 -t nat -I POSTROUTING 1 -j PURE_NAT 2>/dev/null || true
            fi

            # Guarantee TTL normalization & TCPMSS PMTU clamp survive network resets
            iptables -w 2 -t mangle -C POSTROUTING -j TTL --ttl-set 64 2>/dev/null || \
                iptables -w 2 -t mangle -I POSTROUTING 1 -j TTL --ttl-set 64 2>/dev/null || true
            iptables -w 2 -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || \
                iptables -w 2 -t mangle -I FORWARD 1 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true

            # Keep carrier tethering offload disabled & DUN bypassed
            settings put global tether_dun_required 0 2>/dev/null
            settings put global tether_offload_disabled 1 2>/dev/null
            setprop net.tethering.noprovisioning true 2>/dev/null

            # Periodic 30s cellular WAN keepalive
            KEEPALIVE_CNT=$((KEEPALIVE_CNT + 1))
            if [ $KEEPALIVE_CNT -ge 5 ]; then
                KEEPALIVE_CNT=0
                WAN_IF=$(ip -4 -o addr show 2>/dev/null | grep -E "v4-rmnet|rmnet" | awk '{print $2}' | head -n1)
                if [ -n "$WAN_IF" ]; then
                    ping -c 1 -W 2 -I "$WAN_IF" 1.1.1.1 >/dev/null 2>&1 || true
                fi
            fi
        fi
    done
) &

echo "[$(date)] Galaxy Wi-Fi Master Service & Guardian running in background" >> "$LOG"
exit 0
