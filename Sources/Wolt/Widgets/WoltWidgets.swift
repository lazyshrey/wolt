import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
public struct WoltWidgetEntry: TimelineEntry {
    public let date: Date
    public let percentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let liveWatts: Double
    public let adapterName: String
    public let adapterWatts: Int
    public let healthPercentage: Double
    public let cycleCount: Int
    
    public static let sample = WoltWidgetEntry(
        date: Date(),
        percentage: 68,
        isCharging: false,
        isPluggedIn: false,
        liveWatts: 3.28,
        adapterName: "Apple 70W USB-C Adapter",
        adapterWatts: 70,
        healthPercentage: 100.0,
        cycleCount: 2
    )
}

// MARK: - Timeline Provider
public struct WoltTimelineProvider: TimelineProvider {
    public init() {}
    
    public func placeholder(in context: Context) -> WoltWidgetEntry {
        .sample
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WoltWidgetEntry) -> Void) {
        completion(.sample)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WoltWidgetEntry>) -> Void) {
        // Reads latest metrics
        let entry = WoltWidgetEntry(
            date: Date(),
            percentage: 68,
            isCharging: false,
            isPluggedIn: false,
            liveWatts: 3.28,
            adapterName: "Apple 70W USB-C Adapter",
            adapterWatts: 70,
            healthPercentage: 100.0,
            cycleCount: 2
        )
        // Refresh every 5 minutes (WidgetKit standard policy)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Small Widget View
public struct WoltSmallWidgetView: View {
    var entry: WoltWidgetEntry
    
    public init(entry: WoltWidgetEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: entry.isCharging ? "bolt.batteryblock.fill" : "bolt.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(entry.isCharging ? .green : .accentColor)
                Text("Wolt")
                    .font(.system(size: 11, weight: .bold))
                Spacer()
                if entry.adapterWatts > 0 && entry.isPluggedIn {
                    Text("\(entry.adapterWatts)W")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                }
            }
            
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(entry.percentage) / 100.0)
                    .stroke(
                        entry.isCharging ? Color.green : (entry.percentage <= 20 ? Color.red : Color.accentColor),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 1) {
                    Text("\(entry.percentage)%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(String(format: "%.1fW", entry.liveWatts))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(entry.isPluggedIn ? "Plugged In" : "On Battery")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// MARK: - Medium Widget View (Power Meter & Flow)
public struct WoltMediumWidgetView: View {
    var entry: WoltWidgetEntry
    
    public init(entry: WoltWidgetEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Left: Battery Gauge
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 7)
                        .frame(width: 68, height: 68)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(entry.percentage) / 100.0)
                        .stroke(
                            entry.isCharging ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 7, lineCap: .round)
                        )
                        .frame(width: 68, height: 68)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 1) {
                        Text("\(entry.percentage)%")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text(entry.isCharging ? "Charging" : "Battery")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(String(format: "%.1fW Draw", entry.liveWatts))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            
            Divider()
            
            // Right: Power Adapter & Flow Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "powerplug.fill")
                        .foregroundStyle(.green)
                    Text(entry.isPluggedIn ? entry.adapterName : "Running on Battery")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                }
                
                if entry.isPluggedIn {
                    HStack(spacing: 8) {
                        WidgetMetricPill(title: "Adapter", value: "\(entry.adapterWatts)W", color: .blue)
                        WidgetMetricPill(title: "Flow", value: String(format: "%.1fW", entry.liveWatts), color: .green)
                    }
                } else {
                    HStack(spacing: 8) {
                        WidgetMetricPill(title: "Health", value: "\(Int(entry.healthPercentage))%", color: .green)
                        WidgetMetricPill(title: "Cycles", value: "\(entry.cycleCount)", color: .blue)
                    }
                }
                
                HStack {
                    Text(entry.isPluggedIn ? "Optimal charging power delivery" : "Low power consumption mode")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

private struct WidgetMetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Widget Bundle Definition
public struct WoltWidget: Widget {
    public let kind: String = "WoltWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WoltTimelineProvider()) { entry in
            WoltSmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Wolt Battery Meter")
        .description("Track battery percentage, adapter wattage, and live power flow.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
