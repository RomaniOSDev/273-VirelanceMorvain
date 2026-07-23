import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("pref_app_theme") private var themeRaw = AppTheme.dark.rawValue

    private var preferredScheme: ColorScheme? {
        switch AppTheme(rawValue: themeRaw) ?? .dark {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(store)
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(store)
            }
        }
        .preferredColorScheme(preferredScheme)
    }
}
