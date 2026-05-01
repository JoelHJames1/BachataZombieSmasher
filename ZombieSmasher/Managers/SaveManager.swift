import Foundation

enum SaveManager {
    private static let unlockedKey = "highestUnlockedLevel"
    private static let killsKey    = "totalKills"
    private static let muteKey     = "muteAudio"

    static var highestUnlockedLevel: Int {
        get { max(1, UserDefaults.standard.integer(forKey: unlockedKey)) }
        set { UserDefaults.standard.set(newValue, forKey: unlockedKey) }
    }

    static var totalKills: Int {
        get { UserDefaults.standard.integer(forKey: killsKey) }
        set { UserDefaults.standard.set(newValue, forKey: killsKey) }
    }

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: muteKey) }
        set { UserDefaults.standard.set(newValue, forKey: muteKey) }
    }

    static func unlock(level: Int) {
        if level > highestUnlockedLevel { highestUnlockedLevel = level }
    }
}
