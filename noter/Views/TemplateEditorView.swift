import SwiftUI

struct TemplateEditorView: View {
    @Binding var template: NoteTemplate
    let isNew: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var showIconPicker = false
    @FocusState private var isTemplateEditorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: NoterSpacing.lg) {
            // Header
            HStack {
                Text(isNew ? "New Template" : "Edit Template")
                    .font(NoterTypography.sectionHeader)
                Spacer()
            }

            // Name field
            VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                Text("Name")
                    .font(NoterTypography.caption)
                    .foregroundStyle(.secondary)
                TextField("Template name", text: $template.name)
                    .textFieldStyle(.roundedBorder)
                    .font(NoterTypography.body)
            }

            // Icon and Color row
            HStack(spacing: NoterSpacing.lg) {
                // Icon picker
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text("Icon")
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)

                    Button(action: { showIconPicker.toggle() }) {
                        HStack(spacing: NoterSpacing.xs + NoterSpacing.xxs) {
                            Image(systemName: template.icon)
                                .font(.system(size: NoterIconSize.md))
                            Image(systemName: "chevron.down")
                                .font(.system(size: NoterIconSize.xs - 2))
                        }
                        .padding(.horizontal, NoterSpacing.sm + NoterSpacing.xxs)
                        .padding(.vertical, NoterSpacing.xs + NoterSpacing.xxs)
                        .background(NoterColors.surfaceLight)
                        .cornerRadius(NoterRadius.md)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showIconPicker) {
                        IconPickerView(selectedIcon: $template.icon)
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                    Text("Color")
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $template.color) {
                        ForEach(NoteTemplate.availableColors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(NoterTemplateColor.from(color))
                                    .frame(width: NoterSpacing.md, height: NoterSpacing.md)
                                Text(color.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)
                }

                Spacer()
            }

            // Template content
            VStack(alignment: .leading, spacing: NoterSpacing.xs) {
                HStack {
                    Text("Template")
                        .font(NoterTypography.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Menu {
                        ForEach(NoteTemplate.availableVariables, id: \.name) { variable in
                            Button(action: {
                                template.template += variable.name
                            }) {
                                VStack(alignment: .leading) {
                                    Text(variable.name)
                                    Text(variable.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } label: {
                        Label("Insert Variable", systemImage: "plus.circle")
                            .font(NoterTypography.captionSmall)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                TextEditor(text: $template.template)
                    .font(NoterTypography.mono)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(NoterSpacing.sm)
                    .background(NoterColors.surfaceSubtle)
                    .cornerRadius(NoterRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: NoterRadius.md)
                            .stroke(NoterColors.strokeSubtle, lineWidth: 1)
                    )
                    .focused($isTemplateEditorFocused)
                    .focusRing(isFocused: isTemplateEditorFocused, cornerRadius: NoterRadius.md)
            }

            // Show in quick actions toggle
            Toggle(isOn: $template.showInQuickActions) {
                Text("Show in Quick Actions")
                    .font(NoterTypography.body)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            // Actions
            HStack {
                NoterButton("Cancel", style: .tertiary) {
                    onCancel()
                }

                Spacer()

                NoterButton("Save", style: .primary, isDisabled: template.name.isEmpty) {
                    onSave()
                }
            }
        }
        .padding(NoterSpacing.lg)
        .frame(width: 300)
    }
}

// MARK: - Icon Picker

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    private let icons = [
        "checkmark.circle", "circle", "square", "star",
        "note.text", "doc.text", "pencil", "pencil.line",
        "lightbulb", "bolt", "flame", "leaf",
        "person", "person.2", "person.3", "building",
        "calendar", "clock", "alarm", "timer",
        "tag", "bookmark", "flag", "pin",
        "folder", "tray", "archivebox", "externaldrive",
        "phone", "envelope", "paperplane", "bubble.left",
        "link", "globe", "map", "location",
        "heart", "hand.thumbsup", "hand.raised", "exclamationmark.triangle"
    ]

    var body: some View {
        VStack(spacing: NoterSpacing.sm) {
            Text("Choose Icon")
                .font(NoterTypography.captionMedium)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 6), spacing: NoterSpacing.sm) {
                ForEach(icons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                        dismiss()
                    }) {
                        Image(systemName: icon)
                            .font(.system(size: NoterIconSize.md))
                            .frame(width: 28, height: 28)
                            .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(NoterRadius.sm)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(NoterSpacing.md)
    }
}

#Preview {
    TemplateEditorView(
        template: .constant(NoteTemplate(
            name: "Test",
            icon: "checkmark.circle",
            template: "- [ ] {{time}} - ",
            color: "blue"
        )),
        isNew: true,
        onSave: {},
        onCancel: {}
    )
}
