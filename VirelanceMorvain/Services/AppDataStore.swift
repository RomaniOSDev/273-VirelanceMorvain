import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var recipes: [Recipe]
    @Published var shoppingItems: [ShoppingItem]
    @Published var timers: [PrepTimer]
    @Published var stats: AchievementStats
    @Published var mealPlan: MealPlan

    private let recipesKey = "recipes_v1"
    private let shoppingKey = "shopping_v1"
    private let timersKey = "timers_v1"
    private let statsKey = "stats_v1"
    private let mealPlanKey = "meal_plan_v1"
    private let defaults = UserDefaults.standard

    private init() {
        if let data = defaults.data(forKey: recipesKey),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data),
           !decoded.isEmpty {
            recipes = decoded
        } else {
            recipes = RecipeSeed.recipes
        }

        if let data = defaults.data(forKey: shoppingKey),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            shoppingItems = decoded
        } else {
            shoppingItems = [
                ShoppingItem(name: "Spinach", category: .produce),
                ShoppingItem(name: "Milk", category: .dairy),
                ShoppingItem(name: "Sourdough", category: .bakery)
            ]
        }

        if let data = defaults.data(forKey: timersKey),
           let decoded = try? JSONDecoder().decode([PrepTimer].self, from: data) {
            timers = decoded.map { timer in
                var t = timer
                t.syncRemaining()
                return t
            }
        } else {
            timers = [
                PrepTimer(title: "Pasta boil", durationSeconds: 600),
                PrepTimer(title: "Rest dough", durationSeconds: 1800)
            ]
        }

        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(AchievementStats.self, from: data) {
            stats = decoded
        } else {
            stats = .empty
        }

        if let data = defaults.data(forKey: mealPlanKey),
           let decoded = try? JSONDecoder().decode(MealPlan.self, from: data) {
            mealPlan = decoded
        } else {
            mealPlan = .empty
        }

        recordActivityDay()
    }

    func persistAll() {
        if let data = try? JSONEncoder().encode(recipes) {
            defaults.set(data, forKey: recipesKey)
        }
        if let data = try? JSONEncoder().encode(shoppingItems) {
            defaults.set(data, forKey: shoppingKey)
        }
        if let data = try? JSONEncoder().encode(timers) {
            defaults.set(data, forKey: timersKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        if let data = try? JSONEncoder().encode(mealPlan) {
            defaults.set(data, forKey: mealPlanKey)
        }
    }

    func recipe(with id: UUID) -> Recipe? {
        recipes.first { $0.id == id }
    }

    func toggleFavorite(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index].isFavorite.toggle()
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func markRecipeViewed(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        if !recipes[index].viewed {
            recipes[index].viewed = true
            stats.recipesViewed += 1
            persistAll()
        }
        bumpActivity()
    }

    func updateNotes(for recipe: Recipe, notes: String) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index].notes = notes
        persistAll()
    }

    func saveRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.insert(recipe, at: 0)
        }
        persistAll()
        HapticService.success()
        SoundService.success()
        bumpActivity()
    }

    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        for key in mealPlan.assignments.keys {
            mealPlan.assignments[key]?.removeAll { $0 == recipe.id }
            if mealPlan.assignments[key]?.isEmpty == true {
                mealPlan.assignments[key] = nil
            }
        }
        persistAll()
        HapticService.medium()
    }

    func addIngredientsToShopping(from recipe: Recipe, servings: Int? = nil) {
        let target = servings ?? recipe.servings
        let scaled = IngredientScaler.scaleAll(recipe.ingredients, from: recipe.servings, to: target)
        for ingredient in scaled {
            let name = ingredient.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let exists = shoppingItems.contains {
                !$0.isCompleted && $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            if !exists {
                shoppingItems.append(
                    ShoppingItem(name: name, category: ShoppingCategoryGuess.category(for: name))
                )
            }
        }
        persistAll()
        HapticService.success()
        SoundService.success()
        bumpActivity()
    }

    func addShoppingItem(name: String, category: ShoppingCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        shoppingItems.append(ShoppingItem(name: trimmed, category: category))
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        guard let index = shoppingItems.firstIndex(where: { $0.id == item.id }) else { return }
        shoppingItems[index].isCompleted.toggle()
        if shoppingItems[index].isCompleted {
            let incomplete = shoppingItems.filter { !$0.isCompleted }
            if incomplete.isEmpty && !shoppingItems.isEmpty {
                stats.listsCompleted += 1
            }
            SoundService.tap()
        }
        persistAll()
        HapticService.selection()
        bumpActivity()
    }

    func deleteShoppingItem(_ item: ShoppingItem) {
        shoppingItems.removeAll { $0.id == item.id }
        persistAll()
        HapticService.medium()
    }

    func addTimer(title: String, minutes: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, minutes > 0 else { return }
        timers.append(PrepTimer(title: trimmed, durationSeconds: minutes * 60))
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func startTimer(_ timer: PrepTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        var t = timers[index]
        if t.remainingSeconds <= 0 {
            t.remainingSeconds = t.durationSeconds
        }
        t.isRunning = true
        t.endDate = Date().addingTimeInterval(TimeInterval(t.remainingSeconds))
        timers[index] = t
        persistAll()
        HapticService.medium()
        SoundService.tap()
        bumpActivity()
    }

    func pauseTimer(_ timer: PrepTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        var t = timers[index]
        t.syncRemaining()
        t.isRunning = false
        t.endDate = nil
        timers[index] = t
        persistAll()
        HapticService.selection()
    }

    func deleteTimer(_ timer: PrepTimer) {
        timers.removeAll { $0.id == timer.id }
        persistAll()
        HapticService.medium()
    }

    func recordTimerCompleted() {
        stats.timersCompleted += 1
        persistAll()
        bumpActivity()
    }

    func tickTimers() {
        var changed = false
        for index in timers.indices {
            let before = timers[index]
            timers[index].syncRemaining()
            if timers[index] != before {
                changed = true
            }
        }
        if changed {
            persistAll()
        }
    }

    func addRecipeToMealPlan(_ recipe: Recipe, dayKey: String) {
        var list = mealPlan.assignments[dayKey] ?? []
        guard !list.contains(recipe.id) else { return }
        list.append(recipe.id)
        mealPlan.assignments[dayKey] = list
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func removeRecipeFromMealPlan(_ recipeID: UUID, dayKey: String) {
        mealPlan.assignments[dayKey]?.removeAll { $0 == recipeID }
        if mealPlan.assignments[dayKey]?.isEmpty == true {
            mealPlan.assignments[dayKey] = nil
        }
        persistAll()
        HapticService.selection()
    }

    func moveMealPlanRecipe(dayKey: String, fromOffsets: IndexSet, toOffset: Int) {
        guard var list = mealPlan.assignments[dayKey] else { return }
        list.move(fromOffsets: fromOffsets, toOffset: toOffset)
        mealPlan.assignments[dayKey] = list
        persistAll()
    }

    func recordActivityDay() {
        let today = Self.dayKey(for: Date())
        if stats.lastActiveDay == today { return }

        if let last = stats.lastActiveDay,
           let lastDate = Self.dayFormatter.date(from: last),
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           Self.dayKey(for: yesterday) == Self.dayFormatter.string(from: lastDate) {
            stats.streakDays += 1
        } else {
            stats.streakDays = 1
        }
        stats.lastActiveDay = today
        persistAll()
    }

    func bumpActivity() {
        recordActivityDay()
        let today = Self.dayKey(for: Date())
        stats.activityByDay[today, default: 0] += 1
        persistAll()
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    func resetAll() {
        recipes = RecipeSeed.recipes
        shoppingItems = []
        timers = []
        stats = .empty
        mealPlan = .empty
        defaults.removeObject(forKey: recipesKey)
        defaults.removeObject(forKey: shoppingKey)
        defaults.removeObject(forKey: timersKey)
        defaults.removeObject(forKey: statsKey)
        defaults.removeObject(forKey: mealPlanKey)
        persistAll()
        HapticService.heavy()
    }
}
