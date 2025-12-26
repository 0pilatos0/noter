import SwiftUI

struct TemplateEditorView: View {
    @Binding var template: NoteTemplate
    let isNew: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var showIconPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(isNew ? "New Template" : "Edit Template")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }

            // Name field
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Template name", text: $template.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
            }

            // Icon and Color row
            HStack(spacing: 16) {
                // Icon picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Icon")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Button(action: { showIconPicker.toggle() }) {
                        HStack(spacing: 6) {
                            Image(systemName: template.icon)
                                .font(.system(size: 14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showIconPicker) {
                        IconPickerView(selectedIcon: $template.icon)
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Color")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Picker("", selection: $template.color) {
                        ForEach(NoteTemplate.availableColors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(colorForName(color))
                                    .frame(width: 12, height: 12)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Template")
                        .font(.system(size: 11))
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
                            .font(.system(size: 10))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }

                TextEditor(text: $template.template)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }

            // Show in quick actions toggle
            Toggle(isOn: $template.showInQuickActions) {
                Text("Show in Quick Actions")
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            // Actions
            HStack {
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)

                Spacer()

                Button("Save", action: onSave)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(template.name.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "gray": return .gray
        case "pink": return .pink
        case "teal": return .teal
        default: return .blue
        }
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
        VStack(spacing: 8) {
            Text("Choose Icon")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32)), count: 6), spacing: 8) {
                ForEach(icons, id: \.self) { icon in
                    Button(action: {
                        selectedIcon = icon
                        dismiss()
                    }) {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
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
