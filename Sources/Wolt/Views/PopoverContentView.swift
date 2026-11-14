import SwiftUI

@MainActor
public struct PopoverContentView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var settings: AppSettings
    
    @State private var showingSettings: Bool = false
    
    public init() {
        self.powerService = PowerService.shared
        self.settings = AppSettings.shared
    }
    
    public init(powerService: PowerService, settings: AppSettings) {
        self.powerService = powerService
        self.settings = settings
    }
    
    public var body: some View {
        let t = powerService.telemetry
        let isCharging = t.batteryPowerWatts > 0.05
        let isAssisting = t.batteryPowerWatts < -0.5 && (t.chargerInputWatts < t.systemLoadWatts - 0.5 || t.chargerInputWatts <= 0.5)
        
        ZStack {
            if showingSettings {
                // ─────────────────────────────────────────────────────────────
                // MINIMALIST SETTINGS PANEL
                // ─────────────────────────────────────────────────────────────
                VStack(spacing: 0) {
                    // Header Bar
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                showingSettings = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Settings")
                            .font(.system(size: 12.5, weight: .semibold))
                        
                        Spacer()
                        
                        // Transparent placeholder for symmetric alignment
                        Text("Back")
                            .font(.system(size: 12))
                            .opacity(0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    Divider().opacity(0.5)
                    
                    // Settings Content
                    VStack(spacing: 12) {
                        // Low Power Mode Toggle
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle(isOn: Binding(
                                get: { powerService.isLowPowerMode },
                                set: { powerService.setLowPowerMode(enabled: $0) }
                            )) {
                                HStack(spacing: 6) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.green)
                                    Text("Low Power Mode")
                                        .font(.system(size: 12))
                                }
                            }
                            .toggleStyle(.switch)
                            
                            if !powerService.isPasswordlessConfigured {
                                Button {
                                    powerService.setupPasswordlessRule { success in
                                        // updated
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "lock.shield")
                                            .font(.system(size: 9.5))
                                        Text("Enable 1-Click Toggle (No Password)")
                                            .font(.system(size: 9.5))
                                    }
                                    .foregroundStyle(.blue)
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 1)
                            }
                        }
                        
                        Divider().opacity(0.4)
                        
                        // Menu Bar Style Picker
                        HStack {
                            Text("Menu Bar Style")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Picker("", selection: $settings.displayMode) {
                                ForEach(MenuBarDisplayMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        
                        Divider().opacity(0.4)
                        
                        // Launch at Login Toggle
                        Toggle(isOn: $settings.launchAtLogin) {
                            Text("Launch at Login")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .toggleStyle(.switch)
                        
                        Divider().opacity(0.4)
                        
                        // Action Buttons
                        HStack(spacing: 10) {
                            Button("Refresh Now") {
                                powerService.triggerImmediateRefresh()
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity)
                            
                            Button("Quit Wolt") {
                                NSApplication.shared.terminate(nil)
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 4)
                        
                        Text("Wolt v1.0.0 • Apple Silicon")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 6)
                    }
                    .padding(16)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: 16)),
                    removal: .opacity.combined(with: .offset(x: 16))
                ))
                
            } else {
                // ─────────────────────────────────────────────────────────────
                // MAIN POWER & HEALTH VIEW (Reference Image Style)
                // ─────────────────────────────────────────────────────────────
                VStack(spacing: 0) {
                    // SECTION 1: BATTERY HEADER
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(t.percentage)")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("%")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if powerService.isLowPowerMode {
                                HStack(spacing: 3) {
                                    Image(systemName: "leaf.fill")
                                        .font(.system(size: 8.5))
                                    Text("Low Power")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundStyle(.yellow)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Color.yellow.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            
                            if t.isPluggedIn {
                                Text(t.isCharging ? "Charging" : (t.percentage >= 95 ? "Full" : "Plugged In"))
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundStyle(t.isCharging ? .green : .secondary)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(t.isCharging ? Color.green.opacity(0.12) : Color.primary.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(t.isPluggedIn ? "Connected to Power" : (powerService.isLowPowerMode ? "Running in Low Power Mode" : "Running on Battery Power"))
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        // Horizontal Battery Level Bar (Capsule Track)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(height: 6.5)
                                
                                let pct = CGFloat(max(0.02, min(1.0, Double(t.percentage) / 100.0)))
                                Capsule()
                                    .fill(t.isCharging ? Color.green : (t.percentage <= 20 ? Color.red : Color.primary.opacity(0.8)))
                                    .frame(width: max(6.5, geo.size.width * pct), height: 6.5)
                            }
                        }
                        .frame(height: 6.5)
                        .padding(.top, 2)
                        
                        // Remaining Time or Bypass State (Clean, non-repeating)
                        Text(t.isPluggedIn && !t.isCharging ? "Power bypass active" : t.timeRemainingDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .padding(.top, 1)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    
                    Divider().opacity(0.5)
                    
                    // SECTION 2: POWER & POWER SOURCE
                    VStack(spacing: 8) {
                        // Power Row
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.blue)
                                    .frame(width: 14)
                                Text("Power")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            let powerWatts = t.isPluggedIn ? t.chargerInputWatts : (t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts)
                            Text(String(format: "%.1f W", powerWatts))
                                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        }
                        
                        // Power Source Row (Mention adapter ONCE here!)
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: t.isPluggedIn ? "powerplug.fill" : "battery.100percent")
                                    .font(.system(size: 11))
                                    .foregroundStyle(t.isPluggedIn ? .green : .secondary)
                                    .frame(width: 14)
                                Text("Power Source")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            Text(t.isPluggedIn ? t.adapter.name : "Battery")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    // SECTION 3: POWER DISTRIBUTION (When Plugged In)
                    if t.isPluggedIn {
                        Divider().opacity(0.5)
                        
                        VStack(spacing: 7) {
                            HStack {
                                Text("Power Distribution")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Total: \(String(format: "%.1fW", max(t.chargerInputWatts, t.systemLoadWatts + max(0, t.batteryPowerWatts))))")
                                    .font(.system(size: 10.5, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            
                            // Dual Proportion Bar
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    if isCharging {
                                        let total = max(1.0, max(t.chargerInputWatts, t.batteryPowerWatts + t.systemLoadWatts))
                                        let battFraction = max(0.04, min(0.96, t.batteryPowerWatts / total))
                                        let sysFraction = max(0.04, 1.0 - battFraction)
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.green)
                                            .frame(width: max(4, geo.size.width * CGFloat(battFraction)))
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.blue)
                                            .frame(width: max(4, geo.size.width * CGFloat(sysFraction)))
                                    } else if isAssisting {
                                        let total = max(0.5, t.systemLoadWatts)
                                        let wallFraction = max(0.0, min(1.0, t.chargerInputWatts / total))
                                        let battFraction = max(0.0, min(1.0, abs(t.batteryPowerWatts) / total))
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.blue)
                                            .frame(width: max(4, geo.size.width * CGFloat(wallFraction)))
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.orange)
                                            .frame(width: max(4, geo.size.width * CGFloat(battFraction)))
                                    } else {
                                        // Hardware Bypass: 100% wall
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.blue)
                                            .frame(width: geo.size.width)
                                    }
                                }
                            }
                            .frame(height: 5)
                            .animation(.smooth(duration: 0.35), value: t.chargerInputWatts)
                            .animation(.smooth(duration: 0.35), value: t.batteryPowerWatts)
                            
                            // Distribution Labels
                            HStack {
                                if isCharging {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.green).frame(width: 5, height: 5)
                                        Text("Battery +\(String(format: "%.1fW", abs(t.batteryPowerWatts)))")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.green)
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.blue).frame(width: 5, height: 5)
                                        Text("System \(String(format: "%.1fW", t.systemLoadWatts))")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.blue)
                                    }
                                } else if isAssisting {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.blue).frame(width: 5, height: 5)
                                        Text("Wall \(String(format: "%.1fW", t.chargerInputWatts))")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.blue)
                                    }
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.orange).frame(width: 5, height: 5)
                                        Text("Battery -\(String(format: "%.1fW", abs(t.batteryPowerWatts)))")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.orange)
                                    }
                                } else {
                                    HStack(spacing: 4) {
                                        Circle().fill(Color.blue).frame(width: 5, height: 5)
                                        Text("System \(String(format: "%.1fW", t.systemLoadWatts)) (100% Wall Power)")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    Divider().opacity(0.5)
                    
                    // SECTION 4: HEALTH, CYCLES & TEMPERATURE (Exact to Image 2)
                    VStack(spacing: 8) {
                        // Health Row
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "heart")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 14)
                                Text("Health")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text("\(Int(t.healthPercentage))%")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        
                        // Cycles Row
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 14)
                                Text("Cycles")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text("\(t.cycleCount)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        
                        // Temperature Row
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 14)
                                Text("Temperature")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text(String(format: "%.1f °C", t.temperatureCelsius))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    
                    Divider().opacity(0.5)
                    
                    // SECTION 5: SETTINGS BUTTON (Exact to Image 2)
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            showingSettings = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                                .frame(width: 14)
                            Text("Settings...")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(x: -16)),
                    removal: .opacity.combined(with: .offset(x: -16))
                ))
            }
        }
        .frame(width: 270)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: showingSettings)
        .onAppear {
            powerService.setWindowVisible(true)
        }
        .onDisappear {
            powerService.setWindowVisible(false)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0s cadence
                powerService.refresh()
            }
        }
    }
}
