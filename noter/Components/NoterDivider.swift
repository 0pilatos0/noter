import SwiftUI

// MARK: - NoterDivider
/// Consistent divider component replacing all inline Rectangle().fill() patterns
struct NoterDivider: View {
    let inset: CGFloat
    let thickness: CGFloat

    init(inset: CGFloat = 0, thickness: CGFloat = 1) {
        self.inset = inset
        self.thickness = thickness
    }

    var body: some View {
        Rectangle()
            .fill(NoterColors.divider)
            .frame(height: thickness)
            .padding(.horizontal, inset)
    }
}

// MARK: - NoterVerticalDivider
/// Vertical divider for horizontal layouts
struct NoterVerticalDivider: View {
    let inset: CGFloat
    let thickness: CGFloat

    init(inset: CGFloat = 0, thickness: CGFloat = 1) {
        self.inset = inset
        self.thickness = thickness
    }

    var body: some View {
        Rectangle()
            .fill(NoterColors.divider)
            .frame(width: thickness)
            .padding(.vertical, inset)
    }
}

// MARK: - Previews
#Preview("Dividers") {
    VStack(spacing: 20) {
        Text("Content above")
        NoterDivider()
        Text("Content below")

        Spacer().frame(height: 20)

        Text("With inset")
        NoterDivider(inset: 16)
        Text("Content below")

        Spacer().frame(height: 20)

        HStack {
            Text("Left")
            NoterVerticalDivider()
            Text("Right")
        }
        .frame(height: 40)
    }
    .padding()
}
