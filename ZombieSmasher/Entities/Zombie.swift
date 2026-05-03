import SpriteKit

final class Zombie: SKSpriteNode {

    enum State { case walk, attack, hit, dead }

    private(set) var state: State = .walk
    var maxHealth: Int = 30
    var health: Int = 30
    var moveSpeed: CGFloat = 45
    weak var target: SKNode?

    private let walkFrames: [SKTexture]
    private let biteFrames: [SKTexture]
    var onDied: ((Zombie) -> Void)?
    var onBite: ((Zombie) -> Void)?

    private let meleeRange: CGFloat = 70
    private var lastBiteAt: TimeInterval = 0
    private let biteInterval: TimeInterval = 1.1

    init() {
        let frames = AssetCatalog.zombieWalkFrames()
        walkFrames = frames
        biteFrames = AssetCatalog.zombieAttackBiteFrames()
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 105, height: 125))
        anchorPoint = CGPoint(x: 0.5, y: 0.62)
        zPosition = 45
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 70, height: 120))
        body.categoryBitMask = PhysicsCategory.zombie
        body.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.arrow | PhysicsCategory.explosion | PhysicsCategory.grenade | PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.ground
        body.allowsRotation = false
        body.affectedByGravity = false
        body.friction = 0
        body.linearDamping = 0
        physicsBody = body
        startWalk()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func startWalk() {
        state = .walk
        removeAction(forKey: "anim")
        let anim = SKAction.animate(with: walkFrames, timePerFrame: 1.0/8.0)
        run(.repeatForever(anim), withKey: "anim")
    }

    private func startAttack() {
        state = .attack
        physicsBody?.velocity.dx = 0
        removeAction(forKey: "anim")
        guard !biteFrames.isEmpty else { return }
        let anim = SKAction.animate(with: biteFrames, timePerFrame: 1.0/10.0)
        run(.repeatForever(anim), withKey: "anim")
        run(AudioManager.sfx("ZombieSound"))
    }

    func update(dt: TimeInterval, currentTime: TimeInterval) {
        guard state != .dead, state != .hit, let target else { return }
        let dx = target.position.x - position.x
        let dir: CGFloat = dx >= 0 ? 1 : -1
        xScale = dir
        if abs(dx) < meleeRange {
            if state != .attack { startAttack() }
            physicsBody?.velocity.dx = 0
            if currentTime - lastBiteAt > biteInterval {
                lastBiteAt = currentTime
                onBite?(self)
            }
        } else {
            if state != .walk { startWalk() }
            physicsBody?.velocity.dx = dir * moveSpeed
        }
    }

    func takeDamage(_ amount: Int, kind: HitKind) {
        guard state != .dead else { return }
        health -= amount
        if health <= 0 {
            die(kind: kind)
            return
        }
        // Normal arrow doesn't interrupt walking — zombie keeps marching
        // toward the player. Fire arrow plays a dedicated burning-damage anim.
        if kind == .arrow { return }
        playHit(kind: kind)
    }

    private func playHit(kind: HitKind) {
        state = .hit
        physicsBody?.velocity = .zero
        // Reset the bite cooldown so the zombie can't immediately chomp the
        // player the instant the hit-flinch finishes.
        lastBiteAt = CACurrentMediaTime()
        removeAction(forKey: "anim")
        let frames: [SKTexture]
        switch kind {
        case .bullet, .melee: frames = AssetCatalog.zombieHitBulletFrames()
        case .arrow:          frames = AssetCatalog.zombieHitArrowFrames()
        case .fireArrow:      frames = AssetCatalog.zombieFireArrowHitFrames()
        case .grenade:        frames = AssetCatalog.zombieHitBulletFrames()
        }
        let anim = SKAction.animate(with: frames, timePerFrame: 1.0/10.0)
        run(.sequence([anim, .run { [weak self] in self?.startWalk() }]), withKey: "anim")
    }

    func die(kind: HitKind) {
        guard state != .dead else { return }
        state = .dead
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = 0
        physicsBody?.velocity = .zero
        physicsBody?.affectedByGravity = false
        removeAction(forKey: "anim")
        run(AudioManager.sfx("ZombieDyingSound"))
        let frames: [SKTexture]
        switch kind {
        case .grenade:   frames = AssetCatalog.zombieGrenadeDeathFrames()
        case .fireArrow: frames = AssetCatalog.zombieFireArrowDeathFrames()
        case .arrow:     frames = AssetCatalog.zombieArrowDeathFrames()
        case .bullet:    frames = AssetCatalog.zombieBulletDeathFrames()
        case .melee:     frames = AssetCatalog.zombieHitBulletFrames()
        }
        let anim = SKAction.animate(with: frames, timePerFrame: 1.0/8.0)
        // All deaths play the full sequence, freeze on the last frame as a
        // corpse, then fade out 10s later.
        zPosition = 30  // drop below living entities so new zombies walk in front
        run(.sequence([
            anim,
            .run { [weak self] in
                guard let self else { return }
                if let last = frames.last { self.texture = last }
                self.onDied?(self)
            },
            .wait(forDuration: 10.0),
            .fadeOut(withDuration: 0.6),
            .removeFromParent()
        ]))
    }
}

enum HitKind { case bullet, arrow, fireArrow, melee, grenade }
