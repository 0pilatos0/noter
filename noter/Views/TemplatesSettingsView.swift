import SwiftUI

struct TemplatesSettingsView: View {
    @ObservedObject var templateService = TemplateService.shared
    @State private var editingTemplate: NoteTemplate?
    @State private var isCreatingNew = false
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: NoterSpacing.md) {
            // Header
            HStack {
                Text("Templates")
                    .font(NoterTypography.sectionHeader)
                    .foregroundStyle(.primary)

                Spacer()

                NoterButton("Add", icon: "plus", style: .secondary) {
                    isCreatingNew = true
                }
            }

            // Templates list
            if templateService.templates.isEmpty {
                VStack(spacing: NoterSpacing.sm) {
                    Image(systemName: "doc.text")
                        .font(.system(size: NoterIconSize.xl + NoterIconSize.xs))
                        .foregroundStyle(.tertiary)
                    Text("No templates")
                        .font(NoterTypography.body)
                        .foregroundStyle(.secondary)
                    NoterButton("Reset to Defaults", style: .tertiary) {
                        templateService.resetToDefaults()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NoterSpacing.xl)
            } else {
                NoterCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(templateService.templates) { template in
                            TemplateRow(
                                template: template,
                                onEdit: { editingTemplate = template },
                                onDelete: { templateService.delete(template.id) }
                            )

                            if template.id != templateService.templates.last?.id {
                                NoterDivider()
                            }
                        }
                    }
                }
            }

            // Reset button
            if !templateService.templates.isEmpty {
                HStack {
                    Spacer()
                    NoterButton("Reset to Defaults", style: .tertiary) {
                        showResetConfirmation = true
                    }
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
        HStack(spacing: NoterSpacing.sm + NoterSpacing.xxs) {
            // Icon and color indicator
            Image(systemName: template.icon)
                .font(.system(size: NoterIconSize.sm))
                .foregroundStyle(NoterTemplateColor.from(template.color))
                .frame(width: NoterSpacing.xl)

            // Name and quick action indicator
            VStack(alignment: .leading, spacing: NoterSpacing.xxs) {
                Text(template.name)
                    .font(NoterTypography.body)
                    .foregroundStyle(.primary)

                if template.showInQuickActions {
                    Text("Quick Action")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Actions - always visible for accessibility
            HStack(spacing: NoterSpacing.sm) {
                NoterIconButton(icon: "pencil", help: "Edit template") {
                    onEdit()
                }

                NoterIconButton(icon: "trash", style: .destructive, help: "Delete template") {
                    onDelete()
                }
            }
            .alwaysVisibleActions(isHovered: isHovered)
        }
        .padding(.horizontal, NoterSpacing.md)
        .padding(.vertical, NoterSpacing.sm)
        .contentShape(Rectangle())
        .background(isHovered ? NoterColors.surfaceSubtle : .clear)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NoterAnimation.fast)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onEdit()
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
