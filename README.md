# 📶 Galaxy Wi-Fi Master & Web Control Panel (by hoc)

Extreme MediaTek **MT6853 Dimensity 720** & **MT6631 CONNSYS 2.0 (Mouton ASIC)** Wi-Fi Performance, Low-Latency Gaming Suite, and Glassmorphism Web Control Panel.

Author: **hoc**  
Target Device: **Samsung Galaxy M32 5G (`SM-M326B` / MT6853)**  
Operating System: **OneUI 5.1 / Android 13 (Linux 4.14.186)**  

---

## ⚡ Core Features & Unlocks

### 1. 🚀 256-QAM (TurboQAM) Modulation Enabler
* **Stock Limitation**: Samsung disables 256-QAM (`Probe256QAM=0`) on the 2.4 GHz band by default, capping 40 MHz channel throughput to ~150/300 Mbps.
* **Master Unlock**: Dynamically writes `Probe256QAM 1` directly to `/proc/net/wlan/cfg` at boot, unlocking 256-QAM high-density symbol modulation on both 2.4 GHz and 5 GHz.
* **Performance Gain**: Boosts peak 2.4 GHz link speeds from **150/300 Mbps to 200/400 Mbps (+33% throughput)** on compatible Wi-Fi routers!

### 2. 🎮 Ultra-Low Latency Continuous Access Mode (CAM) Gaming Engine
* **The Problem**: Standard 802.11 power-saving modes (PSM) periodically put the Wi-Fi transceiver to sleep between beacon intervals, resulting in 50–150ms latency spikes and jitter during online gaming.
* **The Solution**: Continuous Access Mode (CAM) locks the MT6631 transceiver into continuous active receive/transmit state via `/proc/net/wlan/setCAM 1`. Eliminates sleep cycles and stabilizes packet delivery to 0–1ms jitter.

### 3. 🌐 Dual Band Dual Concurrent (DBDC) Engine
* Unlocks hardware-level simultaneous dual-band concurrent operation (`DbdcMode 2` on MT6631), allowing simultaneous connection to a 5 GHz uplink while broadcasting a 2.4 GHz Hotspot (`swlan0` + `wlan0`).

### 4. 🔓 All-Channel & DFS Restrictions Override
* **The Problem**: Samsung's stock `/vendor/etc/wifi/indoorchannel.info` forces strict DFS radar detection restrictions and disables 5 GHz channels (DFS channels 52–144 and UNII-3 channels 149–165) for SoftAP and ad-hoc networks across several regulatory domains.
* **The Solution**: Systemless overlay removes indoor-only channel blocks, unlocking all 5GHz channels (36–165) and 2.4GHz channels (1–14) for both Station and Hotspot broadcasting.

### 5. 📦 Packet Aggregation & Network Buffer Tuning
* Configures 8K A-MSDU aggregation (`TxMaxAmsduInAmpduLen 8192`) and queue thresholds (`NetifStartTh 128`, `NetifStopTh 256`) to maximize frame efficiency.
* Automatically tunes Linux kernel socket buffers to 16MB (`net.core.rmem_max=16777216`, `net.core.wmem_max=16777216`).
* Switches TCP congestion control to **BBR** (Google Bottleneck Bandwidth and RTT).

### 6. 🌐 Glassmorphism Web Control Panel (Port 8095)
* Built-in lightweight web dashboard running natively on port **`8095`**:
  * **Dashboard**: Live signal gauge (dBm), SSID/BSSID, operating frequency, channel, PHY link speed, IP, gateway, and live traffic stats.
  * **Feature Accelerators**: One-click toggles for 256-QAM, CAM Gaming Mode, AutoPerf Monitor, DBDC Concurrency, Country Code selector, and TCP Congestion algorithms.
  * **Hotspot & Tethering**: Change SSID, password, band (2.4 GHz vs 5 GHz), channel, and view connected clients with instant MAC blocking.
  * **Live `/proc/net/wlan/cfg` Editor**: Search and tune all 120+ MediaTek driver parameters in real-time.
  * **Quick Profiles**: Instant switches for `[🎮 Gaming Mode]`, `[🚀 Max Throughput]`, `[🔋 Battery Saver]`, and `[↺ Stock Reset]`.

---

## 🛠️ CLI Usage (`wifi_master`)

The module provides a command-line interface executable from root shell:

```bash
# View complete JSON telemetry & hardware state
su -c wifi_master status

# Toggle 256-QAM (TurboQAM)
su -c wifi_master set_qam256 1

# Toggle Ultra-Low Latency Continuous Access Mode (CAM)
su -c wifi_master set_cam 1

# Apply Quick Profile (gaming | max_throughput | battery_saver | default)
su -c wifi_master apply_profile gaming

# Change TCP congestion control algorithm
su -c wifi_master set_tcp bbr

# Set regulatory country code (00=Global, IN=India, US=USA, EU=Europe)
su -c wifi_master set_country IN

# Dump all 120+ live driver parameters in JSON
su -c wifi_master dump_cfg
```

---

## 📱 Accessing the Web Control Panel

1. Connect to Wi-Fi or turn on Hotspot.
2. Open any web browser on your phone and navigate to:
   ```
   http://127.0.0.1:8095
   ```
3. Or tap the **Action** button on the `Galaxy Wi-Fi Master` card inside the Magisk App!
