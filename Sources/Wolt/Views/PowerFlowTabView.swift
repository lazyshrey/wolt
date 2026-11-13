import SwiftUI

struct PowerFlowTabView: View {
    @ObservedObject var powerService: PowerService
    
    var body: some View {
        let t = powerService.telemetry
        
        VStack(spacing: 12) {
            if t.isPluggedIn {
                // 1. Adapter Header & Live Wall Draw
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                            .frame(width: 28, height: 28)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(t.adapter.name)
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                            
                            if t.adapterVoltageVolts > 0 && t.adapterCurrentAmps > 0 {
                                Text(String(format: "USB-PD: %.1fV @ %.2fA", t.adapterVoltageVolts, t.adapterCurrentAmps))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(t.adapter.description)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(String(format: "%.1f W", t.chargerInputWatts))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                                .contentTransition(.numericText())
                            
                            if t.adapter.ratedWatts > 0 {
                                Text("live of \(t.adapter.ratedWatts)W rated")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // 2. Power Flow Split (Juicy Power Flow Distribution)
                let isCharging = t.batteryPowerWatts > 0.05
                let isAssisting = t.batteryPowerWatts < -0.5 && (t.chargerInputWatts < t.systemLoadWatts - 0.5 || t.chargerInputWatts <= 0.5)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isAssisting ? Color.orange : Color.green)
                            .frame(width: 6, height: 6)
                        Text("Live Power Distribution")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        if isAssisting {
                            Text("Total Load: \(String(format: "%.1fW", t.systemLoadWatts))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        } else {
                            let totalWall = max(t.chargerInputWatts, t.systemLoadWatts + max(0.0, t.batteryPowerWatts))
                            Text("Total Draw: \(String(format: "%.1fW", totalWall))")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                    }
                    
                    // Dual Proportion Bar with smooth continuous animation
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            if isCharging {
                                let total = max(1.0, max(t.chargerInputWatts, t.batteryPowerWatts + t.systemLoadWatts))
                                let battFraction = max(0.03, min(0.97, t.batteryPowerWatts / total))
                                let sysFraction = max(0.03, 1.0 - battFraction)
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.green)
                                    .frame(width: max(4, geo.size.width * CGFloat(battFraction)))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.blue)
                                    .frame(width: max(4, geo.size.width * CGFloat(sysFraction)))
                            } else if isAssisting {
                                let total = max(0.5, t.systemLoadWatts)
                                let wallFraction = max(0.0, min(1.0, t.chargerInputWatts / total))
                                let battFraction = max(0.0, min(1.0, abs(t.batteryPowerWatts) / total))
                                
                                if t.chargerInputWatts > 0.1 {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.blue)
                                        .frame(width: max(4, geo.size.width * CGFloat(wallFraction)))
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.orange)
                                        .frame(width: max(4, geo.size.width * CGFloat(battFraction)))
                                } else {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.orange)
                                        .frame(width: geo.size.width)
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width)
                            }
                        }
                    }
                    .frame(height: 6)
                    .animation(.smooth(duration: 0.35), value: t.chargerInputWatts)
                    .animation(.smooth(duration: 0.35), value: t.batteryPowerWatts)
                    
                    // Detailed Split Rows
                    VStack(spacing: 8) {
                        // Battery Channel
                        HStack(spacing: 10) {
                            Circle()
                                .fill(isCharging ? Color.green : (isAssisting ? Color.orange : Color.secondary.opacity(0.6)))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                if isCharging {
                                    Text("Battery Charging")
                                        .font(.system(size: 12, weight: .medium))
                                    if let time = t.timeRemainingMinutes, time > 0 {
                                        Text("\(t.formattedTimeRemaining) to full charge")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Trickle charge / maintenance")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                } else if isAssisting {
                                    Text("Battery Discharging (Assisting)")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Supplying supplemental power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("Battery Standby (Power Bypass)")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Mac running directly from wall power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                if isCharging {
                                    Text(String(format: "+%.1f W", abs(t.batteryPowerWatts)))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.green)
                                        .contentTransition(.numericText())
                                    
                                    let total = max(1.0, max(t.chargerInputWatts, t.batteryPowerWatts + t.systemLoadWatts))
                                    let pct = min(100, max(1, Int((abs(t.batteryPowerWatts) / total) * 100)))
                                    Text("\(pct)% of power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                } else if isAssisting {
                                    Text(String(format: "-%.1f W", abs(t.batteryPowerWatts)))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.orange)
                                        .contentTransition(.numericText())
                                    
                                    let total = max(0.5, t.systemLoadWatts)
                                    let pct = min(100, max(1, Int((abs(t.batteryPowerWatts) / total) * 100)))
                                    Text("\(pct)% of load")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                } else {
                                    Text("0.0 W")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("0% of power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(
                            (isCharging ? Color.green : (isAssisting ? Color.orange : Color.secondary)).opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Mac System Load Channel
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Mac System Load")
                                    .font(.system(size: 12, weight: .medium))
                                Text("CPU, display, RAM, logic board")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(String(format: "%.1f W", t.systemLoadWatts))
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue)
                                    .contentTransition(.numericText())
                                
                                if isCharging {
                                    let total = max(1.0, max(t.chargerInputWatts, t.batteryPowerWatts + t.systemLoadWatts))
                                    let battPct = min(100, max(1, Int((abs(t.batteryPowerWatts) / total) * 100)))
                                    let sysPct = max(0, 100 - battPct)
                                    Text("\(sysPct)% of power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                } else if isAssisting {
                                    if t.chargerInputWatts > 0.5 {
                                        let wallPct = min(100, max(0, Int((t.chargerInputWatts / max(0.5, t.systemLoadWatts)) * 100)))
                                        let battPct = max(0, 100 - wallPct)
                                        Text("\(wallPct)% wall • \(battPct)% batt")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .contentTransition(.numericText())
                                    } else {
                                        Text("100% from battery (charger idle)")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .contentTransition(.numericText())
                                    }
                                } else {
                                    Text("100% of wall power")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(12)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // 3. Charger Delivery & Protocol Status
                HStack(spacing: 6) {
                    if t.adapter.isSlowCharging {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text("Slow Charger (Limited Power Delivery)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.orange)
                    } else if t.adapter.ratedWatts == 0 {
                        Image(systemName: "bolt.badge.clock.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.blue)
                        Text("Negotiating USB-PD Power Profile...")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else if isAssisting {
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.orange)
                        Text("Supplemental Battery Mode (High System Demand)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else if t.chargerInputWatts < 0.5 {
                        Image(systemName: "powerplug")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("\(t.adapter.name) Connected (Idle / Standby)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else if t.percentage >= 95 || abs(t.batteryPowerWatts) <= 0.05 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                        Text(t.percentage >= 98 ? "Battery Full (Wall Power Bypass Active)" : "Hardware Power Bypass Active (Wall Powered)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                        let efficiency = t.adapter.ratedWatts > 0 ? min(100, max(1, Int((t.chargerInputWatts / Double(t.adapter.ratedWatts)) * 100))) : 0
                        Text("Optimal USB-PD Delivery (\(efficiency)% of rated)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
                
            } else {
                // Running on Battery View
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                            .frame(width: 88, height: 88)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(t.percentage) / 100.0)
                            .stroke(
                                t.percentage <= 20 ? Color.red : Color.green,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 88, height: 88)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(t.percentage)%")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Text("Battery")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 4) {
                        Text("Running on Battery Power")
                            .font(.system(size: 13, weight: .semibold))
                        
                        Text("\(t.formattedTimeRemaining) remaining")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Live Discharge Rate
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "cpu")
                                .foregroundStyle(.secondary)
                            Text("Mac System Consumption:")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.2f W", t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle((t.systemLoadWatts > 20) ? .orange : .green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(12)
            }
        }
    }
}