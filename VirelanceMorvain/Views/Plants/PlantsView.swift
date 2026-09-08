import SwiftUI

struct PlantsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedCategory = "All"
    @State private var selectedDifficulty: CareDifficulty? = nil
    @State private var maxCareMinutes = 60
    @State private var showEditor = false
    @State private var showFilters = false

    private var categories: [String] {
        ["All"] + Array(Set(store.plants.map(\.category))).sorted()
    }

    private var filtered: [Plant] {
        store.plants.filter { plant in
            let categoryMatch = selectedCategory == "All" || plant.category == selectedCategory
            let favoriteMatch = !showFavoritesOnly || plant.isFavorite
            let difficultyMatch = selectedDifficulty == nil || plant.difficulty == selectedDifficulty
            let timeMatch = plant.careMinutes <= maxCareMinutes
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatch = query.isEmpty
                || plant.title.localizedCaseInsensitiveContains(query)
                || plant.materials.contains { $0.localizedCaseInsensitiveContains(query) }
                || plant.category.localizedCaseInsensitiveContains(query)
            return categoryMatch && favoriteMatch && difficultyMatch && timeMatch && searchMatch
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                VStack(spacing: 0) {
                    header

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("AppTextSecondary"))
                        TextField("Search plants or materials", text: $searchText)
                            .foregroundColor(Color("AppTextPrimary"))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    .padding(12)
                    .background(Color("AppSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories, id: \.self) { category in
                                chip(category, selected: selectedCategory == category) {
                                    selectedCategory = category
                                    HapticService.selection()
                                    SoundService.tap()
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    if showFilters {
                        filtersPanel
                    }

                    HStack {
                        Toggle("Favorites", isOn: $showFavoritesOnly)
                            .foregroundColor(Color("AppTextPrimary"))
                            .tint(Color("AppPrimary"))
                        Spacer()
                        Button {
                            withAnimation { showFilters.toggle() }
                        } label: {
                            Label("Filters", systemImage: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("AppPrimary"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    List {
                        ForEach(filtered) { plant in
                            NavigationLink(value: plant) {
                                PlantRow(plant: plant) {
                                    store.toggleFavorite(plant)
                                }
                            }
                            .listRowBackground(Color("AppSurface").opacity(0.85))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if plant.isCustom {
                                    Button(role: .destructive) {
                                        store.deletePlant(plant)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Plant.self) { plant in
                PlantDetailView(plant: plant)
            }
            .sheet(isPresented: $showEditor) {
                PlantEditorView(plant: nil)
                    .environmentObject(store)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image("banner")
                .resizable()
                .scaledToFill()
                .frame(height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color("AppPrimary").opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)

            HStack(spacing: 14) {
                Image("card_art")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Atelier")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("AppAccent"))
                    Text("Living Collection")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                }
                Spacer()
                Button {
                    showEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
                .accessibilityLabel("Add plant")
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var filtersPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppTextSecondary"))
            HStack(spacing: 8) {
                chip("Any", selected: selectedDifficulty == nil) {
                    selectedDifficulty = nil
                }
                ForEach(CareDifficulty.allCases) { level in
                    chip(level.label, selected: selectedDifficulty == level) {
                        selectedDifficulty = level
                    }
                }
            }

            HStack {
                Text("Max time: \(maxCareMinutes) min")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Color("AppTextSecondary"))
                Spacer()
            }
            Slider(value: Binding(
                get: { Double(maxCareMinutes) },
                set: { maxCareMinutes = Int($0) }
            ), in: 10...90, step: 5)
            .tint(Color("AppPrimary"))
        }
        .padding(14)
        .background(Color("AppSurface").opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(selected ? .white : Color("AppTextSecondary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color("AppPrimary") : Color("AppSurface"))
                .clipShape(Capsule())
        }
    }
}

private struct PlantRow: View {
    let plant: Plant
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CategoryArtwork(category: plant.category, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(plant.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("AppTextPrimary"))
                    if plant.isCustom {
                        Text("Yours")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(Color("AppPrimary"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color("AppPrimary").opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text("\(plant.category) · \(plant.difficulty.label) · \(plant.careMinutes) min")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Color("AppTextSecondary"))
            }

            Spacer()

            Button(action: onFavorite) {
                Image(systemName: plant.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(Color("AppAccent"))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
