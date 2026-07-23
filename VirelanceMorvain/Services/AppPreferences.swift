import Foundation

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AppPreferences {
    private static let soundKey = "pref_sound_enabled"
    private static let hapticsKey = "pref_haptics_enabled"
    private static let themeKey = "pref_app_theme"

    static var soundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: soundKey) }
    }

    static var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hapticsKey) }
    }

    static var theme: AppTheme {
        get {
            guard let raw = UserDefaults.standard.string(forKey: themeKey),
                  let theme = AppTheme(rawValue: raw) else { return .dark }
            return theme
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: themeKey) }
    }
}
