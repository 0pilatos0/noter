import Foundation
import Combine
import SwiftUI

/// Service for managing note templates
class TemplateService: ObservableObject {
    static let shared = TemplateService()

    @Published private(set) var templates: [NoteTemplate] = []

    private let fileURL: URL

    private init() {
        // Set up file URL in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let noterDir = appSupport.appendingPathComponent("noter", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: noterDir, withIntermediateDirectories: true)

        fileURL = noterDir.appendingPathComponent("templates.json")

        // Load existing templates or use defaults
        load()
    }

    // MARK: - Public API

    /// Get templates that should show in quick actions
    var quickActionTemplates: [NoteTemplate] {
        templates
            .filter { $0.showInQuickActions }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Add a new template
    func add(_ template: NoteTemplate) {
        var newTemplate = template
        newTemplate.sortOrder = templates.count
        templates.append(newTemplate)
        persist()
    }

    /// Update an existing template
    func update(_ template: NoteTemplate) {
        guard let index = templates.firstIndex(where: { $0.id == template.id }) else { return }
        templates[index] = template
        persist()
    }

    /// Delete a template
    func delete(_ id: UUID) {
        templates.removeAll { $0.id == id }
        // Re-index sort orders
        for i in templates.indices {
            templates[i].sortOrder = i
        }
        persist()
    }

    /// Reorder templates
    func move(from source: IndexSet, to destination: Int) {
        templates.move(fromOffsets: source, toOffset: destination)
        // Re-index sort orders
        for i in templates.indices {
            templates[i].sortOrder = i
        }
        persist()
    }

    /// Reset to default templates
    func resetToDefaults() {
        templates = NoteTemplate.defaults
        persist()
    }

    /// Expand a template's variables
    func expand(_ template: NoteTemplate) -> String {
        template.expanded()
    }

    // MARK: - Persistence

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(templates)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("TemplateService: Failed to persist templates: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            // No file exists, use defaults
            templates = NoteTemplate.defaults
            persist()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            templates = try decoder.decode([NoteTemplate].self, from: data)
        } catch {
            print("TemplateService: Failed to load templates: \(error)")
            // Fall back to defaults
            templates = NoteTemplate.defaults
        }
    }
}
