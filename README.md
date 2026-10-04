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

### 2. ⚡ 5GHz Hotspot & Wi-Fi 866.7 Mbps / 1733 Mbps Speed Unlock (2x2 MIMO)
* **Stock Limitation**: Samsung's stock driver hardcodes `Nss=1` (1 Spatial Stream / 1x1 SISO) and `ApBw=2` (80MHz). Under 802.11ac VHT80 MCS9, this strictly caps peak 5GHz Hotspot and link speeds to **433.3 Mbps**.
* **Master Unlock**: The MT6631 CONNSYS 2.0 hardware natively supports 2 Spatial Streams (`D:Nss|2`, `D:Ap5gNss|2`) and 160MHz bandwidth (`D:ApBw|3`). By dynamically writing `Nss 2`, `Ap5gNss 2`, `Go5gNss 2`, `ApBw 3`, and `Ap5gBw 3` to `/proc/net/wlan/cfg`, the module activates **2x2 MIMO**:
  * **80 MHz, 2x2 MIMO**: **866.7 Mbps** (2x speed boost over stock 433 Mbps!)
  * **160 MHz, 2x2 MIMO**: **1733.3 Mbps** (4x theoretical peak throughput!)

### 3. 🎮 Ultra-Low Latency Continuous Access Mode (CAM) Gaming Engine
* **The Problem**: Standard 802.11 power-saving modes (PSM) periodically put the Wi-Fi transceiver to sleep between beacon intervals, resulting in 50–150ms latency spikes and jitter during online gaming.
* **The Solution**: Continuous Access Mode (CAM) locks the MT6631 transceiver into continuous active receive/transmit state via `/proc/net/wlan/setCAM 1`. Eliminates sleep cycles and stabilizes packet delivery to 0–1ms jitter.

### 4. 🌐 Dual Band Dual Concurrent (DBDC) Engine
* Unlocks hardware-level simultaneous dual-band concurrent operation (`DbdcMode 2` on MT6631), allowing simultaneous connection to a 5 GHz uplink while broadcasting a 2.4 GHz Hotspot (`swlan0` + `wlan0`).

### 5. 🔓 All-Channel & DFS Restrictions Override
* **The Problem**: Samsung's stock `/vendor/etc/wifi/indoorchannel.info` forces strict DFS radar detection restrictions and disables 5 GHz channels (DFS channels 52–144 and UNII-3 channels 149–165) for SoftAP and ad-hoc networks across several regulatory domains.
* **The Solution**: Systemless overlay removes indoor-only channel blocks, unlocking all 5GHz channels (36–165) and 2.4GHz channels (1–14) for both Station and Hotspot broadcasting.

### 6. 📦 Packet Aggregation & Network Buffer Tuning
* Configures 8K A-MSDU aggregation (`TxMaxAmsduInAmpduLen 8192`) and queue thresholds (`NetifStartTh 128`, `NetifStopTh 256`) to maximize frame efficiency.
* Automatically tunes Linux kernel socket buffers to 16MB (`net.core.rmem_max=16777216`, `net.core.wmem_max=16777216`).
* Switches TCP congestion control to **BBR** (Google Bottleneck Bandwidth and RTT).

### 7. 🌐 Glassmorphism Web Control Panel (Port 8095)
* Built-in lightweight web dashboard running natively on port **`8095`**:
  * **Dashboard**: Live signal gauge (dBm), SSID/BSSID, operating frequency, channel, PHY link speed, IP, gateway, and live traffic stats.
  * **Feature Accelerators**: One-click toggles for 256-QAM, CAM Gaming Mode, 2x2 MIMO 866M Boost, 160MHz Bandwidth, AutoPerf Monitor, DBDC Concurrency, Country Code selector, and TCP Congestion algorithms.
  * **Hotspot & Tethering**: Change SSID, password, band (2.4 GHz vs 5 GHz), channel, toggle 866 Mbps MIMO boost, and view connected clients with instant MAC blocking.
  * **Live `/proc/net/wlan/cfg` Editor**: Search and tune all 120+ MediaTek driver parameters in real-time.
### 8. ⚡ Clean Direct Modem-to-Hotspot Engine & Carrier Bypass
* **Wire-Speed Zero-Restriction Forwarding**: Directly connects wireless clients on Samsung Mobile Hotspot (`swlan0`) or Virtual AP (`ap0`) to the cellular WAN interface (`v4-rmnet*` / `rmnet*`).
* **Complete Carrier Tethering Bypass**:
  * **TTL Normalization (`TTL=64`)**: Hides tethered devices from carrier deep packet inspection (DPI).
  * **TCP MSS Clamping to PMTU**: Prevents packet fragmentation across 4G/5G mobile networks.
  * **Encrypted/Clean DNS Redirection**: Redirects DNS queries directly to Cloudflare (`1.1.1.1`) and Google (`8.8.8.8`), bypassing ISP filtering.
  * **BPF & DUN APN Shield**: Disables eBPF tether throttling and bypasses carrier DUN APN requirements.
  * **Dynamic Policy Routing Guardian**: Tracks cellular table changes (e.g. 5G NSA/SA handovers) and binds `swlan0` (`pref 7010`) and `ap0` (`pref 7011`) with return path links (`pref 7000..7002`).

---

## 🛠️ CLI Usage (`wifi_master`)

The module provides a command-line interface executable from root shell:

```bash
# View complete JSON telemetry & hardware state
su -c wifi_master status

# Toggle Clean Direct Modem-to-Hotspot Passthrough (enable | disable | status)
su -c wifi_master direct_modem enable

# Toggle 2x2 MIMO 866 Mbps Boost (2 = 2x2 MIMO 866M, 1 = 1x1 SISO 433M)
su -c wifi_master set_nss 2

# Toggle 5GHz Bandwidth (3 = 160 MHz Ultra, 2 = 80 MHz Standard)
su -c wifi_master set_bw5g 3

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
