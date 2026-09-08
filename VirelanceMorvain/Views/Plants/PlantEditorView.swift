import SwiftUI

struct PlantEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let plant: Plant?

    @State private var title = ""
    @State private var category = "Other"
    @State private var careMinutes = 20
    @State private var potCount = 2
    @State private var difficulty: CareDifficulty = .medium
    @State private var materialsText = ""
    @State private var stepsText = ""

    private var isEditing: Bool { plant != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                Form {
                    Section("Basics") {
                        TextField("Title", text: $title)
                        Picker("Category", selection: $category) {
                            ForEach(PlantSeed.categories, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(CareDifficulty.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        Stepper("Care time: \(careMinutes) min", value: $careMinutes, in: 1...240)
                        Stepper("Pots: \(potCount)", value: $potCount, in: 1...24)
                    }

                    Section("Materials (one per line)") {
                        TextEditor(text: $materialsText)
                            .frame(minHeight: 120)
                    }

                    Section("Care Steps (one per line)") {
                        TextEditor(text: $stepsText)
                            .frame(minHeight: 140)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Plant" : "New Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !lines(from: materialsText).isEmpty
            && !lines(from: stepsText).isEmpty
    }

    private func load() {
        guard let plant else { return }
        title = plant.title
        category = plant.category
        careMinutes = plant.careMinutes
        potCount = plant.potCount
        difficulty = plant.difficulty
        materialsText = plant.materials.joined(separator: "\n")
        stepsText = plant.careSteps.joined(separator: "\n")
    }

    private func save() {
        let saved = Plant(
            id: plant?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            careMinutes: careMinutes,
            potCount: potCount,
            materials: lines(from: materialsText),
            careSteps: lines(from: stepsText),
            isFavorite: plant?.isFavorite ?? false,
            viewed: plant?.viewed ?? false,
            notes: plant?.notes ?? "",
            isCustom: true,
            difficulty: difficulty
        )
        store.savePlant(saved)
        dismiss()
    }

    private func lines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
