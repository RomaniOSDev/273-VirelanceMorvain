import Foundation
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var plants: [Plant]
    @Published var supplyItems: [SupplyItem]
    @Published var timers: [CareTimer]
    @Published var stats: AchievementStats
    @Published var careSchedule: CareSchedule

    private let plantsKey = "plants_v2"
    private let suppliesKey = "supplies_v2"
    private let timersKey = "care_timers_v2"
    private let statsKey = "atelier_stats_v2"
    private let scheduleKey = "care_schedule_v2"
    private let defaults = UserDefaults.standard

    private init() {
        if let data = defaults.data(forKey: plantsKey),
           let decoded = try? JSONDecoder().decode([Plant].self, from: data),
           !decoded.isEmpty {
            plants = decoded
        } else {
            plants = PlantSeed.plants
        }

        if let data = defaults.data(forKey: suppliesKey),
           let decoded = try? JSONDecoder().decode([SupplyItem].self, from: data) {
            supplyItems = decoded
        } else {
            supplyItems = [
                SupplyItem(name: "Potting Mix", category: .soil),
                SupplyItem(name: "Slow-Release Fertilizer", category: .fertilizer),
                SupplyItem(name: "Mister Bottle", category: .waterCare)
            ]
        }

        if let data = defaults.data(forKey: timersKey),
           let decoded = try? JSONDecoder().decode([CareTimer].self, from: data) {
            timers = decoded.map { timer in
                var t = timer
                t.syncRemaining()
                return t
            }
        } else {
            timers = [
                CareTimer(title: "Deep soak", durationSeconds: 900),
                CareTimer(title: "Mist leaves", durationSeconds: 300)
            ]
        }

        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(AchievementStats.self, from: data) {
            stats = decoded
        } else {
            stats = .empty
        }

        if let data = defaults.data(forKey: scheduleKey),
           let decoded = try? JSONDecoder().decode(CareSchedule.self, from: data) {
            careSchedule = decoded
        } else {
            careSchedule = .empty
        }

        recordActivityDay()
    }

    func persistAll() {
        if let data = try? JSONEncoder().encode(plants) {
            defaults.set(data, forKey: plantsKey)
        }
        if let data = try? JSONEncoder().encode(supplyItems) {
            defaults.set(data, forKey: suppliesKey)
        }
        if let data = try? JSONEncoder().encode(timers) {
            defaults.set(data, forKey: timersKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        if let data = try? JSONEncoder().encode(careSchedule) {
            defaults.set(data, forKey: scheduleKey)
        }
    }

    func plant(with id: UUID) -> Plant? {
        plants.first { $0.id == id }
    }

    func toggleFavorite(_ plant: Plant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index].isFavorite.toggle()
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func markPlantViewed(_ plant: Plant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        if !plants[index].viewed {
            plants[index].viewed = true
            stats.plantsViewed += 1
            persistAll()
        }
        bumpActivity()
    }

    func updateNotes(for plant: Plant, notes: String) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index].notes = notes
        persistAll()
    }

    func savePlant(_ plant: Plant) {
        if let index = plants.firstIndex(where: { $0.id == plant.id }) {
            plants[index] = plant
        } else {
            plants.insert(plant, at: 0)
        }
        persistAll()
        HapticService.success()
        SoundService.success()
        bumpActivity()
    }

    func deletePlant(_ plant: Plant) {
        plants.removeAll { $0.id == plant.id }
        for key in careSchedule.assignments.keys {
            careSchedule.assignments[key]?.removeAll { $0 == plant.id }
            if careSchedule.assignments[key]?.isEmpty == true {
                careSchedule.assignments[key] = nil
            }
        }
        persistAll()
        HapticService.medium()
    }

    func addMaterialsToSupplies(from plant: Plant, potCount: Int? = nil) {
        let target = potCount ?? plant.potCount
        let scaled = MaterialScaler.scaleAll(plant.materials, from: plant.potCount, to: target)
        for material in scaled {
            let name = material.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let exists = supplyItems.contains {
                !$0.isCompleted && $0.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            }
            if !exists {
                supplyItems.append(
                    SupplyItem(name: name, category: SupplyCategoryGuess.category(for: name))
                )
            }
        }
        persistAll()
        HapticService.success()
        SoundService.success()
        bumpActivity()
    }

    func addSupplyItem(name: String, category: SupplyCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        supplyItems.append(SupplyItem(name: trimmed, category: category))
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func toggleSupplyItem(_ item: SupplyItem) {
        guard let index = supplyItems.firstIndex(where: { $0.id == item.id }) else { return }
        supplyItems[index].isCompleted.toggle()
        if supplyItems[index].isCompleted {
            let incomplete = supplyItems.filter { !$0.isCompleted }
            if incomplete.isEmpty && !supplyItems.isEmpty {
                stats.listsCompleted += 1
            }
            SoundService.tap()
        }
        persistAll()
        HapticService.selection()
        bumpActivity()
    }

    func deleteSupplyItem(_ item: SupplyItem) {
        supplyItems.removeAll { $0.id == item.id }
        persistAll()
        HapticService.medium()
    }

    func addTimer(title: String, minutes: Int) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, minutes > 0 else { return }
        timers.append(CareTimer(title: trimmed, durationSeconds: minutes * 60))
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func startTimer(_ timer: CareTimer) {
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

    func pauseTimer(_ timer: CareTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        var t = timers[index]
        t.syncRemaining()
        t.isRunning = false
        t.endDate = nil
        timers[index] = t
        persistAll()
        HapticService.selection()
    }

    func deleteTimer(_ timer: CareTimer) {
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

    func addPlantToCareSchedule(_ plant: Plant, dayKey: String) {
        var list = careSchedule.assignments[dayKey] ?? []
        guard !list.contains(plant.id) else { return }
        list.append(plant.id)
        careSchedule.assignments[dayKey] = list
        persistAll()
        HapticService.light()
        SoundService.tap()
        bumpActivity()
    }

    func removePlantFromCareSchedule(_ plantID: UUID, dayKey: String) {
        careSchedule.assignments[dayKey]?.removeAll { $0 == plantID }
        if careSchedule.assignments[dayKey]?.isEmpty == true {
            careSchedule.assignments[dayKey] = nil
        }
        persistAll()
        HapticService.selection()
    }

    func moveCareSchedulePlant(dayKey: String, fromOffsets: IndexSet, toOffset: Int) {
        guard var list = careSchedule.assignments[dayKey] else { return }
        list.move(fromOffsets: fromOffsets, toOffset: toOffset)
        careSchedule.assignments[dayKey] = list
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
        plants = PlantSeed.plants
        supplyItems = []
        timers = []
        stats = .empty
        careSchedule = .empty
        defaults.removeObject(forKey: plantsKey)
        defaults.removeObject(forKey: suppliesKey)
        defaults.removeObject(forKey: timersKey)
        defaults.removeObject(forKey: statsKey)
        defaults.removeObject(forKey: scheduleKey)
        persistAll()
        HapticService.heavy()
    }
}
