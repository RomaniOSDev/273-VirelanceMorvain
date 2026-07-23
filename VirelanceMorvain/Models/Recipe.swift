import Foundation

enum RecipeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var label: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

struct Recipe: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var cookTimeMinutes: Int
    var servings: Int
    var ingredients: [String]
    var steps: [String]
    var isFavorite: Bool
    var viewed: Bool
    var notes: String
    var isCustom: Bool
    var difficulty: RecipeDifficulty

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        cookTimeMinutes: Int,
        servings: Int,
        ingredients: [String],
        steps: [String],
        isFavorite: Bool = false,
        viewed: Bool = false,
        notes: String = "",
        isCustom: Bool = false,
        difficulty: RecipeDifficulty = .medium
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.ingredients = ingredients
        self.steps = steps
        self.isFavorite = isFavorite
        self.viewed = viewed
        self.notes = notes
        self.isCustom = isCustom
        self.difficulty = difficulty
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, cookTimeMinutes, servings, ingredients, steps
        case isFavorite, viewed, notes, isCustom, difficulty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(String.self, forKey: .category)
        cookTimeMinutes = try c.decode(Int.self, forKey: .cookTimeMinutes)
        servings = try c.decode(Int.self, forKey: .servings)
        ingredients = try c.decode([String].self, forKey: .ingredients)
        steps = try c.decode([String].self, forKey: .steps)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        viewed = try c.decodeIfPresent(Bool.self, forKey: .viewed) ?? false
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        difficulty = try c.decodeIfPresent(RecipeDifficulty.self, forKey: .difficulty)
            ?? Self.inferredDifficulty(minutes: cookTimeMinutes)
    }

    private static func inferredDifficulty(minutes: Int) -> RecipeDifficulty {
        if minutes <= 15 { return .easy }
        if minutes <= 30 { return .medium }
        return .hard
    }
}

enum RecipeSeed {
    static let recipes: [Recipe] = [
        Recipe(
            title: "Lemon Herb Chicken",
            category: "Poultry",
            cookTimeMinutes: 35,
            servings: 4,
            ingredients: ["4 chicken thighs", "2 lemons", "Fresh rosemary", "Olive oil", "Garlic", "Salt", "Pepper"],
            steps: [
                "Preheat oven to 400°F (200°C).",
                "Mix lemon juice, oil, garlic, and rosemary.",
                "Coat chicken and season well.",
                "Roast for 30–35 minutes until golden."
            ],
            difficulty: .medium
        ),
        Recipe(
            title: "Garden Vegetable Stir-Fry",
            category: "Vegetarian",
            cookTimeMinutes: 20,
            servings: 3,
            ingredients: ["Broccoli", "Bell peppers", "Carrots", "Snap peas", "Soy sauce", "Ginger", "Sesame oil"],
            steps: [
                "Chop all vegetables into bite-size pieces.",
                "Heat sesame oil in a wok.",
                "Stir-fry vegetables for 6–8 minutes.",
                "Add soy sauce and ginger; toss to finish."
            ],
            difficulty: .easy
        ),
        Recipe(
            title: "Creamy Tomato Pasta",
            category: "Pasta",
            cookTimeMinutes: 25,
            servings: 4,
            ingredients: ["Pasta", "Crushed tomatoes", "Heavy cream", "Onion", "Garlic", "Basil", "Parmesan"],
            steps: [
                "Cook pasta until al dente.",
                "Sauté onion and garlic until soft.",
                "Add tomatoes and simmer 10 minutes.",
                "Stir in cream and basil; toss with pasta."
            ],
            difficulty: .easy
        ),
        Recipe(
            title: "Berry Overnight Oats",
            category: "Breakfast",
            cookTimeMinutes: 10,
            servings: 2,
            ingredients: ["Rolled oats", "Milk", "Greek yogurt", "Honey", "Mixed berries", "Chia seeds"],
            steps: [
                "Combine oats, milk, yogurt, and chia.",
                "Sweeten with honey.",
                "Chill overnight.",
                "Top with berries before serving."
            ],
            difficulty: .easy
        ),
        Recipe(
            title: "Seared Salmon Bowl",
            category: "Seafood",
            cookTimeMinutes: 30,
            servings: 2,
            ingredients: ["Salmon fillets", "Rice", "Cucumber", "Avocado", "Soy sauce", "Sesame seeds"],
            steps: [
                "Cook rice and set aside.",
                "Season and sear salmon 3–4 minutes per side.",
                "Slice cucumber and avocado.",
                "Assemble bowls and drizzle soy sauce."
            ],
            difficulty: .medium
        ),
        Recipe(
            title: "Hearty Lentil Soup",
            category: "Soup",
            cookTimeMinutes: 45,
            servings: 6,
            ingredients: ["Dried lentils", "Carrots", "Celery", "Onion", "Vegetable broth", "Cumin", "Bay leaf"],
            steps: [
                "Sauté onion, carrots, and celery.",
                "Add lentils, broth, cumin, and bay leaf.",
                "Simmer 35–40 minutes until tender.",
                "Season and serve warm."
            ],
            difficulty: .hard
        ),
        Recipe(
            title: "Avocado Toast Plate",
            category: "Breakfast",
            cookTimeMinutes: 12,
            servings: 2,
            ingredients: ["Sourdough bread", "Ripe avocado", "Cherry tomatoes", "Lemon", "Chili flakes", "Olive oil"],
            steps: [
                "Toast bread until crisp.",
                "Mash avocado with lemon and salt.",
                "Spread on toast and top with tomatoes.",
                "Finish with chili flakes and olive oil."
            ],
            difficulty: .easy
        ),
        Recipe(
            title: "Spiced Chickpea Wrap",
            category: "Vegetarian",
            cookTimeMinutes: 18,
            servings: 3,
            ingredients: ["Chickpeas", "Tortillas", "Yogurt sauce", "Lettuce", "Cumin", "Paprika", "Lime"],
            steps: [
                "Warm chickpeas with cumin and paprika.",
                "Warm tortillas lightly.",
                "Fill with chickpeas, lettuce, and yogurt sauce.",
                "Squeeze lime over and roll tightly."
            ],
            difficulty: .easy
        )
    ]

    static let categories = ["Poultry", "Vegetarian", "Pasta", "Breakfast", "Seafood", "Soup", "Other"]
}
