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
        let launchAgentExists = FileManager.default.fileExists(atPath: Self.launchAgentPlistURL.path)
        let savedPreference = defaults.bool(forKey: "launchAtLogin")
        
        let isEnabled = smEnabled || launchAgentExists || savedPreference
        self.launchAtLogin = isEnabled
        
        if isEnabled {
            // Keep system registration synced and up to date with active binary path
            self.applyLaunchAtLogin(true)
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
        var smSucceeded = false
        let service = SMAppService.mainApp
        if service.status != .enabled {
            do {
                try service.register()
                smSucceeded = true
            } catch {
                NSLog("[Wolt] SMAppService.register error: \(error.localizedDescription)")
            }
        } else {
            smSucceeded = true
        }
        
        // High-reliability LaunchAgent backup (ensures startup across all macOS configurations)
        createLaunchAgentPlist()
        bootstrapLaunchAgent(plistURL: Self.launchAgentPlistURL)
        
        if smSucceeded {
            launchAtLoginStatusMessage = "Active (Registered with macOS Login Items)"
        } else {
            launchAtLoginStatusMessage = "Active (Configured via LaunchAgent)"
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
        
        bootoutLaunchAgent()
        removeLaunchAgentPlist()
        launchAtLoginStatusMessage = ""
    }
    
    private func bootstrapLaunchAgent(plistURL: URL) {
        let uid = getuid()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["bootstrap", "gui/\(uid)", plistURL.path]
        try? task.run()
    }
    
    private func bootoutLaunchAgent() {
        let uid = getuid()
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["bootout", "gui/\(uid)/com.wolt.mac"]
        try? task.run()
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
    
    private func removeLaunchAgentPlist() {
        let fileManager = FileManager.default
        let plistURL = Self.launchAgentPlistURL
        if fileManager.fileExists(atPath: plistURL.path) {
            try? fileManager.removeItem(at: plistURL)
        }
    }
}
