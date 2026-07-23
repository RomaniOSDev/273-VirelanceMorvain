import SwiftUI

struct RecipeEditorView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?

    @State private var title = ""
    @State private var category = "Other"
    @State private var cookTime = 20
    @State private var servings = 2
    @State private var difficulty: RecipeDifficulty = .medium
    @State private var ingredientsText = ""
    @State private var stepsText = ""

    private var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                Form {
                    Section("Basics") {
                        TextField("Title", text: $title)
                        Picker("Category", selection: $category) {
                            ForEach(RecipeSeed.categories, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(RecipeDifficulty.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        Stepper("Cook time: \(cookTime) min", value: $cookTime, in: 1...240)
                        Stepper("Servings: \(servings)", value: $servings, in: 1...24)
                    }

                    Section("Ingredients (one per line)") {
                        TextEditor(text: $ingredientsText)
                            .frame(minHeight: 120)
                    }

                    Section("Steps (one per line)") {
                        TextEditor(text: $stepsText)
                            .frame(minHeight: 140)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
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
            && !lines(from: ingredientsText).isEmpty
            && !lines(from: stepsText).isEmpty
    }

    private func load() {
        guard let recipe else { return }
        title = recipe.title
        category = recipe.category
        cookTime = recipe.cookTimeMinutes
        servings = recipe.servings
        difficulty = recipe.difficulty
        ingredientsText = recipe.ingredients.joined(separator: "\n")
        stepsText = recipe.steps.joined(separator: "\n")
    }

    private func save() {
        let saved = Recipe(
            id: recipe?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            cookTimeMinutes: cookTime,
            servings: servings,
            ingredients: lines(from: ingredientsText),
            steps: lines(from: stepsText),
            isFavorite: recipe?.isFavorite ?? false,
            viewed: recipe?.viewed ?? false,
            notes: recipe?.notes ?? "",
            isCustom: true,
            difficulty: difficulty
        )
        store.saveRecipe(saved)
        dismiss()
    }

    private func lines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
