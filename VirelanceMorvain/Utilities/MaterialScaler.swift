import Foundation

enum MaterialScaler {
    static func scale(_ material: String, from basePots: Int, to targetPots: Int) -> String {
        guard basePots > 0, targetPots != basePots else { return material }
        let ratio = Double(targetPots) / Double(basePots)

        let pattern = #"^(\d+\s+\d+/\d+|\d+/\d+|\d+\.\d+|\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return material }
        let range = NSRange(material.startIndex..., in: material)
        guard let match = regex.firstMatch(in: material, range: range),
              let numRange = Range(match.range, in: material) else {
            return material
        }

        let token = String(material[numRange])
        guard let value = parseAmount(token) else { return material }
        let scaled = value * ratio
        let formatted = formatAmount(scaled)
        return formatted + material[numRange.upperBound...]
    }

    static func scaleAll(_ materials: [String], from base: Int, to target: Int) -> [String] {
        materials.map { scale($0, from: base, to: target) }
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

enum SupplyCategoryGuess {
    static func category(for material: String) -> SupplyCategory {
        let text = material.lowercased()
        if matches(text, ["soil", "mix", "peat", "coco", "perlite", "bark"]) { return .soil }
        if matches(text, ["fertilizer", "feed", "nutrient", "bloom"]) { return .fertilizer }
        if matches(text, ["shears", "pruner", "stake", "pole", "cloth", "mister", "tool"]) { return .tools }
        if matches(text, ["pot", "planter", "saucer", "hanging"]) { return .pots }
        if matches(text, ["water", "distilled", "humidity", "tray", "pebble"]) { return .waterCare }
        if matches(text, ["light", "lamp", "grow"]) { return .light }
        if matches(text, ["pest", "neem", "insect", "mite"]) { return .pestControl }
        return .other
    }

    private static func matches(_ text: String, _ keys: [String]) -> Bool {
        keys.contains { text.contains($0) }
    }
}
