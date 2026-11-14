import SwiftUI
import AppKit

struct SettingsTabView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var powerService: PowerService
    
    var body: some View {
        VStack(spacing: 12) {
            // App Branding Header
            HStack(spacing: 12) {
                if let icon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1.5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Wolt")
                            .font(.system(size: 14, weight: .bold))
                        Text("v1.0.0")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())
                    }
                    Text("Native Power & Battery Intelligence")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Unified Preferences Card
            VStack(spacing: 10) {
                // Menu Bar Display Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Menu Bar Style")
                            .font(.system(size: 11.5, weight: .medium))
                        Text("Appearance in system menu bar")
                            .font(.system(size: 9.5))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("", selection: $settings.displayMode) {
                        ForEach(MenuBarDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Divider()
                
                // Launch at Login Toggle
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: $settings.launchAtLogin) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 11.5, weight: .medium))
                            Text("Start Wolt automatically on boot")
                                .font(.system(size: 9.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    
                    if settings.launchAtLogin {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9.5))
                                .foregroundStyle(.green)
                            Text(settings.launchAtLoginStatusMessage.isEmpty ? "Active in macOS Login Items" : settings.launchAtLoginStatusMessage)
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 2)
                        .transition(.opacity)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    powerService.triggerImmediateRefresh()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                        Text("Quit Wolt")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.8))
            }
        }
    }
}
