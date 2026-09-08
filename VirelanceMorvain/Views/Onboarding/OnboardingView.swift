import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var page = 0

    private let pages: [(title: String, subtitle: String, icon: String, accent: Color)] = [
        (
            "Meet Your Plants",
            "Build a living collection with care notes for every specimen.",
            "leaf.fill",
            Color("AppPrimary")
        ),
        (
            "Schedule Care",
            "Plan watering days, gather supplies, and run care timers.",
            "drop.fill",
            Color(red: 0.35, green: 0.72, blue: 0.95)
        ),
        (
            "Watch Them Thrive",
            "Log care streaks, unlock grower milestones, and track atelier stats.",
            "drop.fill",
            Color(red: 1.0, green: 0.62, blue: 0.22)
        )
    ]

    var body: some View {
        ZStack {
            SafeBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer()
                            FeatureIllustration(
                                systemName: pages[index].icon,
                                accent: pages[index].accent,
                                size: 96
                            )

                            Text(pages[index].title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Color("AppTextPrimary"))
                                .multilineTextAlignment(.center)

                            Text(pages[index].subtitle)
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(Color("AppTextSecondary"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)

                            Spacer()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    HapticService.medium()
                    SoundService.tap()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Enter Atelier")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AppPrimary"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}
