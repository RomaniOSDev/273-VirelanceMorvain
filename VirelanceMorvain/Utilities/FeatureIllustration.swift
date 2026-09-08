import SwiftUI

struct FeatureIllustration: View {
    let systemName: String
    var accent: Color = Color("AppPrimary")
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.18))
                .frame(width: size * 1.7, height: size * 1.7)

            Circle()
                .stroke(accent.opacity(0.35), lineWidth: 2)
                .frame(width: size * 1.35, height: size * 1.35)

            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(accent)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(height: size * 1.8)
        .accessibilityHidden(true)
    }
}

struct CategoryArtwork: View {
    let category: String
    var size: CGFloat = 56

    private var icon: String {
        switch category.lowercased() {
        case "tropical": return "leaf.fill"
        case "succulent": return "circle.hexagongrid.fill"
        case "fern": return "laurel.leading"
        case "flowering": return "sparkles"
        case "trailing": return "arrow.triangle.swap"
        case "low light": return "moon.fill"
        default: return "leaf.fill"
        }
    }

    private var tint: Color {
        switch category.lowercased() {
        case "tropical": return Color(red: 0.28, green: 0.72, blue: 0.48)
        case "succulent": return Color(red: 0.45, green: 0.70, blue: 0.40)
        case "fern": return Color(red: 0.22, green: 0.55, blue: 0.38)
        case "flowering": return Color(red: 0.85, green: 0.45, blue: 0.55)
        case "trailing": return Color(red: 0.35, green: 0.65, blue: 0.55)
        case "low light": return Color(red: 0.45, green: 0.55, blue: 0.75)
        default: return Color("AppAccent")
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(tint.opacity(0.22))
            Image(systemName: icon)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .foregroundColor(Color("AppTextPrimary"))
            .background(Color("AppSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color("AppTextSecondary").opacity(0.4), lineWidth: 1)
            )
    }
}
