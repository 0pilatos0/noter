import SwiftUI

struct NoteInputView: View {
    @State private var noteText: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showOutput: Bool = false
    @State private var hasOutput: Bool = false
    
    @FocusState private var isTextEditorFocused: Bool
    
    let vaultDirectory: URL
    let opencodePath: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Main input card
            VStack(spacing: 0) {
                // Text editor with placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $noteText)
                        .font(.system(size: 13))
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .focused($isTextEditorFocused)
                        .disabled(isLoading)
                    
                    // Placeholder - positioned to match TextEditor's internal padding
                    if noteText.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil.line")
                                .font(.system(size: 12))
                            Text("Capture a thought...")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 0)
                        .padding(.leading, 6)
                        .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 100, maxHeight: 140)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Toolbar
                HStack(spacing: 12) {
                    // Output toggle button
                    Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showOutput.toggle() } }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "terminal")
                                .font(.system(size: 13))
                                .foregroundStyle(showOutput ? .primary : .secondary)
                            
                            // Indicator dot when output available
                            if hasOutput && !showOutput {
                                Circle()
                                    .fill(.blue)
                                    .frame(width: 6, height: 6)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Toggle output")
                    
                    Spacer()
                    
                    // Keyboard shortcut hint
                    Text("⌘↵")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                    
                    // Send button
                    Button(action: addNote) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .foregroundStyle(noteText.isEmpty || isLoading ? Color.gray : Color.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(noteText.isEmpty || isLoading)
                    .keyboardShortcut(.return, modifiers: .command)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            
            // Status banner
            if showSuccess || showError {
                StatusBanner(
                    isSuccess: showSuccess,
                    message: showSuccess ? "Added to daily note" : errorMessage
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
            
            // Collapsible output panel
            if showOutput {
                OutputPanel(
                    outputText: outputText,
                    isLoading: isLoading,
                    onClear: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            outputText = ""
                            hasOutput = false
                            showOutput = false
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .onAppear {
            isTextEditorFocused = true
        }
    }
    
    private func addNote() {
        guard !noteText.isEmpty else { return }
        
        isLoading = true
        outputText = ""
        showSuccess = false
        showError = false
        
        Task.detached {
            do {
                let output = try await OpenCodeService.addNote(noteText, in: vaultDirectory, opencodePath: opencodePath)
                
                await MainActor.run {
                    outputText = output
                    hasOutput = true
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSuccess = true
                    }
                }
                
                // Auto-dismiss success and clear text
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSuccess = false
                    }
                    noteText = ""
                }
            } catch {
                await MainActor.run {
                    outputText = error.localizedDescription
                    hasOutput = true
                    errorMessage = error.localizedDescription
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showError = true
                    }
                }
                
                // Auto-dismiss error after longer delay
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showError = false
                    }
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Status Banner

struct StatusBanner: View {
    let isSuccess: Bool
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundStyle(isSuccess ? .green : .red)
            
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

// MARK: - Output Panel

struct OutputPanel: View {
    let outputText: String
    let isLoading: Bool
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Label("Output", systemImage: "terminal")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isLoading {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Running...")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                } else if !outputText.isEmpty {
                    Button(action: onClear) {
                        Text("Clear")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(4)
                }
            }
            
            // Output content
            ScrollView {
                Text(outputText.isEmpty ? "No output yet" : outputText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(outputText.isEmpty ? .tertiary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .lineSpacing(2)
            }
            .frame(maxHeight: 120)
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}
