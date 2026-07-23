import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    let recipe: Recipe

    @State private var servings: Int = 0
    @State private var notesDraft = ""
    @State private var showCookMode = false
    @State private var showEditor = false
    @State private var addedToList = false
    @State private var showPlanPicker = false

    private var liveRecipe: Recipe {
        store.recipes.first(where: { $0.id == recipe.id }) ?? recipe
    }

    private var scaledIngredients: [String] {
        IngredientScaler.scaleAll(liveRecipe.ingredients, from: liveRecipe.servings, to: servings)
    }

    var body: some View {
        ZStack {
            SafeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    actionButtons
                    servingsCard

                    section(title: "Ingredients") {
                        ForEach(scaledIngredients, id: \.self) { item in
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

                    section(title: "Steps") {
                        ForEach(Array(liveRecipe.steps.enumerated()), id: \.offset) { index, step in
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
                        showCookMode = true
                    } label: {
                        Label("Cook Mode", systemImage: "flame.fill")
                    }
                    Button {
                        showPlanPicker = true
                    } label: {
                        Label("Add to Meal Plan", systemImage: "calendar")
                    }
                    if liveRecipe.isCustom {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Edit Recipe", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("AppPrimary"))
                }
            }
        }
        .onAppear {
            if servings == 0 {
                servings = liveRecipe.servings
            }
            notesDraft = liveRecipe.notes
            store.markRecipeViewed(recipe)
        }
        .fullScreenCover(isPresented: $showCookMode) {
            CookModeView(recipe: liveRecipe)
                .environmentObject(store)
        }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(recipe: liveRecipe)
                .environmentObject(store)
        }
        .confirmationDialog("Add to Meal Plan", isPresented: $showPlanPicker, titleVisibility: .visible) {
            ForEach(MealPlanCalendar.weekDates(from: MealPlanCalendar.startOfWeek()), id: \.self) { date in
                let key = MealPlanCalendar.dayKey(for: date)
                Button("\(MealPlanCalendar.weekdayLabel(for: date)) · \(MealPlanCalendar.shortDateLabel(for: date))") {
                    store.addRecipeToMealPlan(liveRecipe, dayKey: key)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            CategoryArtwork(category: liveRecipe.category, size: 88)
            VStack(alignment: .leading, spacing: 6) {
                Text(liveRecipe.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                Text("\(liveRecipe.category) · \(liveRecipe.difficulty.label) · \(liveRecipe.cookTimeMinutes) min")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color("AppTextSecondary"))
            }
            Spacer()
            Button {
                store.toggleFavorite(liveRecipe)
            } label: {
                Image(systemName: liveRecipe.isFavorite ? "heart.fill" : "heart")
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
                showCookMode = true
            } label: {
                Label("Cook Mode", systemImage: "flame.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AppPrimary"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button {
                store.addIngredientsToShopping(from: liveRecipe, servings: servings)
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

    private var servingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Servings")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color("AppAccent"))
            HStack {
                Button {
                    if servings > 1 {
                        servings -= 1
                        HapticService.selection()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
                Text("\(servings)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color("AppTextPrimary"))
                    .frame(minWidth: 44)
                Button {
                    if servings < 24 {
                        servings += 1
                        HapticService.selection()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("AppPrimary"))
                }
                Spacer()
                Text("Base \(liveRecipe.servings)")
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
                    store.updateNotes(for: liveRecipe, notes: value)
                }
            Text("Personal tweaks stay on this recipe.")
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
