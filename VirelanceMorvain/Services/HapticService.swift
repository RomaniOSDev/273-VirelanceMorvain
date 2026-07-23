import UIKit

enum HapticService {
    static func light() {
        guard AppPreferences.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        guard AppPreferences.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func heavy() {
        guard AppPreferences.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func selection() {
        guard AppPreferences.hapticsEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        guard AppPreferences.hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
