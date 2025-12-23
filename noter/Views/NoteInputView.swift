import SwiftUI

struct NoteInputView: View {
    @State private var noteText: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    
    let vaultDirectory: URL
    let opencodePath: String
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Text("Quick Note")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                
                TextEditor(text: $noteText)
                    .font(.system(size: 14))
                    .frame(height: 150)
                    .scrollContentBackground(.hidden)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 1, y: 1)
                
                Button(action: addNote) {
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Add Note")
                        }
                    } else {
                        Text("Add Note")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(noteText.isEmpty || isLoading)
                .keyboardShortcut(KeyEquivalent.return, modifiers: .command)
            }
            .padding(18)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            DisclosureSection(title: "Output", defaultExpanded: false) {
                VStack(alignment: .leading, spacing: 8) {
                    if isLoading {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Processing...")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } else if showSuccess {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                            Text("Done")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } else if !outputText.isEmpty {
                        Text("Done")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(outputText)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                                .lineSpacing(2)
                                .id("output-bottom")
                        }
                        .onChange(of: outputText) { _, _ in
                            proxy.scrollTo("output-bottom", anchor: .bottom)
                        }
                    }
                    .frame(minHeight: 200)
                }
            }
            .padding(18)
        }
    }
    
    private func addNote() {
        guard !noteText.isEmpty else { return }
        
        isLoading = true
        outputText = ""
        showSuccess = false
        
        Task.detached {
            do {
                let output = try await OpenCodeService.addNote(noteText, in: vaultDirectory, opencodePath: opencodePath)
                
                await MainActor.run {
                    outputText = output
                    showSuccess = true
                }
                
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    noteText = ""
                }
            } catch {
                await MainActor.run {
                    outputText = error.localizedDescription
                    showSuccess = false
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct DisclosureSection<Content: View>: View {
    @State private var isExpanded: Bool = false
    let title: String
    let defaultExpanded: Bool
    let content: Content
    
    init(title: String, defaultExpanded: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.defaultExpanded = defaultExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 12)
            }
        }
    }
    
    private func toggle() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded.toggle()
        }
    }
}
