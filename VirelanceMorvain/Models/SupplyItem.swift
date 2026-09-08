import Foundation

enum SupplyCategory: String, CaseIterable, Codable, Identifiable {
    case soil = "Soil"
    case fertilizer = "Fertilizer"
    case tools = "Tools"
    case pots = "Pots"
    case waterCare = "Water Care"
    case light = "Light"
    case pestControl = "Pest Control"
    case other = "Other"

    var id: String { rawValue }
}

struct SupplyItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: SupplyCategory
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: SupplyCategory,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isCompleted = isCompleted
    }
}
