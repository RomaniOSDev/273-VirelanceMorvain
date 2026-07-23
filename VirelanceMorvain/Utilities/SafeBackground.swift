import SwiftUI

struct SafeBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color("AppBackground")
                Image("bg_main")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(colorScheme == .dark ? 0.28 : 0.08)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func withSafeBackground() -> some View {
        background(SafeBackground())
    }
}
