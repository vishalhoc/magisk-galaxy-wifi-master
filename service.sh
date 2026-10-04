#!/system/bin/sh
# ================================================================
# Galaxy Wi-Fi Master Late Boot Service & Web Daemon
# Author: hoc
# ================================================================
MODDIR=${0%/*}
LOG=/data/local/tmp/galaxy_wifi_master.log

echo "[$(date)] Galaxy Wi-Fi Master Service starting" > "$LOG"

# Wait for boot completion
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 3

chmod 755 "$MODDIR/system/bin/wifi_master" 2>/dev/null
chmod 755 "$MODDIR/web/cgi-bin/api.cgi" 2>/dev/null
chmod 755 "$MODDIR/action.sh" 2>/dev/null

cp "$MODDIR/system/bin/wifi_master" /data/adb/wifi_master 2>/dev/null
chmod 755 /data/adb/wifi_master 2>/dev/null

# Wait for wlan driver procfs to initialize
WAIT_CNT=0
while [ ! -f /proc/net/wlan/cfg ] && [ $WAIT_CNT -lt 15 ]; do
    sleep 2
    WAIT_CNT=$((WAIT_CNT + 1))
done

CFG_FILE="/data/adb/galaxy_wifi_master.cfg"
if [ ! -f "$CFG_FILE" ]; then
    cat <<EOF > "$CFG_FILE"
QAM256=1
CAM=0
AUTOPERF=1
DBDC=2
TCP_CONG=bbr
COUNTRY=00
PROFILE=default
EOF
fi

# Apply Hardware Accels & Wi-Fi Tunings
if [ -f /proc/net/wlan/cfg ]; then
    # 1. 256-QAM (TurboQAM) Modulation
    QAM_VAL=$(grep '^QAM256=' "$CFG_FILE" | cut -d '=' -f 2)
    [ -z "$QAM_VAL" ] && QAM_VAL=1
    echo "Probe256QAM $QAM_VAL" > /proc/net/wlan/cfg 2>/dev/null
    echo "[*] Probe256QAM set to $QAM_VAL" >> "$LOG"

    # 2. Continuous Access Mode (CAM)
    CAM_VAL=$(grep '^CAM=' "$CFG_FILE" | cut -d '=' -f 2)
    [ "$CAM_VAL" = "1" ] && echo 1 > /proc/net/wlan/setCAM 2>/dev/null

    # 3. Auto Performance Monitor
    AUTO_VAL=$(grep '^AUTOPERF=' "$CFG_FILE" | cut -d '=' -f 2)
    [ -z "$AUTO_VAL" ] && AUTO_VAL=1
    echo "ForceEnable:$AUTO_VAL" > /proc/net/wlan/autoPerfCfg 2>/dev/null

    # 4. DBDC Mode
    DBDC_VAL=$(grep '^DBDC=' "$CFG_FILE" | cut -d '=' -f 2)
    [ -z "$DBDC_VAL" ] && DBDC_VAL=2
    echo "DbdcMode $DBDC_VAL" > /proc/net/wlan/cfg 2>/dev/null

    # 5. Buffer & Packet Aggregation Tuning
    echo "TxMaxAmsduInAmpduLen 8192" > /proc/net/wlan/cfg 2>/dev/null
    echo "NetifStopTh 256" > /proc/net/wlan/cfg 2>/dev/null
    echo "NetifStartTh 128" > /proc/net/wlan/cfg 2>/dev/null
fi

# Apply TCP Congestion
TCP_VAL=$(grep '^TCP_CONG=' "$CFG_FILE" | cut -d '=' -f 2)
[ -z "$TCP_VAL" ] && TCP_VAL=bbr
echo "$TCP_VAL" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null

# Kill any existing or stale web daemon on port 8095
pkill -9 -f "8095" 2>/dev/null
sleep 1

# Start Busybox HTTPD Web Server on port 8095
BUSYBOX="/data/adb/magisk/busybox"
if [ ! -x "$BUSYBOX" ]; then
    BUSYBOX="/system/bin/busybox"
fi

if [ -x "$BUSYBOX" ]; then
    "$BUSYBOX" httpd -p 0.0.0.0:8095 -h "$MODDIR/web" -c "$MODDIR/web/httpd.conf"
    echo "[*] Galaxy Wi-Fi Master Web UI started on http://127.0.0.1:8095" >> "$LOG"
else
    echo "[-] Error: Busybox binary not found" >> "$LOG"
fi

echo "[$(date)] Galaxy Wi-Fi Master Service initialized successfully" >> "$LOG"
exit 0
