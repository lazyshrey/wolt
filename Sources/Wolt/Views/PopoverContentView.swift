import SwiftUI

public enum WoltTab: String, CaseIterable, Identifiable {
    case power = "Power"
    case health = "Health"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .power: return "bolt.fill"
        case .health: return "heart.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@MainActor
public struct PopoverContentView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var settings: AppSettings
    
    @State private var selectedTab: WoltTab = .power
    @State private var hoveredTab: WoltTab? = nil
    @Namespace private var tabNamespace
    
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
            
            // Custom Polished Animated Segmented Tab Switcher
            HStack(spacing: 3) {
                ForEach(WoltTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    let isHovered = hoveredTab == tab && !isSelected
                    
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                        }
                        .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1.5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                                    )
                                    .matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)
                            } else if isHovered {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering {
                            hoveredTab = tab
                        } else if hoveredTab == tab {
                            hoveredTab = nil
                        }
                    }
                }
            }
            .padding(3)
            .background(Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // Tab Contents with Smooth Animated Transition
            ZStack(alignment: .top) {
                switch selectedTab {
                case .power:
                    PowerFlowTabView(powerService: powerService)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)).combined(with: .offset(y: 4)),
                            removal: .opacity
                        ))
                case .health:
                    HealthTabView(powerService: powerService)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)).combined(with: .offset(y: 4)),
                            removal: .opacity
                        ))
                case .settings:
                    SettingsTabView(settings: settings, powerService: powerService)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)).combined(with: .offset(y: 4)),
                            removal: .opacity
                        ))
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .animation(.spring(response: 0.30, dampingFraction: 0.85), value: selectedTab)
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