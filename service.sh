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
DBDC=2
NSS=2
BW5G=2
TCP_CONG=bbr
COUNTRY=00
PROFILE=default
EOF
fi

# Function to apply all settings
apply_wifi_settings() {
    [ ! -f "$CFG_FILE" ] && return
    . "$CFG_FILE" 2>/dev/null

    [ -z "$QAM256" ] && QAM256=1
    [ -z "$NSS" ] && NSS=2
    [ -z "$BW5G" ] && BW5G=2
    [ -z "$DBDC" ] && DBDC=2
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
        echo "Ap5gBw 2" > /proc/net/wlan/cfg 2>/dev/null
        echo "Sta5gBw 2" > /proc/net/wlan/cfg 2>/dev/null
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

    # Also ensure vendor/firmware/wifi.cfg has persistent settings
    if [ -f /vendor/firmware/wifi.cfg ]; then
        grep -q "Nss 2" /vendor/firmware/wifi.cfg 2>/dev/null || {
            mount -o remount,rw /vendor 2>/dev/null
            mount -o remount,rw / 2>/dev/null
        }
    fi
}

# Apply initial boot settings
apply_wifi_settings
echo "[*] Initial settings applied" >> "$LOG"

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
    while true; do
        sleep 6

        # 1. Keep Web UI alive
        start_web_daemon

        # 2. Check and re-enforce driver settings against reversion
        if [ -f /proc/net/wlan/cfg ]; then
            # Verify if Probe256QAM or Nss reverted
            if ! grep -q "D:Probe256QAM|1" /proc/net/wlan/cfg 2>/dev/null || \
               ! grep -q "D:Nss|2" /proc/net/wlan/cfg 2>/dev/null; then
                apply_wifi_settings
            fi
        fi

        # 3. Check if hostapd_swlan0.conf is running with op_class=126 and patch if needed
        CONF="/data/vendor/wifi/hostapd/hostapd_swlan0.conf"
        if [ -f "$CONF" ]; then
            if grep -q "op_class=126" "$CONF" 2>/dev/null; then
                sed -i 's/op_class=126/op_class=128/g' "$CONF" 2>/dev/null
            fi
        fi
    done
) &

echo "[$(date)] Galaxy Wi-Fi Master Service & Guardian running in background" >> "$LOG"
exit 0
