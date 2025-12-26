import SwiftUI

struct QuickActionsBar: View {
    @ObservedObject var templateService = TemplateService.shared
    let onSelect: (NoteTemplate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NoterSpacing.sm) {
                ForEach(templateService.quickActionTemplates) { template in
                    QuickActionButton(template: template) {
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal, NoterSpacing.xs)
        }
    }
}

struct QuickActionButton: View {
    let template: NoteTemplate
    let action: () -> Void

    @State private var isHovered = false

    private var templateColor: Color {
        NoterTemplateColor.from(template.color)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NoterSpacing.xs) {
                Image(systemName: template.icon)
                    .font(.system(size: NoterIconSize.xs))
                Text(template.name)
                    .font(.system(size: NoterIconSize.xs, weight: .medium))
            }
            .foregroundStyle(templateColor.opacity(isHovered ? 1.0 : 0.8))
            .padding(.horizontal, NoterSpacing.sm)
            .padding(.vertical, NoterSpacing.xs)
            .background(
                Capsule()
                    .fill(templateColor.opacity(isHovered ? 0.15 : 0.1))
            )
            .overlay(
                Capsule()
                    .stroke(templateColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: NoterAnimation.fast)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    VStack {
        QuickActionsBar { template in
            print("Selected: \(template.name)")
        }
    }
    .padding()
    .frame(width: 350)
}
