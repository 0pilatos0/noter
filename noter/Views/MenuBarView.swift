import SwiftUI

struct MenuBarView: View {
    @State private var selectedTab: Tab = .note
    
    private enum Tab: String, CaseIterable {
        case note = "Note"
        case settings = "Settings"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            ScrollView {
                Group {
                    if !StorageManager.hasConfiguredDirectory() && selectedTab == .note {
                        VStack(spacing: 20) {
                            Spacer()
                            Image(systemName: "folder.badge.questionmark")
                                .font(.system(size: 56))
                                .foregroundStyle(.secondary.opacity(0.6))
                            Text("No Directory Configured")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("Please configure your Obsidian vault in Settings")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            Button("Go to Settings") {
                                selectedTab = .settings
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                            Spacer()
                        }
                        .padding(18)
                    } else {
                        let settings = StorageManager.loadSettings()
                        if selectedTab == .note, let directory = settings.vaultDirectory {
                            NoteInputView(
                                vaultDirectory: directory,
                                opencodePath: settings.opencodePath,
                                model: settings.model
                            )
                        } else if selectedTab == .settings {
                            SettingsView()
                        }
                    }
                }
            }
            .frame(height: 350)
        }
        .frame(width: 380, height: 420)
        .background(.windowBackground)
    }
}
