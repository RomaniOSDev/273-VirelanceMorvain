import SwiftUI

struct CarePlanView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var weekStart = CareScheduleCalendar.startOfWeek()
    @State private var selectedDayKey = CareScheduleCalendar.dayKey(for: Date())
    @State private var showPlantPicker = false

    private var weekDates: [Date] {
        CareScheduleCalendar.weekDates(from: weekStart)
    }

    private var selectedPlants: [Plant] {
        store.careSchedule.plantIDs(for: selectedDayKey).compactMap { store.plant(with: $0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                VStack(spacing: 12) {
                    weekHeader

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(weekDates, id: \.self) { date in
                                let key = CareScheduleCalendar.dayKey(for: date)
                                let count = store.careSchedule.plantIDs(for: key).count
                                Button {
                                    selectedDayKey = key
                                    HapticService.selection()
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(CareScheduleCalendar.weekdayLabel(for: date))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        Text(CareScheduleCalendar.shortDateLabel(for: date))
                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                        Text("\(count)")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(selectedDayKey == key ? .white : Color("AppTextPrimary"))
                                    .frame(width: 72, height: 84)
                                    .background(selectedDayKey == key ? Color("AppPrimary") : Color("AppSurface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if selectedPlants.isEmpty {
                        VStack(spacing: 12) {
                            FeatureIllustration(systemName: "calendar", accent: Color("AppPrimary"), size: 64)
                            Text("No meals planned")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("AppTextPrimary"))
                            Text("Add a plant for this day.")
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(selectedPlants) { plant in
                                NavigationLink(value: plant) {
                                    HStack(spacing: 12) {
                                        CategoryArtwork(category: plant.category, size: 48)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(plant.title)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color("AppTextPrimary"))
                                            Text("\(plant.careMinutes) min · \(plant.difficulty.label)")
                                                .font(.caption)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                    }
                                }
                                .listRowBackground(Color("AppSurface").opacity(0.85))
                            }
                            .onDelete { offsets in
                                let ids = selectedPlants.map(\.id)
                                for index in offsets {
                                    store.removePlantFromCareSchedule(ids[index], dayKey: selectedDayKey)
                                }
                            }
                            .onMove { from, to in
                                store.moveCareSchedulePlant(dayKey: selectedDayKey, fromOffsets: from, toOffset: to)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Care Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(Color("AppPrimary"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showPlantPicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                    }
                }
            }
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
            .sheet(isPresented: $showPlantPicker) {
                PlantPickerSheet(dayKey: selectedDayKey)
                    .environmentObject(store)
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                weekStart = Calendar.current.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .foregroundColor(Color("AppPrimary"))
            }
            Spacer()
            Text("Week of \(CareScheduleCalendar.shortDateLabel(for: weekStart))")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppTextPrimary"))
            Spacer()
            Button {
                weekStart = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(Color("AppPrimary"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

private struct PlantPickerSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let dayKey: String

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()
                List(store.plants) { plant in
                    Button {
                        store.addPlantToCareSchedule(plant, dayKey: dayKey)
                        dismiss()
                    } label: {
                        HStack {
                            CategoryArtwork(category: plant.category, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.title)
                                    .foregroundColor(Color("AppTextPrimary"))
                                Text(plant.category)
                                    .font(.caption)
                                    .foregroundColor(Color("AppTextSecondary"))
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color("AppPrimary"))
                        }
                    }
                    .listRowBackground(Color("AppSurface").opacity(0.9))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
