import Foundation

enum ShoppingCategory: String, CaseIterable, Codable, Identifiable {
    case produce = "Produce"
    case dairy = "Dairy"
    case bakery = "Bakery"
    case meat = "Meat"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case other = "Other"

    var id: String { rawValue }
}

struct ShoppingItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: ShoppingCategory
    var isCompleted: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: ShoppingCategory,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.isCompleted = isCompleted
    }
}
