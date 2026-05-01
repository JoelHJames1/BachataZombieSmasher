import SpriteKit

final class Zombie: SKSpriteNode {

    enum State { case walk, hit, dead }

    private(set) var state: State = .walk
    var maxHealth: Int = 30
    var health: Int = 30
    var moveSpeed: CGFloat = 45
    weak var target: SKNode?

    private let walkFrames: [SKTexture]
    var onDied: ((Zombie) -> Void)?

    init() {
        let frames = AssetCatalog.zombieWalkFrames()
        walkFrames = frames
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 105, height: 125))
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        zPosition = 45
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 70, height: 120))
        body.categoryBitMask = PhysicsCategory.zombie
        body.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.arrow | PhysicsCategory.explosion | PhysicsCategory.player
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
        let anim = SKAction.animate(with: walkFrames, timePerFrame: 1.0/8.0)
        run(.repeatForever(anim), withKey: "anim")
    }

    func update(dt: TimeInterval) {
        guard state == .walk, let target else { return }
        let dx = target.position.x - position.x
        let dir: CGFloat = dx >= 0 ? 1 : -1
        xScale = dir
        physicsBody?.velocity.dx = dir * moveSpeed
    }

    func takeDamage(_ amount: Int, kind: HitKind) {
        guard state != .dead else { return }
        health -= amount
        if health <= 0 {
            die(kind: kind)
        } else {
            playHit(kind: kind)
        }
    }

    private func playHit(kind: HitKind) {
        state = .hit
        physicsBody?.velocity.dx = 0
        removeAction(forKey: "anim")
        let frames: [SKTexture]
        switch kind {
        case .bullet, .melee: frames = AssetCatalog.zombieHitBulletFrames()
        case .arrow:          frames = AssetCatalog.zombieHitArrowFrames()
        case .grenade:        frames = AssetCatalog.zombieHitBulletFrames()
        }
        let anim = SKAction.animate(with: frames, timePerFrame: 1.0/12.0)
        run(.sequence([anim, .run { [weak self] in self?.startWalk() }]), withKey: "anim")
    }

    func die(kind: HitKind) {
        guard state != .dead else { return }
        state = .dead
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = 0
        physicsBody?.velocity = .zero
        removeAction(forKey: "anim")
        let frames: [SKTexture]
        switch kind {
        case .grenade: frames = AssetCatalog.zombieGrenadeDeathFrames()
        case .arrow:   frames = AssetCatalog.zombieHitArrowFrames()
        case .bullet, .melee: frames = AssetCatalog.zombieHitBulletFrames()
        }
        let anim = SKAction.animate(with: frames, timePerFrame: 1.0/10.0)
        run(.sequence([anim, .wait(forDuration: 0.6), .fadeOut(withDuration: 0.4), .removeFromParent(), .run { [weak self] in
            guard let self else { return }
            self.onDied?(self)
        }]))
    }
}

enum HitKind { case bullet, arrow, melee, grenade }
