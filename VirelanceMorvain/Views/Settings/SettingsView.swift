import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.colorScheme) private var colorScheme
    @State private var showResetConfirm = false
    @State private var soundEnabled = AppPreferences.soundEnabled
    @State private var hapticsEnabled = AppPreferences.hapticsEnabled
    @AppStorage("pref_app_theme") private var themeRaw = AppTheme.dark.rawValue

    var body: some View {
        NavigationStack {
            ZStack {
                SafeBackground()

                List {
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.label).tag(theme.rawValue)
                            }
                        }
                        .foregroundColor(Color("AppTextPrimary"))
                        .listRowBackground(Color("AppSurface").opacity(0.9))
                        .onChange(of: themeRaw) { _ in
                            HapticService.selection()
                        }
                    }

                    Section("Feedback") {
                        Toggle("Sound", isOn: $soundEnabled)
                            .foregroundColor(Color("AppTextPrimary"))
                            .tint(Color("AppPrimary"))
                            .listRowBackground(Color("AppSurface").opacity(0.9))
                            .onChange(of: soundEnabled) { value in
                                AppPreferences.soundEnabled = value
                                if value { SoundService.tap() }
                            }

                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                            .foregroundColor(Color("AppTextPrimary"))
                            .tint(Color("AppPrimary"))
                            .listRowBackground(Color("AppSurface").opacity(0.9))
                            .onChange(of: hapticsEnabled) { value in
                                AppPreferences.hapticsEnabled = value
                                if value { HapticService.selection() }
                            }
                    }

                    Section {
                        Button("Rate Us") {
                            requestReview()
                        }
                        .foregroundColor(Color("AppTextPrimary"))
                        .listRowBackground(Color("AppSurface").opacity(0.9))

                        Link("Privacy", destination: AppLinks.privacy.url)
                            .foregroundColor(Color("AppTextPrimary"))
                            .listRowBackground(Color("AppSurface").opacity(0.9))

                        Link("Terms", destination: AppLinks.terms.url)
                            .foregroundColor(Color("AppTextPrimary"))
                            .listRowBackground(Color("AppSurface").opacity(0.9))
                    }

                    Section {
                        Button("Reset", role: .destructive) {
                            showResetConfirm = true
                        }
                        .listRowBackground(Color("AppSurface").opacity(0.9))
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .alert("Reset all data?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                }
            } message: {
                Text("This clears recipes, shopping lists, timers, meal plan, and achievements.")
            }
        }
    }

    private func requestReview() {
        HapticService.success()
        SoundService.success()
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
