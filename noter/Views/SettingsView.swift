import SwiftUI
import AppKit
import UniformTypeIdentifiers
import ServiceManagement

struct SettingsView: View {
    @State private var vaultDirectory: URL?
    @State private var opencodePath: String = ""
    @State private var model: String = ""
    @State private var customModel: String = ""
    @State private var launchAtLogin: Bool = false
    @State private var showingFilePicker: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var showLaunchAtLoginError: Bool = false
    @State private var launchAtLoginErrorMessage: String = ""
    
    private var isCustomModel: Bool {
        !AppSettings.defaultModels.contains(model)
    }
    
    init() {
        let settings = StorageManager.loadSettings()
        _vaultDirectory = State(initialValue: settings.vaultDirectory)
        _opencodePath = State(initialValue: settings.opencodePath)
        _model = State(initialValue: settings.model)
        _customModel = State(initialValue: AppSettings.defaultModels.contains(settings.model) ? "" : settings.model)
        _launchAtLogin = State(initialValue: AppSettings.isLaunchAtLoginEnabled)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Save success banner
            if showSaveSuccess {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Settings saved")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Obsidian Vault section
            VStack(alignment: .leading, spacing: 12) {
                Text("Obsidian Vault")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        if let directory = vaultDirectory {
                            Text(directory.path)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("No directory configured")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // Vault validation indicator
                        if let directory = vaultDirectory {
                            if AppSettings.isValidObsidianVault(directory) {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.green)
                                    Text("Valid")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.15))
                                .cornerRadius(4)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.orange)
                                    Text("No .obsidian")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.orange.opacity(0.15))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(6)
                    
                    HStack {
                        Spacer()
                        Button(vaultDirectory == nil ? "Select" : "Change") {
                            showingFilePicker = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
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
            
            // OpenCode section
            VStack(alignment: .leading, spacing: 12) {
                Text("OpenCode")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                // Path field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Path")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        TextField("Path to opencode executable", text: $opencodePath)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .autocorrectionDisabled()
                        
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
                }
                .onChange(of: opencodePath) { _, _ in
                    saveSettings()
                }
                
                // Model selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Model")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $model) {
                        ForEach(AppSettings.defaultModels, id: \.self) { modelName in
                            Text(modelName).tag(modelName)
                        }
                        Divider()
                        Text("Custom...").tag("custom")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .onChange(of: model) { _, newValue in
                        if newValue != "custom" {
                            saveSettings()
                        }
                    }
                    
                    if model == "custom" || isCustomModel {
                        TextField("Custom model identifier", text: $customModel)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 12))
                            .autocorrectionDisabled()
                            .onChange(of: customModel) { _, newValue in
                                if !newValue.isEmpty {
                                    model = newValue
                                    saveSettings()
                                }
                            }
                    }
                }
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            // General section
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
                    let result = AppSettings.syncLaunchAtLogin(newValue)
                    switch result {
                    case .success:
                        saveSettings()
                    case .failure(let error):
                        launchAtLoginErrorMessage = error.localizedDescription
                        launchAtLogin = !newValue // Revert the toggle
                        withAnimation {
                            showLaunchAtLoginError = true
                        }
                        // Auto-dismiss after 4 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 4_000_000_000)
                            withAnimation {
                                showLaunchAtLoginError = false
                            }
                        }
                    }
                }
                
                if showLaunchAtLoginError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(launchAtLoginErrorMessage)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
            Text(validationErrorMessage)
        }
    }
    
    private func handleFilePicker(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                vaultDirectory = url
                if !AppSettings.isValidObsidianVault(url) {
                    // Show warning but still allow - it might be intentional
                    validationErrorMessage = "This directory doesn't appear to be an Obsidian vault (no .obsidian folder found). You can still use it, but noter works best with Obsidian vaults."
                    showValidationError = true
                }
                saveSettings()
            }
        case .failure(let error):
            validationErrorMessage = "Failed to select directory: \(error.localizedDescription)"
            showValidationError = true
        }
    }
    
    private func saveSettings() {
        var settings = AppSettings(vaultDirectory: vaultDirectory, opencodePath: opencodePath)
        settings.model = model == "custom" ? customModel : model
        settings.launchAtLogin = launchAtLogin
        
        let result = StorageManager.saveSettings(settings)
        switch result {
        case .success:
            withAnimation(.easeInOut(duration: 0.2)) {
                showSaveSuccess = true
            }
            // Auto-dismiss success message
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSaveSuccess = false
                }
            }
        case .failure(let error):
            validationErrorMessage = error.localizedDescription
            showValidationError = true
        }
    }
}
