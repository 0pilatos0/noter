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
    @State private var globalHotkey: KeyCombination?
    @State private var hotkeyEnabled: Bool = true
    @State private var showingFilePicker: Bool = false
    @State private var showValidationError: Bool = false
    @State private var validationErrorMessage: String = ""
    @State private var showSaveSuccess: Bool = false
    @State private var showLaunchAtLoginError: Bool = false
    @State private var launchAtLoginErrorMessage: String = ""
    @State private var isDetectingPath: Bool = false

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
        _globalHotkey = State(initialValue: settings.globalHotkey)
        _hotkeyEnabled = State(initialValue: settings.hotkeyEnabled)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoterSpacing.xl) {
            // Save success banner
            if showSaveSuccess {
                NoterStatusBanner(.success("Settings saved"))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Obsidian Vault section
            VStack(alignment: .leading, spacing: NoterSpacing.md) {
                Text("Obsidian Vault")
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                VStack(spacing: NoterSpacing.sm) {
                    HStack(spacing: NoterSpacing.sm) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: NoterIconSize.md))
                            .foregroundStyle(.secondary)
                        if let directory = vaultDirectory {
                            Text(directory.path)
                                .font(NoterTypography.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("No directory configured")
                                .font(NoterTypography.body)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        // Vault validation indicator
                        if let directory = vaultDirectory {
                            ValidationBadge(
                                isValid: AppSettings.isValidObsidianVault(directory),
                                validText: "Valid",
                                invalidText: "No .obsidian"
                            )
                        }
                    }
                    .padding(NoterSpacing.sm + NoterSpacing.xxs)
                    .background(NoterColors.surfaceSubtle)
                    .cornerRadius(NoterRadius.md)

                    HStack {
                        Spacer()
                        NoterButton(vaultDirectory == nil ? "Select" : "Change", style: .secondary) {
                            showingFilePicker = true
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

            NoterDivider()

            // OpenCode section
            VStack(alignment: .leading, spacing: NoterSpacing.md) {
                Text("OpenCode")
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                // Path field
                VStack(alignment: .leading, spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                    Text("Path")
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: NoterSpacing.sm) {
                        TextField("Path to opencode executable", text: $opencodePath)
                            .textFieldStyle(.roundedBorder)
                            .font(NoterTypography.body)
                            .autocorrectionDisabled()

                        NoterButton("Detect", style: .secondary, isLoading: isDetectingPath) {
                            Task {
                                isDetectingPath = true
                                if let detected = await OpenCodePathDetector.detectPath() {
                                    opencodePath = detected
                                }
                                isDetectingPath = false
                            }
                        }

                        ValidationBadge(
                            isValid: OpenCodeService.checkOpencodeInstalled(at: opencodePath),
                            validText: "Found",
                            invalidText: "Not found"
                        )
                    }
                }
                .onChange(of: opencodePath) { _, _ in
                    saveSettings()
                }

                // Model selection
                VStack(alignment: .leading, spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                    Text("Model")
                        .font(NoterTypography.caption)
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
                            .font(NoterTypography.body)
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

            NoterDivider()

            // General section
            VStack(alignment: .leading, spacing: NoterSpacing.md) {
                Text("General")
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                Toggle(isOn: $launchAtLogin) {
                    HStack(spacing: NoterSpacing.sm) {
                        Image(systemName: "power")
                            .font(.system(size: NoterIconSize.md))
                            .foregroundStyle(.secondary)
                        Text("Launch at Login")
                            .font(NoterTypography.body)
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
                        launchAtLogin = !newValue
                        withAnimation {
                            showLaunchAtLoginError = true
                        }
                        Task {
                            try? await Task.sleep(nanoseconds: NoterStatusTiming.autoDismiss)
                            withAnimation {
                                showLaunchAtLoginError = false
                            }
                        }
                    }
                }

                if showLaunchAtLoginError {
                    NoterStatusBanner(.error(launchAtLoginErrorMessage))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Global Hotkey section
                VStack(alignment: .leading, spacing: NoterSpacing.sm) {
                    Toggle(isOn: $hotkeyEnabled) {
                        HStack(spacing: NoterSpacing.sm) {
                            Image(systemName: "keyboard")
                                .font(.system(size: NoterIconSize.md))
                                .foregroundStyle(.secondary)
                            Text("Global Hotkey")
                                .font(NoterTypography.body)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: hotkeyEnabled) { _, newValue in
                        updateHotkey()
                        saveSettings()
                    }

                    if hotkeyEnabled {
                        HStack {
                            HotkeyRecorderView(keyCombination: $globalHotkey)
                                .onChange(of: globalHotkey) { _, _ in
                                    updateHotkey()
                                    saveSettings()
                                }
                        }
                        .padding(.leading, 22)
                    }
                }
            }

            NoterDivider()

            // Templates section
            TemplatesSettingsView()

            NoterDivider()

            // Info card
            NoterInfoCard(
                icon: "info.circle",
                message: "Make sure your vault contains a claude.md file for opencode to understand your daily note format.",
                style: .info
            )

            Spacer()
        }
        .padding(NoterSpacing.lg + NoterSpacing.xxs)
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
        settings.globalHotkey = globalHotkey
        settings.hotkeyEnabled = hotkeyEnabled

        let result = StorageManager.saveSettings(settings)
        switch result {
        case .success:
            withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                showSaveSuccess = true
            }
            Task {
                try? await Task.sleep(nanoseconds: NoterStatusTiming.autoDismiss)
                withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                    showSaveSuccess = false
                }
            }
        case .failure(let error):
            validationErrorMessage = error.localizedDescription
            showValidationError = true
        }
    }

    private func updateHotkey() {
        if hotkeyEnabled, let combo = globalHotkey {
            HotkeyService.shared.register(combo) {
                NotificationCenter.default.post(name: .showPopoverFromHotkey, object: nil)
            }
        } else {
            HotkeyService.shared.unregister()
        }
    }
}

extension Notification.Name {
    static let showPopoverFromHotkey = Notification.Name("showPopoverFromHotkey")
}
