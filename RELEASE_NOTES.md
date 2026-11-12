# Release v1.0.0 — Wolt for macOS (Apple Silicon)

> **Real-time battery & power flow intelligence engine for Apple Silicon Macs.**

Wolt is a native, ultra-lightweight menu bar companion that connects directly to the Apple Power Management Unit (PMU) and hardware registers to provide real-time visibility into power flow, live wattage, battery health, thermal status, and charging profiles.

---

### ⚡ What's New in v1.0.0

#### 1. Live Power Flow Distribution Engine
* **Direct PMU Telemetry:** Queries Apple Silicon `PowerTelemetryData` hardware registers to display true instantaneous wattage to the milliwatt.
* **Dual-Proportion Power Flow Bar:**
  * **Charging Mode:** Visualizes power split between battery cell charging (Green) and Mac system consumption (Blue).
  * **Supplemental Battery Mode:** When system load exceeds charger delivery (or charger is idle), dynamically visualizes supplemental power assist from battery (Orange) and wall input (Blue).
* **Zero Formatting Anomalies:** Strict sign enforcement with accurate absolute wattages and mathematically balanced percentages.

#### 2. USB-IF Vendor ID Decoding
* Detects authoritative USB-PD Vendor IDs directly from `FedDetails` hardware ports.
* Accurately brands third-party chargers (e.g. **Xiaomi 67W Charger**, **Anker**, **Ugreen**, **Samsung**, **Apple**) instead of generic "pd charger" or false vendor names.

#### 3. Battery Health & Real-Time Thermal Sensing
* **Hardware Thermal Telemetry:** Direct temperature sensor extraction from `AppleSmartBatteryPack` in Celsius and Fahrenheit with thermal state badges (*Optimal (Cool)*, *Warm*, *Elevated*).
* **Longevity & Degradation Analytics:** Real-time chemical health percentage against factory design capacity, cycle count progress bar (1,000-cycle rating), voltage, and instantaneous amperage.

#### 4. Adaptive Energy-Saving Architecture
* **Active Mode (Popover Open):** Calm, smooth 2.0-second refresh cadence with native `.numericText()` continuous number rolling.
* **Idle Mode (Popover Closed):** Relaxes to a 10.0-second background heartbeat at **0.0% CPU usage**, respecting macOS App Nap.
* **Instant AC Transitions:** Zero-latency kernel interrupts (`IOPSNotificationCreateRunLoopSource`) on cable plug/unplug with immediate physical pin detection (`ExternalConnected`).

#### 5. Dual-Engine Launch at Login
* **Native Apple API:** Registered with `ServiceManagement` (`SMAppService.mainApp`) for seamless macOS 13+ System Settings integration.
* **High-Reliability LaunchAgent Fallback:** Configures `~/Library/LaunchAgents/com.wolt.mac.plist` with `RunAtLoad = true` pointing to `/Applications/Wolt.app` for guaranteed startup across all macOS reboots.

#### 6. Native macOS Design
* Modern glass blur popover interface with segmented tabs (**Power**, **Health**, **Settings**).
* Customizable menu bar displays: *Icon + Percentage*, *Percentage Only*, *Icon Only*, *Icon + Wattage*.
* 10-resolution Retina application icon set (`16x16` up to `1024x1024@2x`).

---

### 💻 System Requirements
* **Architecture:** Apple Silicon (M1, M2, M3, M4, Pro, Max, Ultra)
* **OS Version:** macOS 14.0 Sonoma or macOS 15.0+ Sequoia / newer
* **Permissions:** 100% Read-Only, Zero Admin / Root Privileges Required (No `sudo`, no Low Power Mode overrides)

---

### 📦 Installation

1. Download **`Wolt-1.0.0-arm64.dmg`** below.
2. Open the disk image and drag **Wolt** into your **Applications** folder.
3. Launch Wolt from Applications or Spotlight. It will appear directly in your menu bar.

---

### 🔐 Checksums & Verification

| Asset | SHA-256 Checksum |
| :--- | :--- |
| **`Wolt-1.0.0-arm64.dmg`** | `dab3b77ff9aeb748dc1cd5845b272c0a639602e948a808abfbd18ee1825be295` |
