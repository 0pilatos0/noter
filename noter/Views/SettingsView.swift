import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ServiceManagement

struct SettingsView: View {
    @State private var vaultDirectory: URL?
    @State private var opencodePath: String = ""
    @State private var launchAtLogin: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showValidationError: Bool = false
    
    init() {
        let settings = StorageManager.loadSettings()
        _vaultDirectory = State(initialValue: settings.vaultDirectory)
        _opencodePath = State(initialValue: settings.opencodePath)
        _launchAtLogin = State(initialValue: AppSettings.isLaunchAtLoginEnabled)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Obsidian Vault")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    Text("Vault Path")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        if let directory = vaultDirectory {
                            Text(directory.path)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        } else {
                            Text("No directory configured")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        if vaultDirectory == nil {
                            Button("Select") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
                    
                    if vaultDirectory != nil {
                        HStack {
                            Spacer()
                            Button("Change") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $showingFilePicker,
                    allowedContentTypes: [.folder],
                    allowsMultipleSelection: false
                ) { result in
                    handleFilePicker(result)
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Opencode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    Text("Path")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("", text: .constant(opencodePath))
                            .disabled(true)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .autocorrectionDisabled()
                        
                        Spacer()
                        
                        if OpenCodeService.checkOpencodeInstalled(at: opencodePath) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.green)
                                Text("Found")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.15))
                            .cornerRadius(4)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.red)
                                Text("Not found")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red.opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                    
                    TextField("", text: $opencodePath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .autocorrectionDisabled()
                }
                .onChange(of: opencodePath) { _, _ in
                    saveSettings()
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("General")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                Toggle(isOn: $launchAtLogin) {
                    HStack(spacing: 8) {
                        Image(systemName: "power")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        Text("Launch at Login")
                            .font(.system(size: 12))
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: launchAtLogin) { _, newValue in
                    AppSettings.syncLaunchAtLogin(newValue)
                    saveSettings()
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Make sure your vault contains a claude.md file for opencode to understand your daily note format.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(18)
        .alert("Invalid Directory", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please select a valid directory")
        }
    }
    
    private func handleFilePicker(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                vaultDirectory = url
                saveSettings()
            }
        case .failure:
            showValidationError = true
        }
    }
    
    private func saveSettings() {
        var settings = AppSettings(vaultDirectory: vaultDirectory, opencodePath: opencodePath)
        settings.launchAtLogin = launchAtLogin
        StorageManager.saveSettings(settings)
    }
}
