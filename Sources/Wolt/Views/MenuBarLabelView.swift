import SwiftUI

struct MenuBarLabelView: View {
    @ObservedObject var powerService: PowerService
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        let t = powerService.telemetry
        
        Group {
            switch settings.displayMode {
            case .iconOnly:
                Image(systemName: iconName(for: t))
            case .percentageOnly:
                Text("\(t.percentage)%")
            case .iconAndPercentage:
                HStack(spacing: 3) {
                    Image(systemName: iconName(for: t))
                    Text("\(t.percentage)%")
                }
            case .iconAndWattage:
                HStack(spacing: 3) {
                    Image(systemName: iconName(for: t))
                    if t.isPluggedIn && t.adapter.ratedWatts > 0 {
                        Text("\(t.adapter.ratedWatts)W")
                    } else {
                        Text(String(format: "%.1fW", t.liveWatts))
                    }
                }
            }
        }
        .help(tooltipText(for: t))
    }
    
    /// Native macOS tooltip displayed when hovering over the menu bar item
    private func tooltipText(for t: BatteryTelemetry) -> String {
        if t.isPluggedIn {
            let adapterStr = t.adapter.ratedWatts > 0 ? "\(t.adapter.name) (\(t.adapter.ratedWatts)W)" : t.adapter.name
            let inStr = String(format: "%.1fW", t.chargerInputWatts)
            let sysStr = String(format: "%.1fW", t.systemLoadWatts)
            let battLine: String
            if t.batteryPowerWatts > 0.05 {
                battLine = "├─ Battery Charge: +\(String(format: "%.1fW", t.batteryPowerWatts))"
            } else if t.batteryPowerWatts < -0.05 {
                battLine = "├─ Battery Assist: \(String(format: "%.1fW", t.batteryPowerWatts))"
            } else {
                battLine = "├─ Battery Bypass: 0.0W"
            }
            let timeStr = t.timeRemainingMinutes != nil ? " • \(t.formattedTimeRemaining) to full" : ""
            return "⚡ \(adapterStr)\nTotal Draw: \(inStr)\n\(battLine)\n└─ Mac System Load: \(sysStr)\nBattery: \(t.percentage)%\(timeStr)"
        } else {
            let flowStr = String(format: "%.1fW", t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts)
            return "🔋 Battery: \(t.percentage)% (Discharging)\nSystem Load: \(flowStr)\nRemaining: \(t.formattedTimeRemaining)"
        }
    }
    
    private func iconName(for t: BatteryTelemetry) -> String {
        if t.isCharging {
            return "bolt.batteryblock.fill"
        } else if t.percentage > 85 {
            return "battery.100percent"
        } else if t.percentage > 60 {
            return "battery.75percent"
        } else if t.percentage > 35 {
            return "battery.50percent"
        } else if t.percentage > 15 {
            return "battery.25percent"
        } else {
            return "battery.0percent"
        }
    }
}