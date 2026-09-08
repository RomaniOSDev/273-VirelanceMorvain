import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme

    private var categoryData: [(name: String, count: Int)] {
        let grouped = Dictionary(grouping: store.plants.filter(\.viewed), by: \.category)
        return grouped
            .map { (name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var overviewData: [(label: String, value: Int, color: Color)] {
        [
            ("Viewed", store.stats.plantsViewed, Color("AppPrimary")),
            ("Lists", store.stats.listsCompleted, Color(red: 0.35, green: 0.72, blue: 0.95)),
            ("Streak", store.stats.streakDays, Color(red: 1.0, green: 0.62, blue: 0.22)),
            ("Favorites", store.plants.filter(\.isFavorite).count, Color("AppAccent")),
            ("Timers", store.stats.timersCompleted, Color(red: 0.35, green: 0.78, blue: 0.45))
        ]
    }

    private var weeklyActivity: [(day: String, count: Int)] {
        store.stats.lastSevenDaysActivity()
    }

    private var suppliesProgress: (done: Int, left: Int) {
        let done = store.supplyItems.filter(\.isCompleted).count
        let left = store.supplyItems.count - done
        return (done, max(left, 0))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        overviewCards

                        chartCard(title: "Activity Overview") {
                            Chart(overviewData, id: \.label) { item in
                                BarMark(
                                    x: .value("Metric", item.label),
                                    y: .value("Count", item.value)
                                )
                                .foregroundStyle(item.color.gradient)
                                .cornerRadius(6)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 180)
                        }

                        chartCard(title: "Last 7 Days") {
                            Chart(weeklyActivity, id: \.day) { item in
                                LineMark(
                                    x: .value("Day", item.day),
                                    y: .value("Actions", item.count)
                                )
                                .foregroundStyle(Color("AppPrimary"))
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Day", item.day),
                                    y: .value("Actions", item.count)
                                )
                                .foregroundStyle(Color("AppPrimary").opacity(0.22))
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Day", item.day),
                                    y: .value("Actions", item.count)
                                )
                                .foregroundStyle(Color("AppAccent"))
                            }
                            .frame(height: 180)
                        }

                        if !categoryData.isEmpty {
                            chartCard(title: "Plants by Category") {
                                Chart(categoryData, id: \.name) { item in
                                    BarMark(
                                        x: .value("Count", item.count),
                                        y: .value("Category", item.name)
                                    )
                                    .foregroundStyle(Color("AppPrimary").gradient)
                                    .cornerRadius(6)
                                }
                                .frame(height: max(CGFloat(categoryData.count) * 36, 120))
                            }
                        }

                        chartCard(title: "Supplies Progress") {
                            let total = max(suppliesProgress.done + suppliesProgress.left, 1)
                            VStack(alignment: .leading, spacing: 12) {
                                ProgressView(value: Double(suppliesProgress.done), total: Double(total))
                                    .tint(Color("AppPrimary"))
                                HStack {
                                    Label("\(suppliesProgress.done) done", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(Color("AppAccent"))
                                    Spacer()
                                    Label("\(suppliesProgress.left) left", systemImage: "circle")
                                        .foregroundColor(Color("AppTextSecondary"))
                                }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                        }

                        milestones
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
        }
    }

    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(overviewData, id: \.label) { item in
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.label)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color("AppTextSecondary"))
                    Text("\(item.value)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color("AppSurface").opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)
                        .padding(12)
                }
            }
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Milestones")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppAccent"))

            milestoneRow("First Plant", unlocked: store.stats.plantsViewed >= 1)
            milestoneRow("Curious Grower", unlocked: store.stats.plantsViewed >= 5)
            milestoneRow("Supply Finisher", unlocked: store.stats.listsCompleted >= 1)
            milestoneRow("Steady Streak", unlocked: store.stats.streakDays >= 3)
            milestoneRow("Care Timer Pro", unlocked: store.stats.timersCompleted >= 3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func milestoneRow(_ title: String, unlocked: Bool) -> some View {
        HStack {
            Image(systemName: unlocked ? "checkmark.seal.fill" : "seal")
                .foregroundColor(unlocked ? Color("AppPrimary") : Color("AppTextSecondary"))
            Text(title)
                .foregroundColor(Color("AppTextPrimary"))
            Spacer()
            Text(unlocked ? "Unlocked" : "Locked")
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
        }
    }

    @ViewBuilder
    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppTextPrimary"))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
