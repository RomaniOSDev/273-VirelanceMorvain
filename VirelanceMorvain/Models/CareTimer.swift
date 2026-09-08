import Foundation

struct CareTimer: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var durationSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool
    var endDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        durationSeconds: Int,
        remainingSeconds: Int? = nil,
        isRunning: Bool = false,
        endDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.durationSeconds = durationSeconds
        self.remainingSeconds = remainingSeconds ?? durationSeconds
        self.isRunning = isRunning
        self.endDate = endDate
    }

    mutating func syncRemaining(now: Date = Date()) {
        guard isRunning, let endDate else { return }
        remainingSeconds = max(0, Int(endDate.timeIntervalSince(now)))
        if remainingSeconds == 0 {
            isRunning = false
            self.endDate = nil
        }
    }
}

struct AchievementStats: Codable {
    var plantsViewed: Int
    var listsCompleted: Int
    var streakDays: Int
    var lastActiveDay: String?
    var timersCompleted: Int
    var activityByDay: [String: Int]

    static let empty = AchievementStats(
        plantsViewed: 0,
        listsCompleted: 0,
        streakDays: 0,
        lastActiveDay: nil,
        timersCompleted: 0,
        activityByDay: [:]
    )

    enum CodingKeys: String, CodingKey {
        case plantsViewed, listsCompleted, streakDays, lastActiveDay, timersCompleted, activityByDay
    }

    init(
        plantsViewed: Int,
        listsCompleted: Int,
        streakDays: Int,
        lastActiveDay: String?,
        timersCompleted: Int = 0,
        activityByDay: [String: Int] = [:]
    ) {
        self.plantsViewed = plantsViewed
        self.listsCompleted = listsCompleted
        self.streakDays = streakDays
        self.lastActiveDay = lastActiveDay
        self.timersCompleted = timersCompleted
        self.activityByDay = activityByDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        plantsViewed = try container.decodeIfPresent(Int.self, forKey: .plantsViewed) ?? 0
        listsCompleted = try container.decodeIfPresent(Int.self, forKey: .listsCompleted) ?? 0
        streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        lastActiveDay = try container.decodeIfPresent(String.self, forKey: .lastActiveDay)
        timersCompleted = try container.decodeIfPresent(Int.self, forKey: .timersCompleted) ?? 0
        activityByDay = try container.decodeIfPresent([String: Int].self, forKey: .activityByDay) ?? [:]
    }

    func lastSevenDaysActivity() -> [(day: String, count: Int)] {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "yyyy-MM-dd"
        let short = DateFormatter()
        short.dateFormat = "E"
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> (day: String, count: Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let key = formatter.string(from: date)
            return (day: short.string(from: date), count: activityByDay[key] ?? 0)
        }
    }
}
