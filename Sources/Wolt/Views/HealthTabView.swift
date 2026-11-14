import SwiftUI

struct HealthTabView: View {
    @ObservedObject var powerService: PowerService
    
    var body: some View {
        let t = powerService.telemetry
        
        VStack(spacing: 10) {
            // 1. Unified Battery Health & Capacity Card
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                            .frame(width: 48, height: 48)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(t.healthPercentage) / 100.0)
                            .stroke(
                                t.healthPercentage >= 80 ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(t.healthPercentage))%")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maximum Capacity")
                            .font(.system(size: 12.5, weight: .semibold))
                        
                        HStack(spacing: 4) {
                            Text("Condition:")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text(t.condition)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(t.condition == "Normal" ? .green : .red)
                        }
                        
                        Text("Factory Design: \(t.designCapacityMah.formatted()) mAh")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                }
                
                Divider()
                
                // Cycle Count
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Cycle Count")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(t.cycleCount) / \(t.designCycleCount) cycles")
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
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
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // 2. Diagnostics & Electrical Specs Card
            VStack(spacing: 8) {
                // Temperature Row
                let temp = t.temperatureCelsius
                let isCool = temp < 35.0
                let isWarm = temp >= 35.0 && temp < 45.0
                let tempColor: Color = isCool ? .green : (isWarm ? .orange : .red)
                let tempState = isCool ? "Cool" : (isWarm ? "Warm" : "Elevated")
                
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 11))
                            .foregroundStyle(tempColor)
                        Text("Temperature")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f°C", t.temperatureCelsius))
                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        Text("(\(tempState))")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Divider()
                
                SpecRow(label: "Current Voltage", value: String(format: "%.2f V", t.voltageVolts))
                
                Divider()
                
                SpecRow(label: "Current Flow", value: String(format: "%.0f mA", t.amperageAmps * 1000.0))
                
                Divider()
                
                SpecRow(label: "Usable Capacity", value: "\(t.currentCapacityMah.formatted()) / \(t.maxCapacityMah.formatted()) mAh")
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct SpecRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
    }
}
