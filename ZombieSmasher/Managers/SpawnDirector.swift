import SpriteKit

final class SpawnDirector {

    let level: Int
    let zombieGoal: Int
    private(set) var spawned = 0
    private var nextSpawnAt: TimeInterval = 0
    private let interval: TimeInterval

    init(level: Int) {
        self.level = level
        // Goals scale with level
        switch level {
        case 1: zombieGoal = 8;  interval = 5.0
        case 2: zombieGoal = 12; interval = 4.5
        case 3: zombieGoal = 16; interval = 4.0
        case 4: zombieGoal = 20; interval = 3.5
        case 5: zombieGoal = 28; interval = 3.0
        default: zombieGoal = 10; interval = 4.5
        }
    }

    var hasMoreToSpawn: Bool { spawned < zombieGoal }

    func tick(now: TimeInterval) -> Bool {
        guard hasMoreToSpawn else { return false }
        if now >= nextSpawnAt {
            nextSpawnAt = now + interval + Double.random(in: -0.3...0.3)
            spawned += 1
            return true
        }
        return false
    }
}
