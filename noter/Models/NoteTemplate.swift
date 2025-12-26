import Foundation
import AppKit

struct NoteTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var template: String
    var color: String  // System color name
    var showInQuickActions: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        template: String,
        color: String = "blue",
        showInQuickActions: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.template = template
        self.color = color
        self.showInQuickActions = showInQuickActions
        self.sortOrder = sortOrder
    }

    // MARK: - Variable Expansion

    /// Expand template variables with current values
    func expanded() -> String {
        var text = template

        let dateFormatter = DateFormatter()

        // {{date}} - Current date (YYYY-MM-DD)
        dateFormatter.dateFormat = "yyyy-MM-dd"
        text = text.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: Date()))

        // {{time}} - Current time (HH:mm)
        dateFormatter.dateFormat = "HH:mm"
        text = text.replacingOccurrences(of: "{{time}}", with: dateFormatter.string(from: Date()))

        // {{datetime}} - Full datetime
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        text = text.replacingOccurrences(of: "{{datetime}}", with: dateFormatter.string(from: Date()))

        // {{clipboard}} - Current clipboard content
        if let clipboard = NSPasteboard.general.string(forType: .string) {
            text = text.replacingOccurrences(of: "{{clipboard}}", with: clipboard)
        } else {
            text = text.replacingOccurrences(of: "{{clipboard}}", with: "")
        }

        return text
    }

    // MARK: - Default Templates

    static var defaults: [NoteTemplate] {
        [
            NoteTemplate(
                name: "Quick Task",
                icon: "checkmark.circle",
                template: "- [ ] ",
                color: "blue",
                showInQuickActions: true,
                sortOrder: 0
            ),
            NoteTemplate(
                name: "Meeting",
                icon: "person.2",
                template: """
                ## Meeting:

                ### Attendees
                -

                ### Notes
                -

                ### Action Items
                - [ ]
                """,
                color: "purple",
                showInQuickActions: true,
                sortOrder: 1
            ),
            NoteTemplate(
                name: "Idea",
                icon: "lightbulb",
                template: "#idea\n\n",
                color: "yellow",
                showInQuickActions: true,
                sortOrder: 2
            ),
            NoteTemplate(
                name: "Quick Note",
                icon: "note.text",
                template: "",
                color: "gray",
                showInQuickActions: false,
                sortOrder: 3
            )
        ]
    }

    // MARK: - Available Variables

    static var availableVariables: [(name: String, description: String)] {
        [
            ("{{date}}", "Current date (YYYY-MM-DD)"),
            ("{{time}}", "Current time (HH:mm)"),
            ("{{datetime}}", "Full date and time"),
            ("{{clipboard}}", "Clipboard content")
        ]
    }

    // MARK: - Available Colors

    static var availableColors: [String] {
        ["blue", "purple", "green", "orange", "red", "yellow", "gray", "pink", "teal"]
    }
}
