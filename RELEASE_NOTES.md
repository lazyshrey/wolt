# Release v1.1 — Wolt for macOS (Apple Silicon)

> **Real-time battery & power flow intelligence engine for Apple Silicon Macs.**

Wolt is a native, ultra-lightweight menu bar companion that connects directly to the Apple Power Management Unit (PMU) and hardware registers to provide real-time visibility into power flow, live wattage, battery health, thermal status, and charging profiles.

---

### ⚡ What's New in v1.1

#### 1. Native `NSPopover` with Pointer Notch & Spring Animation
* Replaced detached window panel with a true native AppKit `NSPopover` anchored directly to your menu bar icon.
* Features Apple's native pointer beak/notch and silky-smooth downward slide-in spring physics.
* Automatically renders the system active capsule highlight around the menu bar button while open.

#### 2. Home Screen Low Power Mode Toggle
* Effortlessly toggle Low Power Mode on and off with a single click directly from the popover home screen.
* Features real-time bidirectional synchronization with macOS System Settings and Control Center via `NSProcessInfoPowerStateDidChange`.
* Visual status feedback: glows in native Apple amber/yellow (`[leaf.fill Low Power]`) and adapts the battery level bar when active.

#### 3. Dedicated Battery Health & Electrical Diagnostics Page
* Accessible via a clean navigation link on the home screen with instant `< Back` navigation.
* **Live Current Drain / Flow:** Real-time milliampere (mA) consumption (e.g. `209 mA`).
* **Pack Voltage & Wattage:** High-precision voltage (`12.40 V`) and live battery power flow (`2.59 W`).
* **Capacity Analytics:** Chemical maximum health percentage, current charge vs. design capacity in mAh, and rated hardware cycle counts (`4 / 1,000`).

#### 4. Instantaneous Energy Balance & Zero Gas-Gauge Lag
* Completely eliminated the 30–45 second Texas Instruments gas-gauge rolling-average delay when plugging in the charger through real-time energy reconciliation ($P_{\text{Wall}} = P_{\text{System}} + P_{\text{Battery}}$).
* Instantly reflects Hardware Power Bypass mode at $\ge 95\%$ or when battery cells are idle.

#### 5. Zero Clutter & Redundancy
* Purged all nested cards ("cards inside cards") and duplicate metric callouts.
* Power adapter rating is shown once in the Power Source row without redundant badges.
* Clean 270px compact native popover footprint.

---

### 💻 System Requirements
* **Architecture:** Apple Silicon (M1, M2, M3, M4, Pro, Max, Ultra)
* **OS Version:** macOS 14.0 Sonoma or macOS 15.0+ Sequoia / newer
* **Permissions:** 100% Read-Only hardware telemetry.

---

### 📦 Installation

1. Download **`Wolt-1.1-arm64.dmg`** below.
2. Open the disk image and drag **Wolt** into your **Applications** folder.
3. Launch Wolt from Applications or Spotlight. It will appear directly in your menu bar.

---

### 🔐 Checksums & Verification

| Asset | SHA-256 Checksum |
| :--- | :--- |
| **`Wolt-1.1-arm64.dmg`** | `fc999acca24c9fb05e3bb4696d9262091190bf34cd33565a7dde315b27016693` |
