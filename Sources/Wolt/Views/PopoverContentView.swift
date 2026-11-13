import SwiftUI

public enum WoltTab: String, CaseIterable, Identifiable {
    case power = "Power"
    case health = "Health"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .power: return "bolt.fill"
        case .health: return "heart.text.square.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
public struct PopoverContentView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var settings: AppSettings
    
    @State private var selectedTab: WoltTab = .power
    
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
        
        VStack(spacing: 14) {
            // Header Bar
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: t.isCharging ? "bolt.batteryblock.fill" : "battery.75percent")
                        .font(.system(size: 20))
                        .foregroundStyle(t.isCharging ? .green : .accentColor)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text("\(t.percentage)%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            
                            if t.isPluggedIn {
                                Text(t.isCharging ? "Charging" : "Plugged In")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(t.isCharging ? .green : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(t.isCharging ? Color.green.opacity(0.15) : Color.primary.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(t.isPluggedIn ? "\(t.adapter.name) Connected" : "\(t.formattedTimeRemaining) remaining")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Mini wattage badge
                let isAssisting = t.isPluggedIn && t.batteryPowerWatts < -0.5 && (t.chargerInputWatts < t.systemLoadWatts - 0.5 || t.chargerInputWatts <= 0.5)
                let displayWatts: Double = {
                    if t.isPluggedIn {
                        if t.chargerInputWatts > 0.05 {
                            return t.chargerInputWatts
                        } else if isAssisting {
                            return t.systemLoadWatts
                        } else {
                            return 0.0
                        }
                    } else {
                        return t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts
                    }
                }()
                let suffix: String = {
                    if t.isPluggedIn {
                        if t.chargerInputWatts > 0.05 {
                            return " In"
                        } else if isAssisting {
                            return " Load"
                        } else {
                            return " In"
                        }
                    }
                    return ""
                }()
                
                Text(String(format: "%.1fW%@", displayWatts, suffix))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(t.isCharging ? .green : (isAssisting ? .orange : .secondary))
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.35), value: displayWatts)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // Native Apple Segmented Tab Switcher
            Picker("", selection: $selectedTab) {
                ForEach(WoltTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            
            // Tab Contents
            Group {
                switch selectedTab {
                case .power:
                    PowerFlowTabView(powerService: powerService)
                case .health:
                    HealthTabView(powerService: powerService)
                case .settings:
                    SettingsTabView(settings: settings, powerService: powerService)
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
        }
        .padding(16)
        .frame(width: 330)
        .onAppear {
            powerService.setWindowVisible(true)
        }
        .onDisappear {
            powerService.setWindowVisible(false)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2.0s calm cadence while window is open
                powerService.refresh()
            }
        }
    }
}