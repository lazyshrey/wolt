import SwiftUI
import AppKit

@main
struct WoltApp: App {
    @StateObject private var powerService = PowerService.shared
    @StateObject private var settings = AppSettings.shared
    
    private static var lockFileDescriptor: Int32 = -1
    
    init() {
        Self.ensureSingleInstance()
    }
    
    private static func ensureSingleInstance() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.wolt.mac"
        
        // 1. Check for another running instance of Wolt
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        for app in running {
            if app.processIdentifier != currentPID {
                NSLog("[Wolt] Another instance is already running (PID: %d). Terminating duplicate PID: %d.", app.processIdentifier, currentPID)
                exit(0)
            }
        }
        
        // 2. Acquire exclusive non-blocking lock to prevent parallel launch races
        let lockPath = "/tmp/com.wolt.mac.lock"
        let fd = open(lockPath, O_CREAT | O_WRONLY, 0o644)
        if fd >= 0 {
            if flock(fd, LOCK_EX | LOCK_NB) != 0 {
                NSLog("[Wolt] Failed to acquire lock on %s. Another instance is active. Terminating PID: %d.", lockPath, currentPID)
                close(fd)
                exit(0)
            }
            lockFileDescriptor = fd
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            PopoverContentView(powerService: powerService, settings: settings)
        } label: {
            MenuBarLabelView(powerService: powerService, settings: settings)
        }
        .menuBarExtraStyle(.window)
    }
}
