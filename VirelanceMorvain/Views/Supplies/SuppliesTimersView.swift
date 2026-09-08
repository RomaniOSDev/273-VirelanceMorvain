import SwiftUI

struct SuppliesTimersView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var segment = 0
    @State private var newItemName = ""
    @State private var newItemCategory: SupplyCategory = .soil
    @State private var newTimerTitle = ""
    @State private var newTimerMinutes = 10

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                VStack(spacing: 12) {
                    Picker("Section", selection: $segment) {
                        Text("Garden Supplies").tag(0)
                        Text("Care Timers").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .onChange(of: segment) { _ in
                        HapticService.selection()
                    }

                    if segment == 0 {
                        suppliesContent
                    } else {
                        timersContent
                    }
                }
            }
            .navigationTitle(segment == 0 ? "Garden Supplies" : "Care Timers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
        }
    }

    private var suppliesContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Add item", text: $newItemName)
                    .textFieldStyle(AppTextFieldStyle())
                Picker("Category", selection: $newItemCategory) {
                    ForEach(SupplyCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .labelsHidden()
                .tint(Color("AppTextPrimary"))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color("AppSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Button {
                    store.addSupplyItem(name: newItemName, category: newItemCategory)
                    newItemName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            .padding(.horizontal, 16)

            List {
                ForEach(SupplyCategory.allCases) { category in
                    let items = store.supplyItems.filter { $0.category == category }
                    if !items.isEmpty {
                        Section(category.rawValue) {
                            ForEach(items) { item in
                                HStack {
                                    Button {
                                        store.toggleSupplyItem(item)
                                    } label: {
                                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(item.isCompleted ? Color("AppAccent") : Color("AppTextSecondary"))
                                    }
                                    .buttonStyle(.plain)

                                    Text(item.name)
                                        .strikethrough(item.isCompleted)
                                        .foregroundColor(item.isCompleted ? Color("AppTextSecondary") : Color("AppTextPrimary"))

                                    Spacer()

                                    Button {
                                        store.deleteSupplyItem(item)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundColor(Color("AppPrimary"))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .listRowBackground(Color("AppSurface").opacity(0.85))
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
    }

    private var timersContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                TextField("Timer name", text: $newTimerTitle)
                    .textFieldStyle(AppTextFieldStyle())
                Stepper("\(newTimerMinutes)m", value: $newTimerMinutes, in: 1...180)
                    .frame(width: 120)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .foregroundColor(Color("AppTextPrimary"))
                Button {
                    store.addTimer(title: newTimerTitle, minutes: newTimerMinutes)
                    newTimerTitle = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
            }
            .padding(.horizontal, 16)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                List {
                    ForEach(store.timers) { timer in
                        TimerRow(
                            timer: displayTimer(timer, at: context.date),
                            onStart: { store.startTimer(timer) },
                            onPause: { store.pauseTimer(timer) },
                            onDelete: { store.deleteTimer(timer) }
                        )
                        .listRowBackground(Color("AppSurface").opacity(0.85))
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
                .onChange(of: context.date) { date in
                    finishCompletedTimers(at: date)
                }
            }
        }
    }

    private func displayTimer(_ timer: CareTimer, at date: Date) -> CareTimer {
        var copy = timer
        copy.syncRemaining(now: date)
        return copy
    }

    private func finishCompletedTimers(at date: Date) {
        var completed = 0
        for index in store.timers.indices {
            guard store.timers[index].isRunning, let end = store.timers[index].endDate else { continue }
            if end <= date {
                store.timers[index].remainingSeconds = 0
                store.timers[index].isRunning = false
                store.timers[index].endDate = nil
                completed += 1
            }
        }
        if completed > 0 {
            for _ in 0..<completed {
                store.recordTimerCompleted()
            }
            HapticService.success()
            SoundService.complete()
        }
    }
}

private struct TimerRow: View {
    let timer: CareTimer
    let onStart: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timer.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                Text(formatTime(timer.remainingSeconds))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppAccent"))
                    .monospacedDigit()
            }

            Spacer()

            if timer.isRunning {
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .foregroundColor(Color("AppTextPrimary"))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: onStart) {
                    Image(systemName: "play.fill")
                        .foregroundColor(Color("AppPrimary"))
                }
                .buttonStyle(.plain)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(Color("AppTextSecondary"))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ total: Int) -> String {
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
