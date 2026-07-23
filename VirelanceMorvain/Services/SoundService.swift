import AudioToolbox

enum SoundService {
    static func tap() {
        guard AppPreferences.soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }

    static func success() {
        guard AppPreferences.soundEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    static func complete() {
        guard AppPreferences.soundEnabled else { return }
        AudioServicesPlaySystemSound(1001)
    }
}
