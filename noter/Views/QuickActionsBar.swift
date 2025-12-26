import SwiftUI

struct QuickActionsBar: View {
    @ObservedObject var templateService = TemplateService.shared
    let onSelect: (NoteTemplate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(templateService.quickActionTemplates) { template in
                    QuickActionButton(template: template) {
                        onSelect(template)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct QuickActionButton: View {
    let template: NoteTemplate
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: template.icon)
                    .font(.system(size: 10))
                Text(template.name)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(templateColor.opacity(isHovered ? 1.0 : 0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private var templateColor: Color {
        switch template.color {
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

#Preview {
    VStack {
        QuickActionsBar { template in
            print("Selected: \(template.name)")
        }
    }
    .padding()
    .frame(width: 350)
}
