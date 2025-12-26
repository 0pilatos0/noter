import SwiftUI

struct NoteInputView: View {
    @State private var noteText: String = ""
    @State private var outputText: String = ""
    @State private var isLoading: Bool = false
    @State private var bannerType: NoterStatusBanner.BannerType?
    @State private var showQueueOption: Bool = false
    @State private var failedNoteText: String = ""
    @State private var showOutput: Bool = false
    @State private var hasOutput: Bool = false
    @State private var currentOperationHandle: NoteOperationHandle?

    @FocusState private var isTextEditorFocused: Bool

    let vaultDirectory: URL
    let opencodePath: String
    let model: String
    var prefillText: String = ""

    init(vaultDirectory: URL, opencodePath: String, model: String, prefillText: String = "") {
        self.vaultDirectory = vaultDirectory
        self.opencodePath = opencodePath
        self.model = model
        self.prefillText = prefillText
        _noteText = State(initialValue: prefillText)
    }

    var body: some View {
        VStack(spacing: NoterSpacing.md) {
            // Quick actions bar
            QuickActionsBar { template in
                applyTemplate(template)
            }

            // Main input card
            NoterInputCard {
                VStack(spacing: 0) {
                    // Text editor with placeholder
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $noteText)
                            .font(NoterTypography.sectionHeader)
                            .scrollContentBackground(.hidden)
                            .background(.clear)
                            .focused($isTextEditorFocused)
                            .disabled(isLoading)

                        // Placeholder
                        if noteText.isEmpty {
                            HStack(spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: NoterIconSize.sm))
                                Text("Capture a thought...")
                            }
                            .font(NoterTypography.sectionHeader)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 0)
                            .padding(.leading, NoterSpacing.xs + NoterSpacing.xxs)
                            .allowsHitTesting(false)
                        }
                    }
                    .frame(minHeight: 100, maxHeight: 140)
                    .padding(.horizontal, NoterSpacing.md)
                    .padding(.top, NoterSpacing.md)
                    .padding(.bottom, NoterSpacing.sm)
                    .focusRing(isFocused: isTextEditorFocused, cornerRadius: NoterRadius.lg)

                    // Toolbar
                    HStack(spacing: NoterSpacing.md) {
                        // Output toggle button
                        Button(action: { withAnimation(.easeInOut(duration: NoterAnimation.normal)) { showOutput.toggle() } }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "terminal")
                                    .font(.system(size: NoterIconSize.md))
                                    .foregroundStyle(showOutput ? .primary : .secondary)

                                // Indicator dot when output available
                                if hasOutput && !showOutput {
                                    Circle()
                                        .fill(NoterColors.Status.info)
                                        .frame(width: 6, height: 6)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .help("Toggle output")
                        .accessibleIconButton(label: "Toggle output panel")

                        Spacer()

                        // Cancel button (shown when loading)
                        if isLoading {
                            NoterButton("Cancel", icon: "xmark.circle.fill", style: .tertiary) {
                                cancelNote()
                            }
                            .keyboardShortcut(.escape, modifiers: [])
                        } else {
                            // Keyboard shortcut hint
                            Text("\u{2318}\u{21A9}")
                                .font(NoterTypography.keyboardHint)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, NoterSpacing.xs + NoterSpacing.xxs)
                                .padding(.vertical, NoterSpacing.xxs)
                                .background(NoterColors.surfaceLight)
                                .cornerRadius(NoterRadius.sm)
                        }

                        // Send button
                        NoterSendButton(
                            isLoading: isLoading,
                            isDisabled: noteText.isEmpty
                        ) {
                            addNote()
                        }
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    .padding(.horizontal, NoterSpacing.md)
                    .padding(.bottom, NoterSpacing.sm + NoterSpacing.xxs)
                }
            }

            // Status banner
            if bannerType != nil {
                VStack(spacing: NoterSpacing.sm) {
                    AnimatedStatusBanner(bannerType)

                    // Queue option on error
                    if showQueueOption && !failedNoteText.isEmpty {
                        HStack(spacing: NoterSpacing.md) {
                            NoterButton("Add to Queue", icon: "tray.and.arrow.down", style: .secondary) {
                                addToQueue()
                            }

                            NoterButton("Dismiss", style: .tertiary) {
                                dismissQueueOption()
                            }
                        }
                    }
                }
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
                        withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
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
        .padding(NoterSpacing.lg)
        .onAppear {
            isTextEditorFocused = true
        }
    }

    private func cancelNote() {
        currentOperationHandle?.cancel()
        currentOperationHandle = nil
        isLoading = false

        outputText += "\n\n[Cancelled]"

        withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
            bannerType = nil
        }
    }

    private func addToQueue() {
        guard !failedNoteText.isEmpty else { return }

        NoteQueueService.shared.enqueueFailedNote(
            text: failedNoteText,
            vaultPath: vaultDirectory.path,
            model: model,
            opencodePath: opencodePath,
            error: bannerType?.message ?? "Unknown error"
        )

        withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
            bannerType = nil
            showQueueOption = false
            failedNoteText = ""
            noteText = ""
        }
    }

    private func dismissQueueOption() {
        withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
            showQueueOption = false
            failedNoteText = ""
        }
    }

    private func applyTemplate(_ template: NoteTemplate) {
        let expandedText = template.expanded()
        if noteText.isEmpty {
            noteText = expandedText
        } else {
            noteText += (noteText.hasSuffix("\n") ? "" : "\n") + expandedText
        }
        isTextEditorFocused = true
    }

    private func addNote() {
        guard !noteText.isEmpty else { return }

        isLoading = true
        outputText = ""
        bannerType = nil

        let noteToAdd = noteText

        Task {
            let (stream, handle, _) = OpenCodeService.addNoteStreaming(
                noteToAdd,
                in: vaultDirectory,
                opencodePath: opencodePath,
                model: model
            )

            currentOperationHandle = handle

            do {
                for try await chunk in stream {
                    outputText += chunk
                    if !hasOutput {
                        hasOutput = true
                    }
                }

                // Success
                withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                    bannerType = .success("Added to daily note")
                }

                HistoryService.shared.addProcessedNote(
                    text: noteToAdd,
                    vaultPath: vaultDirectory.path,
                    outputPreview: String(outputText.prefix(100))
                )

                // Unified auto-dismiss timing
                try await Task.sleep(nanoseconds: NoterStatusTiming.autoDismiss)

                withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                    bannerType = nil
                }
                noteText = ""

            } catch let error as OpenCodeService.OpenCodeError where error == .cancelled {
                // Cancelled - already handled
            } catch {
                outputText += "\n\nError: \(error.localizedDescription)"
                hasOutput = true
                failedNoteText = noteToAdd

                HistoryService.shared.addFailedNote(
                    text: noteToAdd,
                    vaultPath: vaultDirectory.path
                )

                withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                    bannerType = .error(error.localizedDescription)
                    showQueueOption = true
                }

                // Unified auto-dismiss timing
                try? await Task.sleep(nanoseconds: NoterStatusTiming.autoDismiss)

                withAnimation(.easeInOut(duration: NoterAnimation.normal)) {
                    bannerType = nil
                    showQueueOption = false
                    failedNoteText = ""
                }
            }

            currentOperationHandle = nil
            isLoading = false
        }
    }
}

// MARK: - Output Panel

struct OutputPanel: View {
    let outputText: String
    let isLoading: Bool
    let onClear: () -> Void

    var body: some View {
        NoterCard(padding: NoterSpacing.md) {
            VStack(alignment: .leading, spacing: NoterSpacing.sm) {
                // Header
                HStack {
                    Label("Output", systemImage: "terminal")
                        .font(NoterTypography.captionMedium)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if isLoading {
                        HStack(spacing: NoterSpacing.xs) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Streaming...")
                                .font(NoterTypography.captionSmall)
                                .foregroundStyle(.secondary)
                        }
                    } else if !outputText.isEmpty {
                        NoterButton("Clear", style: .tertiary) {
                            onClear()
                        }
                    }
                }

                // Output content with auto-scroll
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(outputText.isEmpty ? "No output yet" : outputText)
                            .font(NoterTypography.mono)
                            .foregroundStyle(outputText.isEmpty ? .tertiary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .lineSpacing(2)

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .frame(maxHeight: 120)
                    .onChange(of: outputText) { _, _ in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// Extension for comparing OpenCodeError
extension OpenCodeService.OpenCodeError: Equatable {
    static func == (lhs: OpenCodeService.OpenCodeError, rhs: OpenCodeService.OpenCodeError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        case (.executionFailed(let a), .executionFailed(let b)):
            return a == b
        case (.pathNotFound(let a), .pathNotFound(let b)):
            return a == b
        default:
            return false
        }
    }
}
