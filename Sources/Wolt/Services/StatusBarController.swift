import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()
    
    private let powerService = PowerService.shared
    private let settings = AppSettings.shared
    
    override init() {
        super.init()
        setupPopover()
        setupStatusItem()
        observeUpdates()
    }
    
    // MARK: - Popover Setup
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 270, height: 320)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        
        let contentView = PopoverContentView(powerService: powerService, settings: settings)
        let hostingController = NSHostingController(rootView: contentView)
        popover.contentViewController = hostingController
    }
    
    // MARK: - Status Item Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateStatusItem()
    }
    
    // MARK: - Reactive Observation
    private func observeUpdates() {
        powerService.$telemetry
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
        
        settings.$displayMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Status Item Update
    func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        let t = powerService.telemetry
        
        let symbolName = iconName(for: t)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Battery")
        image?.isTemplate = true
        
        switch settings.displayMode {
        case .iconOnly:
            button.image = image
            button.title = ""
            button.imagePosition = .imageOnly
        case .percentageOnly:
            button.image = nil
            button.title = "\(t.percentage)%"
            button.imagePosition = .noImage
        case .iconAndPercentage:
            button.image = image
            button.title = " \(t.percentage)%"
            button.imagePosition = .imageLeading
        case .iconAndWattage:
            button.image = image
            let wattStr: String
            if t.isPluggedIn && t.adapter.ratedWatts > 0 {
                wattStr = "\(t.adapter.ratedWatts)W"
            } else {
                wattStr = String(format: "%.1fW", t.liveWatts)
            }
            button.title = " \(wattStr)"
            button.imagePosition = .imageLeading
        }
        
        button.toolTip = tooltipText(for: t)
    }
    
    // MARK: - Click Action
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        togglePopover(sender)
    }
    
    func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            powerService.refresh()
            // show(relativeTo:of:preferredEdge:) attaches the native notch/beak directly to the button
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    // MARK: - NSPopoverDelegate
    func popoverWillShow(_ notification: Notification) {
        powerService.setWindowVisible(true)
    }
    
    func popoverDidClose(_ notification: Notification) {
        powerService.setWindowVisible(false)
    }
    
    // MARK: - Formatting Helpers
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
            return "\(adapterStr)\nTotal Draw: \(inStr)\n\(battLine)\n└─ Mac System Load: \(sysStr)\nBattery: \(t.percentage)%\(timeStr)"
        } else {
            let flowStr = String(format: "%.1fW", t.systemLoadWatts > 0 ? t.systemLoadWatts : t.liveWatts)
            return "Battery: \(t.percentage)% (Discharging)\nSystem Load: \(flowStr)\nRemaining: \(t.formattedTimeRemaining)"
        }
    }
}
