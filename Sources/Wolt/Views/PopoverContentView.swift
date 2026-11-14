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
            // Clean Header Bar (No redundant duplicate numbers)
            HStack(alignment: .center) {
                HStack(spacing: 9) {
                    Image(systemName: t.isCharging ? "bolt.batteryblock.fill" : (t.percentage <= 20 ? "battery.25percent" : "battery.75percent"))
                        .font(.system(size: 20))
                        .foregroundStyle(t.isCharging ? .green : (t.percentage <= 20 ? .red : .primary))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("\(t.percentage)%")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            
                            if t.isPluggedIn {
                                Text(t.isCharging ? "Charging" : "Plugged In")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundStyle(t.isCharging ? .green : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(t.isCharging ? Color.green.opacity(0.12) : Color.primary.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(t.isPluggedIn ? t.adapter.name : (t.timeRemainingMinutes != nil ? "\(t.formattedTimeRemaining) remaining" : "Running on Battery"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Status Pill (Clean Apple style context, avoids repeating body watts)
                if t.isPluggedIn {
                    if t.adapter.ratedWatts > 0 {
                        Text("\(t.adapter.ratedWatts)W Adapter")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                    }
                } else if let time = t.timeRemainingMinutes, time > 0 {
                    Text("\(t.formattedTimeRemaining) left")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Capsule())
                }
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