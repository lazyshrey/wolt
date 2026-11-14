import SwiftUI

struct PowerFlowTabView: View {
    @ObservedObject var powerService: PowerService
    
    var body: some View {
        let t = powerService.telemetry
        let isCharging = t.batteryPowerWatts > 0.05
        let isAssisting = t.batteryPowerWatts < -0.5 && (t.chargerInputWatts < t.systemLoadWatts - 0.5 || t.chargerInputWatts <= 0.5)
        
        VStack(spacing: 10) {
            // ─────────────────────────────────────────────────────────────────
            // 1. Primary Live Wattage Hero Card
            // Consistent layout whether plugged in or on battery (Juicy style)
            // ─────────────────────────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(t.isPluggedIn ? "Live Wall Draw" : "System Power Consumption")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if t.isPluggedIn && t.adapter.ratedWatts > 0 {
                        Text("of \(t.adapter.ratedWatts)W rated")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    } else if !t.isPluggedIn {
                        Text("Active Draw")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    let heroWatts = t.isPluggedIn ? t.chargerInputWatts : (t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts)
                    Text(String(format: "%.1f", heroWatts))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    
                    Text("W")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if t.isPluggedIn {
                        if isCharging {
                            Text("+\(String(format: "%.1fW", abs(t.batteryPowerWatts))) to battery")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.green)
                        } else if isAssisting {
                            Text("-\(String(format: "%.1fW", abs(t.batteryPowerWatts))) from battery")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.orange)
                        } else {
                            Text("Direct Wall Bypass")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("\(t.percentage)% Battery")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // ─────────────────────────────────────────────────────────────────
            // 2. Telemetry Details Card
            // Clean table rows with subtle hairline dividers, NO cards inside cards
            // ─────────────────────────────────────────────────────────────────
            VStack(spacing: 8) {
                if t.isPluggedIn {
                    // Row 1: Power Source
                    MetricRow(
                        icon: "powerplug.fill",
                        iconColor: .green,
                        label: "Power Source",
                        value: t.adapter.name
                    )
                    
                    Divider()
                    
                    // Row 2: USB-PD Negotiation
                    if t.adapterVoltageVolts > 0 && t.adapterCurrentAmps > 0 {
                        MetricRow(
                            icon: "bolt.fill",
                            iconColor: .blue,
                            label: "USB-PD Profile",
                            value: String(format: "%.1fV @ %.2fA", t.adapterVoltageVolts, t.adapterCurrentAmps)
                        )
                    } else {
                        MetricRow(
                            icon: "bolt.fill",
                            iconColor: .blue,
                            label: "Adapter Type",
                            value: t.adapter.description
                        )
                    }
                    
                    Divider()
                    
                    // Row 3: Battery Channel
                    let battLabel: String = isCharging ? "Battery Charging" : (isAssisting ? "Battery Assisting" : "Battery State")
                    let battValue: String = isCharging ? String(format: "+%.1f W", abs(t.batteryPowerWatts)) : (isAssisting ? String(format: "-%.1f W", abs(t.batteryPowerWatts)) : "Standby (0.0 W)")
                    let battColor: Color = isCharging ? .green : (isAssisting ? .orange : .secondary)
                    MetricRow(
                        icon: isCharging ? "arrow.down.batteryblock.fill" : "batteryblock.fill",
                        iconColor: battColor,
                        label: battLabel,
                        value: battValue,
                        valueColor: battColor
                    )
                    
                    Divider()
                    
                    // Row 4: Mac Hardware Consumption
                    MetricRow(
                        icon: "cpu",
                        iconColor: .secondary,
                        label: "Mac System Load",
                        value: String(format: "%.1f W", t.systemLoadWatts)
                    )
                    
                } else {
                    // ON BATTERY: Exactly the same 4-row structure
                    // Row 1: Power Source
                    MetricRow(
                        icon: "battery.100percent",
                        iconColor: .primary,
                        label: "Power Source",
                        value: "Battery (Discharging)"
                    )
                    
                    Divider()
                    
                    // Row 2: Live Discharge Current Flow
                    MetricRow(
                        icon: "bolt.fill",
                        iconColor: .orange,
                        label: "Discharge Flow",
                        value: String(format: "%.0f mA @ %.2f V", t.amperageAmps * 1000.0, t.voltageVolts)
                    )
                    
                    Divider()
                    
                    // Row 3: Remaining Charge Capacity
                    MetricRow(
                        icon: "gauge.with.dots.needle.bottom.50percent",
                        iconColor: .secondary,
                        label: "Remaining Energy",
                        value: "\(t.currentCapacityMah.formatted()) / \(t.maxCapacityMah.formatted()) mAh"
                    )
                    
                    Divider()
                    
                    // Row 4: Calculated Runtime
                    MetricRow(
                        icon: "clock",
                        iconColor: .secondary,
                        label: "Estimated Runtime",
                        value: t.formattedTimeRemaining
                    )
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // ─────────────────────────────────────────────────────────────────
            // 3. Subtle Status Footer
            // ─────────────────────────────────────────────────────────────────
            HStack(spacing: 6) {
                if t.isPluggedIn {
                    if t.adapter.isSlowCharging {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.orange)
                        Text("Slow Charger (Limited Power Delivery)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                    } else if isAssisting {
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.orange)
                        Text("Supplemental Battery Mode Active")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                    } else if t.percentage >= 95 || abs(t.batteryPowerWatts) <= 0.05 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.green)
                        Text("Hardware Power Bypass Active (Wall Powered)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10.5))
                            .foregroundStyle(.green)
                        Text("Fast Charging via USB-PD")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10.5))
                        .foregroundStyle(t.percentage <= 20 ? .red : .green)
                    Text(t.percentage <= 20 ? "Battery Low — Connect Power Adapter" : "System Running on Battery Power")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
    }
}

private struct MetricRow: View {
    let icon: String
    var iconColor: Color = .secondary
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(iconColor)
                .frame(width: 14)
            
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }
}
