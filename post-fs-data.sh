#!/system/bin/sh
# ================================================================
# Galaxy Wi-Fi Master Early Boot Setup
# Author: hoc
# ================================================================
MODDIR=${0%/*}

# 1. Early kernel socket buffer tuning for extreme Wi-Fi throughput
echo 16777216 > /proc/sys/net/core/rmem_max 2>/dev/null
echo 16777216 > /proc/sys/net/core/wmem_max 2>/dev/null
echo "4096 87380 16777216" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null
echo "4096 65536 16777216" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null
echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null
echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo cubic > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null

exit 0
