import Foundation

enum IngredientScaler {
    static func scale(_ ingredient: String, from baseServings: Int, to targetServings: Int) -> String {
        guard baseServings > 0, targetServings != baseServings else { return ingredient }
        let ratio = Double(targetServings) / Double(baseServings)

        let pattern = #"^(\d+\s+\d+/\d+|\d+/\d+|\d+\.\d+|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return ingredient }
        let range = NSRange(ingredient.startIndex..., in: ingredient)
        guard let match = regex.firstMatch(in: ingredient, range: range),
              let numRange = Range(match.range, in: ingredient) else {
            return ingredient
        }

        let token = String(ingredient[numRange])
        guard let value = parseAmount(token) else { return ingredient }
        let scaled = value * ratio
        let formatted = formatAmount(scaled)
        return formatted + ingredient[numRange.upperBound...]
    }

    static func scaleAll(_ ingredients: [String], from base: Int, to target: Int) -> [String] {
        ingredients.map { scale($0, from: base, to: target) }
    }

    private static func parseAmount(_ token: String) -> Double? {
        let trimmed = token.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(" ") {
            let parts = trimmed.split(separator: " ")
            guard parts.count == 2,
                  let whole = Double(parts[0]),
                  let frac = parseFraction(String(parts[1])) else { return nil }
            return whole + frac
        }
        if trimmed.contains("/") {
            return parseFraction(trimmed)
        }
        return Double(trimmed)
    }

    private static func parseFraction(_ token: String) -> Double? {
        let parts = token.split(separator: "/")
        guard parts.count == 2,
              let n = Double(parts[0]),
              let d = Double(parts[1]),
              d != 0 else { return nil }
        return n / d
    }

    private static func formatAmount(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if abs(rounded - rounded.rounded()) < 0.001 {
            return String(Int(rounded.rounded()))
        }
        if abs(rounded * 2 - (rounded * 2).rounded()) < 0.01 {
            let whole = Int(rounded)
            let frac = rounded - Double(whole)
            if abs(frac - 0.5) < 0.01 {
                return whole == 0 ? "1/2" : "\(whole) 1/2"
            }
        }
        return String(format: "%g", rounded)
    }
}

enum ShoppingCategoryGuess {
    static func category(for ingredient: String) -> ShoppingCategory {
        let text = ingredient.lowercased()
        if matches(text, ["milk", "cheese", "yogurt", "cream", "butter", "parmesan"]) { return .dairy }
        if matches(text, ["bread", "sourdough", "tortilla", "bun", "bagel"]) { return .bakery }
        if matches(text, ["chicken", "beef", "pork", "turkey", "thigh", "meat"]) { return .meat }
        if matches(text, ["salmon", "fish", "shrimp", "tuna"]) { return .meat }
        if matches(text, ["frozen"]) { return .frozen }
        if matches(text, ["juice", "soda", "wine", "beer", "broth", "stock"]) { return .beverages }
        if matches(text, ["pasta", "rice", "oil", "sauce", "spice", "cumin", "paprika", "salt", "pepper", "soy", "honey", "oats", "lentil", "chickpea", "flour"]) {
            return .pantry
        }
        if matches(text, ["spinach", "lettuce", "tomato", "onion", "garlic", "carrot", "celery", "pepper", "broccoli", "avocado", "lemon", "lime", "berry", "cucumber", "herb", "basil", "rosemary", "ginger", "pea"]) {
            return .produce
        }
        return .other
    }

    private static func matches(_ text: String, _ keys: [String]) -> Bool {
        keys.contains { text.contains($0) }
    }
}
