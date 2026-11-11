import SwiftUI

struct HealthTabView: View {
    @ObservedObject var powerService: PowerService
    
    var body: some View {
        let t = powerService.telemetry
        
        VStack(spacing: 12) {
            // 1. Health & Maximum Capacity Card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 6)
                        .frame(width: 54, height: 54)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(t.healthPercentage) / 100.0)
                        .stroke(
                            t.healthPercentage >= 80 ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 54, height: 54)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(t.healthPercentage))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Maximum Capacity")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Condition: \(t.condition)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(t.condition == "Normal" ? .green : .red)
                    Text("Factory Design: \(t.designCapacityMah.formatted()) mAh")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // 2. Battery Temperature Card
            HStack(spacing: 12) {
                let temp = t.temperatureCelsius
                let isCool = temp < 35.0
                let isWarm = temp >= 35.0 && temp < 45.0
                let color: Color = isCool ? .green : (isWarm ? .orange : .red)
                let statusText = isCool ? "Cool (Optimal)" : (isWarm ? "Warm" : "Elevated")
                
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Battery Temperature")
                        .font(.system(size: 12, weight: .medium))
                    Text("Thermal State: \(statusText)")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.1f°C", t.temperatureCelsius))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(String(format: "%.1f°F", t.temperatureFahrenheit))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // 3. Cycle Count Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Cycle Count")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(t.cycleCount) / \(t.designCycleCount) cycles")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                            .frame(height: 6)
                        
                        let progress = min(1.0, Double(t.cycleCount) / Double(max(1, t.designCycleCount)))
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: max(6, geo.size.width * CGFloat(progress)), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("Standard Apple Silicon batteries are rated for 1,000 full cycles.")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // 4. Technical Electrical Specs Grid
            VStack(spacing: 8) {
                SpecRow(label: "Current Voltage", value: String(format: "%.2f V", t.voltageVolts))
                Divider()
                SpecRow(label: "Current Flow", value: String(format: "%.0f mA", t.amperageAmps * 1000.0))
                Divider()
                SpecRow(label: "Charge Capacity", value: "\(t.currentCapacityMah.formatted()) / \(t.maxCapacityMah.formatted()) mAh")
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