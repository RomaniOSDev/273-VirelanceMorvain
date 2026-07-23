import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife")
                }

            MealPlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }

            ShoppingTimersView()
                .tabItem {
                    Label("Shop", systemImage: "cart.fill")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(Color("AppPrimary"))
        .onAppear {
            store.recordActivityDay()
            configureTabBar()
        }
        .onChange(of: colorScheme) { _ in
            configureTabBar()
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "AppSurface")
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
