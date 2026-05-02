import Foundation

enum SaveManager {
    private static let unlockedKey    = "highestUnlockedLevel"
    private static let killsKey       = "totalKills"
    private static let muteKey        = "muteAudio"
    private static let bestTimeKey    = "bestSurvivalTime"
    private static let bestKillsKey   = "bestSurvivalKills"

    static var highestUnlockedLevel: Int {
        get { max(1, UserDefaults.standard.integer(forKey: unlockedKey)) }
        set { UserDefaults.standard.set(newValue, forKey: unlockedKey) }
    }

    static func unlock(level: Int) {
        if level > highestUnlockedLevel { highestUnlockedLevel = level }
    }

    static var totalKills: Int {
        get { UserDefaults.standard.integer(forKey: killsKey) }
        set { UserDefaults.standard.set(newValue, forKey: killsKey) }
    }

    static var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: muteKey) }
        set { UserDefaults.standard.set(newValue, forKey: muteKey) }
    }

    static var bestSurvivalTime: TimeInterval {
        get { UserDefaults.standard.double(forKey: bestTimeKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestTimeKey) }
    }

    static var bestSurvivalKills: Int {
        get { UserDefaults.standard.integer(forKey: bestKillsKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestKillsKey) }
    }

    static func recordSurvival(time: TimeInterval, kills: Int) {
        if time > bestSurvivalTime { bestSurvivalTime = time }
        if kills > bestSurvivalKills { bestSurvivalKills = kills }
        totalKills += kills
    }
}
