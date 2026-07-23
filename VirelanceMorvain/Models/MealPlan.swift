import Foundation

struct MealPlan: Codable {
    /// yyyy-MM-dd → recipe IDs for that day
    var assignments: [String: [UUID]]

    static let empty = MealPlan(assignments: [:])

    func recipeIDs(for dayKey: String) -> [UUID] {
        assignments[dayKey] ?? []
    }
}

enum MealPlanCalendar {
    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(for date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func startOfWeek(containing date: Date = Date()) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    static func weekDates(from start: Date) -> [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    static func weekdayLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    static func shortDateLabel(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}
