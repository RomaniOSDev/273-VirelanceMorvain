import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var weekStart = MealPlanCalendar.startOfWeek()
    @State private var selectedDayKey = MealPlanCalendar.dayKey(for: Date())
    @State private var showRecipePicker = false

    private var weekDates: [Date] {
        MealPlanCalendar.weekDates(from: weekStart)
    }

    private var selectedRecipes: [Recipe] {
        store.mealPlan.recipeIDs(for: selectedDayKey).compactMap { store.recipe(with: $0) }
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
                                let key = MealPlanCalendar.dayKey(for: date)
                                let count = store.mealPlan.recipeIDs(for: key).count
                                Button {
                                    selectedDayKey = key
                                    HapticService.selection()
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(MealPlanCalendar.weekdayLabel(for: date))
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        Text(MealPlanCalendar.shortDateLabel(for: date))
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

                    if selectedRecipes.isEmpty {
                        VStack(spacing: 12) {
                            FeatureIllustration(systemName: "calendar", accent: Color("AppPrimary"), size: 64)
                            Text("No meals planned")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("AppTextPrimary"))
                            Text("Add a recipe for this day.")
                                .foregroundColor(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(selectedRecipes) { recipe in
                                NavigationLink(value: recipe) {
                                    HStack(spacing: 12) {
                                        CategoryArtwork(category: recipe.category, size: 48)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.title)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Color("AppTextPrimary"))
                                            Text("\(recipe.cookTimeMinutes) min · \(recipe.difficulty.label)")
                                                .font(.caption)
                                                .foregroundColor(Color("AppTextSecondary"))
                                        }
                                    }
                                }
                                .listRowBackground(Color("AppSurface").opacity(0.85))
                            }
                            .onDelete { offsets in
                                let ids = selectedRecipes.map(\.id)
                                for index in offsets {
                                    store.removeRecipeFromMealPlan(ids[index], dayKey: selectedDayKey)
                                }
                            }
                            .onMove { from, to in
                                store.moveMealPlanRecipe(dayKey: selectedDayKey, fromOffsets: from, toOffset: to)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Meal Plan")
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
                        showRecipePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AppPrimary"))
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipePickerSheet(dayKey: selectedDayKey)
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
            Text("Week of \(MealPlanCalendar.shortDateLabel(for: weekStart))")
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

private struct RecipePickerSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    let dayKey: String

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()
                List(store.recipes) { recipe in
                    Button {
                        store.addRecipeToMealPlan(recipe, dayKey: dayKey)
                        dismiss()
                    } label: {
                        HStack {
                            CategoryArtwork(category: recipe.category, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.title)
                                    .foregroundColor(Color("AppTextPrimary"))
                                Text(recipe.category)
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
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
