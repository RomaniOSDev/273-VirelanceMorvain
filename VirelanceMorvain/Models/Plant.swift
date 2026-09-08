import Foundation

enum CareDifficulty: String, Codable, CaseIterable, Identifiable {
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

struct Plant: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var category: String
    var careMinutes: Int
    var potCount: Int
    var materials: [String]
    var careSteps: [String]
    var isFavorite: Bool
    var viewed: Bool
    var notes: String
    var isCustom: Bool
    var difficulty: CareDifficulty

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        careMinutes: Int,
        potCount: Int,
        materials: [String],
        careSteps: [String],
        isFavorite: Bool = false,
        viewed: Bool = false,
        notes: String = "",
        isCustom: Bool = false,
        difficulty: CareDifficulty = .medium
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.careMinutes = careMinutes
        self.potCount = potCount
        self.materials = materials
        self.careSteps = careSteps
        self.isFavorite = isFavorite
        self.viewed = viewed
        self.notes = notes
        self.isCustom = isCustom
        self.difficulty = difficulty
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, careMinutes, potCount, materials, careSteps
        case isFavorite, viewed, notes, isCustom, difficulty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        category = try c.decode(String.self, forKey: .category)
        careMinutes = try c.decode(Int.self, forKey: .careMinutes)
        potCount = try c.decode(Int.self, forKey: .potCount)
        materials = try c.decode([String].self, forKey: .materials)
        careSteps = try c.decode([String].self, forKey: .careSteps)
        isFavorite = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        viewed = try c.decodeIfPresent(Bool.self, forKey: .viewed) ?? false
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCustom = try c.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        difficulty = try c.decodeIfPresent(CareDifficulty.self, forKey: .difficulty)
            ?? Self.inferredDifficulty(minutes: careMinutes)
    }

    private static func inferredDifficulty(minutes: Int) -> CareDifficulty {
        if minutes <= 15 { return .easy }
        if minutes <= 30 { return .medium }
        return .hard
    }
}

enum PlantSeed {
    static let plants: [Plant] = [
        Plant(
            title: "Monstera Deliciosa",
            category: "Tropical",
            careMinutes: 25,
            potCount: 2,
            materials: ["Chunky aroid mix", "Moss pole", "Balanced 20-20-20 fertilizer", "Filtered water", "Neem oil", "Soft cloth"],
            careSteps: [
                "Check the top two inches of soil — water only when dry.",
                "Water slowly until it drains, then empty the saucer.",
                "Wipe each leaf and guide new growth onto the moss pole.",
                "Feed diluted fertilizer every third watering in spring."
            ],
            difficulty: .medium
        ),
        Plant(
            title: "Snake Plant",
            category: "Succulent",
            careMinutes: 10,
            potCount: 3,
            materials: ["Cactus and succulent mix", "Terracotta pot", "Low-nitrogen fertilizer", "Coarse perlite"],
            careSteps: [
                "Let the mix dry out completely between drinks.",
                "Water at the rim, never into the crown of the leaves.",
                "Rotate the pot a quarter turn for even, upright growth.",
                "Feed once in spring and once in midsummer."
            ],
            difficulty: .easy
        ),
        Plant(
            title: "Peace Lily",
            category: "Flowering",
            careMinutes: 20,
            potCount: 1,
            materials: ["Peat-based potting mix", "Bloom-booster fertilizer", "Distilled water", "Pebble humidity tray"],
            careSteps: [
                "Water as soon as the leaves begin to droop slightly.",
                "Use room-temperature distilled water to avoid leaf tip burn.",
                "Snip spent blooms and yellowing leaves at the base.",
                "Keep the humidity tray topped up through winter."
            ],
            difficulty: .medium
        ),
        Plant(
            title: "Fiddle Leaf Fig",
            category: "Tropical",
            careMinutes: 45,
            potCount: 1,
            materials: ["Well-draining indoor tree mix", "Deep nursery pot", "High-nitrogen fertilizer", "Moisture meter", "Leaf shine cloth", "Stake"],
            careSteps: [
                "Probe the soil to a depth of three inches before watering.",
                "Water thoroughly in one pass and never leave it standing.",
                "Dust every leaf so it can gather all available light.",
                "Keep it in one bright spot — it resents being moved.",
                "Feed every two weeks from March through September."
            ],
            difficulty: .hard
        ),
        Plant(
            title: "Pothos Marble Queen",
            category: "Trailing",
            careMinutes: 12,
            potCount: 2,
            materials: ["All-purpose potting mix", "Hanging planter", "Liquid houseplant food", "Pruning snips"],
            careSteps: [
                "Water when the top inch of the mix feels dry.",
                "Trim leggy vines just above a node to keep it full.",
                "Root the cuttings in water to fill out the pot.",
                "Give it bright indirect light to hold the variegation."
            ],
            difficulty: .easy
        ),
        Plant(
            title: "ZZ Plant",
            category: "Low Light",
            careMinutes: 8,
            potCount: 2,
            materials: ["Gritty potting mix", "Glazed ceramic pot", "Slow-release pellets"],
            careSteps: [
                "Water deeply, then wait until the mix is bone dry.",
                "Skip watering entirely during the darkest winter weeks.",
                "Wipe the glossy leaves once a month.",
                "Scatter a few slow-release pellets each spring."
            ],
            difficulty: .easy
        ),
        Plant(
            title: "Calathea Orbifolia",
            category: "Fern",
            careMinutes: 35,
            potCount: 1,
            materials: ["Moisture-retentive mix", "Distilled water", "Humidifier", "Gentle organic fertilizer", "Fine mister"],
            careSteps: [
                "Keep the mix evenly damp but never waterlogged.",
                "Only ever use distilled or rainwater on this one.",
                "Hold humidity above sixty percent day and night.",
                "Mist the undersides of the leaves each morning.",
                "Trim crisped edges with clean snips."
            ],
            difficulty: .hard
        ),
        Plant(
            title: "String of Pearls",
            category: "Trailing",
            careMinutes: 15,
            potCount: 1,
            materials: ["Succulent mix with pumice", "Shallow hanging pot", "Diluted cactus fertilizer", "Bamboo skewer"],
            careSteps: [
                "Water sparingly and only from the side of the pot.",
                "Give it the brightest window you have.",
                "Tuck bare strands back onto the soil to re-root.",
                "Feed at quarter strength twice during the growing season."
            ],
            difficulty: .medium
        )
    ]

    static let categories = ["Tropical", "Succulent", "Fern", "Flowering", "Trailing", "Low Light", "Other"]
}
