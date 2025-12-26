import SwiftUI

struct TemplatesSettingsView: View {
    @ObservedObject var templateService = TemplateService.shared
    @State private var editingTemplate: NoteTemplate?
    @State private var isCreatingNew = false
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Templates")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: { isCreatingNew = true }) {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }

            // Templates list
            if templateService.templates.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 24))
                        .foregroundStyle(.tertiary)
                    Text("No templates")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Button("Reset to Defaults") {
                        templateService.resetToDefaults()
                    }
                    .font(.system(size: 11))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(templateService.templates) { template in
                        TemplateRow(
                            template: template,
                            onEdit: { editingTemplate = template },
                            onDelete: { templateService.delete(template.id) }
                        )

                        if template.id != templateService.templates.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }

            // Reset button
            if !templateService.templates.isEmpty {
                HStack {
                    Spacer()
                    Button(action: { showResetConfirmation = true }) {
                        Text("Reset to Defaults")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $editingTemplate) { template in
            TemplateEditorSheet(
                template: template,
                isNew: false,
                onSave: { updated in
                    templateService.update(updated)
                    editingTemplate = nil
                },
                onCancel: {
                    editingTemplate = nil
                }
            )
        }
        .sheet(isPresented: $isCreatingNew) {
            TemplateEditorSheet(
                template: NoteTemplate(
                    name: "",
                    icon: "note.text",
                    template: "",
                    color: "blue"
                ),
                isNew: true,
                onSave: { newTemplate in
                    templateService.add(newTemplate)
                    isCreatingNew = false
                },
                onCancel: {
                    isCreatingNew = false
                }
            )
        }
        .confirmationDialog(
            "Reset Templates",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Defaults", role: .destructive) {
                templateService.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace all templates with the default set.")
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: NoteTemplate
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // Icon and color indicator
            Image(systemName: template.icon)
                .font(.system(size: 12))
                .foregroundStyle(colorForName(template.color))
                .frame(width: 20)

            // Name and quick action indicator
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 12))
                    .foregroundStyle(.primary)

                if template.showInQuickActions {
                    Text("Quick Action")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Actions (visible on hover)
            if isHovered {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onEdit()
        }
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

// MARK: - Template Editor Sheet

struct TemplateEditorSheet: View {
    @State var template: NoteTemplate
    let isNew: Bool
    let onSave: (NoteTemplate) -> Void
    let onCancel: () -> Void

    var body: some View {
        TemplateEditorView(
            template: $template,
            isNew: isNew,
            onSave: { onSave(template) },
            onCancel: onCancel
        )
    }
}

#Preview {
    TemplatesSettingsView()
        .frame(width: 350)
        .padding()
}
