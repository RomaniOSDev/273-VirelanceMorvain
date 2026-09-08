import SwiftUI

struct PlantDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let plant: Plant

    @State private var potCount: Int = 0
    @State private var notesDraft = ""
    @State private var showCareMode = false
    @State private var showEditor = false
    @State private var addedToList = false
    @State private var showPlanPicker = false

    private var livePlant: Plant {
        store.plants.first(where: { $0.id == plant.id }) ?? plant
    }

    private var scaledMaterials: [String] {
        MaterialScaler.scaleAll(livePlant.materials, from: livePlant.potCount, to: potCount)
    }

    var body: some View {
        ZStack {
            SafeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    actionButtons
                    potCountCard

                    section(title: "Materials") {
                        ForEach(scaledMaterials, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Color("AppPrimary"))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                Text(item)
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                        }
                    }

                    section(title: "Care Steps") {
                        ForEach(Array(livePlant.careSteps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color("AppPrimary"))
                                    .clipShape(Circle())
                                Text(step)
                                    .foregroundColor(Color("AppTextPrimary"))
                            }
                        }
                    }

                    notesSection
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showCareMode = true
                    } label: {
                        Label("Care Mode", systemImage: "drop.fill")
                    }
                    Button {
                        showPlanPicker = true
                    } label: {
                        Label("Add to Care Schedule", systemImage: "calendar")
                    }
                    if livePlant.isCustom {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Edit Plant", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("AppPrimary"))
                }
            }
        }
        .onAppear {
            if potCount == 0 {
                potCount = livePlant.potCount
            }
            notesDraft = livePlant.notes
            store.markPlantViewed(plant)
        }
        .fullScreenCover(isPresented: $showCareMode) {
            CareModeView(plant: livePlant)
                .environmentObject(store)
        }
        .sheet(isPresented: $showEditor) {
            PlantEditorView(plant: livePlant)
                .environmentObject(store)
        }
        .confirmationDialog("Add to Care Schedule", isPresented: $showPlanPicker, titleVisibility: .visible) {
            ForEach(CareScheduleCalendar.weekDates(from: CareScheduleCalendar.startOfWeek()), id: \.self) { date in
                let key = CareScheduleCalendar.dayKey(for: date)
                Button("\(CareScheduleCalendar.weekdayLabel(for: date)) · \(CareScheduleCalendar.shortDateLabel(for: date))") {
                    store.addPlantToCareSchedule(livePlant, dayKey: key)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            CategoryArtwork(category: livePlant.category, size: 88)
            VStack(alignment: .leading, spacing: 6) {
                Text(livePlant.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                Text("\(livePlant.category) · \(livePlant.difficulty.label) · \(livePlant.careMinutes) min")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            Button {
                store.toggleFavorite(livePlant)
            } label: {
                Image(systemName: livePlant.isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundColor(Color("AppAccent"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                showCareMode = true
            } label: {
                Label("Care Mode", systemImage: "drop.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                store.addMaterialsToSupplies(from: livePlant, potCount: potCount)
                addedToList = true
            } label: {
                Label(addedToList ? "Added" : "To List", systemImage: addedToList ? "checkmark.circle.fill" : "cart.badge.plus")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var potCountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pots")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppAccent"))
            HStack {
                Button {
                    if potCount > 1 {
                        potCount -= 1
                        HapticService.selection()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
                Text("\(potCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                    .frame(minWidth: 44)
                Button {
                    if potCount < 24 {
                        potCount += 1
                        HapticService.selection()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                Text("Pots \(livePlant.potCount)")
                    .font(.caption)
                    .foregroundColor(Color("AppTextSecondary"))
            }
        }
        .padding(14)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Notes")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppAccent"))
            TextEditor(text: $notesDraft)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .padding(10)
                .foregroundColor(Color("AppTextPrimary"))
                .background(Color("AppBackground").opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: notesDraft) { value in
                    store.updateNotes(for: livePlant, notes: value)
                }
            Text("Personal tweaks stay on this plant.")
                .font(.caption)
                .foregroundColor(Color("AppTextSecondary"))
        }
        .padding(14)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppAccent"))
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("AppSurface").opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
