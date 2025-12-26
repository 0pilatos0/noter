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
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, NoterSpacing.lg)
            .padding(.vertical, NoterSpacing.md)

            NoterDivider()

            // Content area
            Group {
                if !StorageManager.hasConfiguredDirectory() && selectedTab == .note {
                    // Empty state for unconfigured vault
                    NoterEmptyState(
                        icon: "folder.badge.questionmark",
                        title: "No Directory Configured",
                        subtitle: "Please configure your Obsidian vault in Settings",
                        action: .init("Go to Settings", icon: "gear") {
                            selectedTab = .settings
                        }
                    )
                } else {
                    let settings = StorageManager.loadSettings()
                    switch selectedTab {
                    case .note:
                        if let directory = settings.vaultDirectory {
                            // Note: Removed ScrollView wrapper - NoteInputView handles its own scrolling
                            NoteInputView(
                                vaultDirectory: directory,
                                opencodePath: settings.opencodePath,
                                model: settings.model,
                                prefillText: prefillNoteText
                            )
                            .onChange(of: selectedTab) { _, _ in
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
