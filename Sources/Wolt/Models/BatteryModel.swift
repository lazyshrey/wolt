import Foundation

/// Represents the current power source state
public enum PowerSourceState: String, Sendable {
    case battery = "Battery Power"
    case acPower = "AC Power"
    case unknown = "Unknown"
}

/// Details about the connected external power adapter
public struct PowerAdapterInfo: Equatable, Sendable {
    public let isConnected: Bool
    public let name: String
    public let manufacturer: String
    public let ratedWatts: Int
    public let isFastCharging: Bool
    public let isSlowCharging: Bool
    public let description: String
    
    public static let disconnected = PowerAdapterInfo(
        isConnected: false,
        name: "Disconnected",
        manufacturer: "",
        ratedWatts: 0,
        isFastCharging: false,
        isSlowCharging: false,
        description: "Running on battery"
    )
}

/// Real-time battery & power flow telemetry read from Apple hardware
public struct BatteryTelemetry: Equatable, Sendable {
    public let percentage: Int
    public let isCharging: Bool
    public let isPluggedIn: Bool
    public let timeRemainingMinutes: Int?
    
    // Live Power Flow Telemetry (Milliwatts / Watts from Apple PMU)
    public let chargerInputWatts: Double     // Total watts pulled from the charger (e.g. 28.3W)
    public let batteryPowerWatts: Double     // Watts flowing into the battery (e.g. +23.4W)
    public let systemLoadWatts: Double       // Watts consumed by the Mac hardware/CPU/display (e.g. 4.9W)
    public let adapterVoltageVolts: Double   // Negotiated USB-PD voltage (e.g. 19.86V)
    public let adapterCurrentAmps: Double    // Negotiated USB-PD current (e.g. 1.42A)
    
    // Health & Cycles
    public let currentCapacityMah: Int
    public let maxCapacityMah: Int
    public let designCapacityMah: Int
    public let healthPercentage: Double
    public let cycleCount: Int
    public let designCycleCount: Int
    public let condition: String
    public let temperatureCelsius: Double    // Battery pack temperature (e.g. 33.2°C)
    
    // Battery Pack Electrical Metrics
    public let voltageVolts: Double          // Battery pack voltage (e.g. 12.45V)
    public let amperageAmps: Double          // Battery pack current (e.g. 1.87A)
    public let liveWatts: Double             // Current net battery wattage
    
    // Power Adapter
    public let adapter: PowerAdapterInfo
    
    public var temperatureFahrenheit: Double {
        return (temperatureCelsius * 1.8) + 32.0
    }
    
    public static let placeholder = BatteryTelemetry(
        percentage: 100,
        isCharging: false,
        isPluggedIn: false,
        timeRemainingMinutes: nil,
        chargerInputWatts: 0.0,
        batteryPowerWatts: 0.0,
        systemLoadWatts: 0.0,
        adapterVoltageVolts: 0.0,
        adapterCurrentAmps: 0.0,
        currentCapacityMah: 4629,
        maxCapacityMah: 4629,
        designCapacityMah: 4629,
        healthPercentage: 100.0,
        cycleCount: 0,
        designCycleCount: 1000,
        condition: "Normal",
        temperatureCelsius: 30.0,
        voltageVolts: 12.0,
        amperageAmps: 0.0,
        liveWatts: 0.0,
        adapter: .disconnected
    )
    
    public var formattedTimeRemaining: String {
        guard let minutes = timeRemainingMinutes, minutes > 0 else {
            return isCharging ? "Calculating time to full..." : "Calculating remaining time..."
        }
        let hrs = minutes / 60
        let mins = minutes % 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }
}