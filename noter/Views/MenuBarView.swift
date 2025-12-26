import SwiftUI

struct MenuBarView: View {
    @State private var selectedTab: Tab = .note
    @State private var prefillNoteText: String = ""

    private enum Tab: String, CaseIterable {
        case note = "Note"
        case history = "History"
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

            Group {
                if !StorageManager.hasConfiguredDirectory() && selectedTab == .note {
                    ScrollView {
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
                    }
                } else {
                    let settings = StorageManager.loadSettings()
                    switch selectedTab {
                    case .note:
                        if let directory = settings.vaultDirectory {
                            ScrollView {
                                NoteInputView(
                                    vaultDirectory: directory,
                                    opencodePath: settings.opencodePath,
                                    model: settings.model,
                                    prefillText: prefillNoteText
                                )
                            }
                            .onChange(of: selectedTab) { _, _ in
                                // Clear prefill when switching tabs
                                if !prefillNoteText.isEmpty {
                                    prefillNoteText = ""
                                }
                            }
                        }
                    case .history:
                        HistoryView(onUseNote: { text in
                            prefillNoteText = text
                            selectedTab = .note
                        })
                    case .settings:
                        ScrollView {
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
