import SpriteKit

/// Endless survival spawner. Difficulty ramps over time — spawn interval
/// shrinks from 4.0s at the start down to a floor of 0.9s after ~3 minutes.
final class SpawnDirector {

    let level: Int
    private(set) var spawned = 0
    private var nextSpawnAt: TimeInterval = 0
    private var startTime: TimeInterval = 0

    init(level: Int) {
        self.level = level
    }

    func tick(now: TimeInterval) -> Bool {
        if startTime == 0 { startTime = now }
        if now < nextSpawnAt { return false }
        let elapsed = now - startTime
        // 4.0 → 0.9 over 180 seconds, then floor.
        let interval = max(0.9, 4.0 - elapsed / 60.0)
        nextSpawnAt = now + interval + Double.random(in: -0.2...0.2)
        spawned += 1
        return true
    }
}
