import Foundation
import SwiftUI
import Combine
import ServiceManagement

public enum MenuBarDisplayMode: String, CaseIterable, Identifiable {
    case iconAndPercentage = "Icon + Percentage"
    case percentageOnly = "Percentage Only"
    case iconOnly = "Icon Only"
    case iconAndWattage = "Icon + Wattage"
    
    public var id: String { rawValue }
}

@MainActor
public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults = UserDefaults.standard
    
    @Published public var displayMode: MenuBarDisplayMode {
        didSet {
            defaults.set(displayMode.rawValue, forKey: "displayMode_v2")
        }
    }
    
    @Published public var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            applyLaunchAtLogin(launchAtLogin)
        }
    }
    
    @Published public var launchAtLoginStatusMessage: String = ""
    
    private static var launchAgentPlistURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/com.wolt.mac.plist")
    }
    
    public init() {
        if let savedMode = defaults.string(forKey: "displayMode_v2"),
           let mode = MenuBarDisplayMode(rawValue: savedMode) {
            self.displayMode = mode
        } else {
            self.displayMode = .iconAndPercentage
        }
        
        let smStatus = SMAppService.mainApp.status
        let smEnabled = (smStatus == .enabled)
        let savedPreference = defaults.bool(forKey: "launchAtLogin")
        
        self.launchAtLogin = smEnabled || savedPreference
        
        // Purge any duplicate/legacy LaunchAgent plist so macOS launchd only has one trigger
        Self.purgeLegacyLaunchAgent()
        
        if self.launchAtLogin && !smEnabled {
            // Re-sync with SMAppService without spawning any secondary processes
            try? SMAppService.mainApp.register()
        }
    }
    
    public func applyLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            enableLaunchAtLogin()
        } else {
            disableLaunchAtLogin()
        }
    }
    
    private func enableLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status != .enabled {
                try service.register()
            }
            launchAtLoginStatusMessage = "Active (Registered with macOS Login Items)"
        } catch {
            NSLog("[Wolt] SMAppService.register error: \(error.localizedDescription)")
            // Fallback: create LaunchAgent plist strictly for NEXT reboot.
            // NEVER invoke launchctl bootstrap while running, to prevent duplicate process spawning!
            createLaunchAgentPlist()
            launchAtLoginStatusMessage = "Active (Configured for next login)"
        }
    }
    
    private func disableLaunchAtLogin() {
        let service = SMAppService.mainApp
        if service.status == .enabled {
            do {
                try service.unregister()
            } catch {
                NSLog("[Wolt] SMAppService.unregister error: \(error.localizedDescription)")
            }
        }
        
        Self.purgeLegacyLaunchAgent()
        launchAtLoginStatusMessage = ""
    }
    
    public static func purgeLegacyLaunchAgent() {
        let plistURL = launchAgentPlistURL
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: plistURL.path) {
            // Boot out from launchd domain if still loaded
            let uid = getuid()
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["bootout", "gui/\(uid)/com.wolt.mac"]
            try? task.run()
            task.waitUntilExit()
            
            try? fileManager.removeItem(at: plistURL)
            NSLog("[Wolt] Purged duplicate LaunchAgent plist at %@", plistURL.path)
        }
    }
    
    private func createLaunchAgentPlist() {
        let fileManager = FileManager.default
        let plistURL = Self.launchAgentPlistURL
        let directoryURL = plistURL.deletingLastPathComponent()
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        let executablePath: String
        if fileManager.fileExists(atPath: "/Applications/Wolt.app/Contents/MacOS/Wolt") {
            executablePath = "/Applications/Wolt.app/Contents/MacOS/Wolt"
        } else if let bundleExec = Bundle.main.executablePath, fileManager.fileExists(atPath: bundleExec) {
            executablePath = bundleExec
        } else {
            executablePath = "/Applications/Wolt.app/Contents/MacOS/Wolt"
        }
        
        let plistContent: [String: Any] = [
            "Label": "com.wolt.mac",
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "ProcessType": "Interactive",
            "KeepAlive": false
        ]
        
        if let data = try? PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0) {
            try? data.write(to: plistURL, options: .atomic)
        }
    }
}
