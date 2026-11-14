import SwiftUI

enum PopoverPage {
    case home
    case health
    case settings
}

@MainActor
public struct PopoverContentView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var settings: AppSettings
    
    @State private var activePage: PopoverPage = .home
    
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
            switch activePage {
            case .home:
                homeView(t: t, isCharging: isCharging, isAssisting: isAssisting)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: -16)),
                        removal: .opacity.combined(with: .offset(x: -16))
                    ))
            case .health:
                healthView(t: t)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 16)),
                        removal: .opacity.combined(with: .offset(x: 16))
                    ))
            case .settings:
                settingsView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 16)),
                        removal: .opacity.combined(with: .offset(x: 16))
                    ))
            }
        }
        .frame(width: 270)
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: activePage)
        .onAppear {
            powerService.setWindowVisible(true)
        }
        .onDisappear {
            powerService.setWindowVisible(false)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                powerService.refresh()
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // 1. HOME SCREEN (Clean Reference Layout)
    // ─────────────────────────────────────────────────────────────────────────
    private func homeView(t: BatteryTelemetry, isCharging: Bool, isAssisting: Bool) -> some View {
        VStack(spacing: 0) {
            // SECTION 1: BATTERY HEADER & LOW POWER TOGGLE
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(t.percentage)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    // Home Screen Quick Low Power Mode Button
                    Button {
                        powerService.toggleLowPowerMode()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: powerService.isLowPowerMode ? "leaf.fill" : "leaf")
                                .font(.system(size: 9.5, weight: .semibold))
                            Text(powerService.isLowPowerMode ? "Low Power" : "Low Power")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(powerService.isLowPowerMode ? Color.yellow : Color.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(powerService.isLowPowerMode ? Color.yellow.opacity(0.16) : Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(powerService.isLowPowerMode ? Color.yellow.opacity(0.35) : Color.clear, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Low Power Mode")
                    
                    if t.isPluggedIn {
                        Text(t.isCharging ? "Charging" : (t.percentage >= 95 ? "Full" : "Plugged In"))
                            .font(.system(size: 10, weight: .semibold))
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
                        let barColor: Color = {
                            if t.isCharging { return .green }
                            if powerService.isLowPowerMode { return .yellow }
                            if t.percentage <= 20 { return .red }
                            return .primary.opacity(0.8)
                        }()
                        
                        Capsule()
                            .fill(barColor)
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
                
                // Power Source Row
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
            
            // SECTION 4: TEMPERATURE & HEALTH PAGE NAVIGATION
            VStack(spacing: 6) {
                // Temperature Row (Always visible on home screen)
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
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                // Dedicated Health Page Link Row
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        activePage = .health
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 14)
                        Text("Battery Health & Details")
                            .font(.system(size: 12))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(Int(t.healthPercentage))%")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 6)
            
            Divider().opacity(0.5)
            
            // SECTION 5: SETTINGS BUTTON
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    activePage = .settings
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // 2. DEDICATED HEALTH & DIAGNOSTICS PAGE
    // (Milliampere drain, voltage, cycle count, capacity breakdown)
    // ─────────────────────────────────────────────────────────────────────────
    private func healthView(t: BatteryTelemetry) -> some View {
        VStack(spacing: 0) {
            // Header Bar with Back Button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        activePage = .home
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
                
                Text("Battery Health")
                    .font(.system(size: 12.5, weight: .semibold))
                
                Spacer()
                
                Text("Back").font(.system(size: 12)).opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider().opacity(0.5)
            
            // Capacity & Condition Overview
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 4.5)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(t.healthPercentage) / 100.0)
                            .stroke(
                                t.healthPercentage >= 80 ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(t.healthPercentage))%")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maximum Capacity")
                            .font(.system(size: 12, weight: .semibold))
                        
                        HStack(spacing: 4) {
                            Text("Condition:")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(t.condition)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(t.condition == "Normal" ? .green : .red)
                        }
                        
                        Text("Design: \(t.designCapacityMah.formatted()) mAh")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                // Cycle Count Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Cycle Count")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(t.cycleCount) / \(t.designCycleCount)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.06))
                                .frame(height: 5)
                            
                            let progress = min(1.0, Double(t.cycleCount) / Double(max(1, t.designCycleCount)))
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: max(5, geo.size.width * CGFloat(progress)), height: 5)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal, 16)
                
                Divider().opacity(0.5).padding(.top, 4)
                
                // Real-Time Electrical & Drain Diagnostics
                VStack(spacing: 8) {
                    HealthSpecRow(
                        label: "Current Drain / Flow",
                        value: String(format: "%.0f mA", t.amperageAmps * 1000.0),
                        valueColor: t.amperageAmps < 0 ? .orange : (t.amperageAmps > 0 ? .green : .primary)
                    )
                    
                    Divider().opacity(0.3)
                    
                    HealthSpecRow(
                        label: "Pack Voltage",
                        value: String(format: "%.2f V", t.voltageVolts)
                    )
                    
                    Divider().opacity(0.3)
                    
                    HealthSpecRow(
                        label: "Live Battery Power",
                        value: String(format: "%.2f W", t.batteryPowerWatts),
                        valueColor: t.batteryPowerWatts > 0 ? .green : (t.batteryPowerWatts < -0.5 ? .orange : .primary)
                    )
                    
                    Divider().opacity(0.3)
                    
                    HealthSpecRow(
                        label: "Remaining Capacity",
                        value: "\(t.currentCapacityMah.formatted()) mAh"
                    )
                    
                    Divider().opacity(0.3)
                    
                    HealthSpecRow(
                        label: "Full Charge Capacity",
                        value: "\(t.maxCapacityMah.formatted()) mAh"
                    )
                    
                    Divider().opacity(0.3)
                    
                    HealthSpecRow(
                        label: "Temperature",
                        value: String(format: "%.1f °C (%.1f °F)", t.temperatureCelsius, t.temperatureFahrenheit)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────────────────
    // 3. MINIMALIST SETTINGS PAGE
    // ─────────────────────────────────────────────────────────────────────────
    private func settingsView() -> some View {
        VStack(spacing: 0) {
            // Header Bar with Back Button
            HStack {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        activePage = .home
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
                
                Text("Back").font(.system(size: 12)).opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider().opacity(0.5)
            
            // Settings Rows
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
                
                Text("Wolt v1.1 • Apple Silicon")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
            .padding(16)
        }
    }
}

private struct HealthSpecRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }
}
