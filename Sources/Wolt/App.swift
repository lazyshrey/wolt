import SwiftUI
import AppKit

@main
struct WoltApp: App {
    @StateObject private var powerService = PowerService.shared
    @StateObject private var settings = AppSettings.shared
    
    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(powerService: powerService, settings: settings)
        } label: {
            MenuBarLabelView(powerService: powerService, settings: settings)
        }
        .menuBarExtraStyle(.window)
    }
}
