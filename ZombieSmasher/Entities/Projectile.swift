import SpriteKit

final class Projectile: SKSpriteNode {

    let weapon: WeaponKind
    let isFire: Bool

    init(weapon: WeaponKind, direction: CGFloat, isFire: Bool = false) {
        self.weapon = weapon
        self.isFire = isFire

        let frames: [SKTexture]
        let displaySize: CGSize
        switch weapon {
        case .handgun:
            frames = AssetCatalog.bulletHandgunFrames()
            displaySize = CGSize(width: 36, height: 14)
        case .rifle:
            frames = AssetCatalog.bulletRifleFrames()
            displaySize = CGSize(width: 44, height: 14)
        case .bow:
            frames = isFire ? AssetCatalog.arrowFireFrames() : AssetCatalog.arrowNormalFrames()
            displaySize = CGSize(width: 64, height: 16)
        default:
            frames = []
            displaySize = CGSize(width: 8, height: 8)
        }
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: frames.isEmpty ? .red : .clear, size: displaySize)
        zPosition = 60
        xScale = direction >= 0 ? 1 : -1
        if !frames.isEmpty {
            run(.repeatForever(.animate(with: frames, timePerFrame: 1.0/14.0)))
        }

        let body = SKPhysicsBody(rectangleOf: displaySize)
        body.categoryBitMask = weapon == .bow ? PhysicsCategory.arrow : PhysicsCategory.bullet
        body.contactTestBitMask = PhysicsCategory.zombie
        body.collisionBitMask = 0
        body.affectedByGravity = false
        body.usesPreciseCollisionDetection = true
        body.velocity = CGVector(dx: weapon.projectileSpeed * direction, dy: 0)
        physicsBody = body
        run(.sequence([.wait(forDuration: 1.4), .removeFromParent()]))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}

final class Grenade: SKSpriteNode {

    private let direction: CGFloat
    private let onExplode: (CGPoint) -> Void

    init(direction: CGFloat, onExplode: @escaping (CGPoint) -> Void) {
        self.direction = direction
        self.onExplode = onExplode
        let tex = SKTexture(imageNamed: AssetCatalog.grenadeImage)
        super.init(texture: tex, color: .clear, size: CGSize(width: 32, height: 32))
        zPosition = 60
        run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 0.6)))
        let body = SKPhysicsBody(circleOfRadius: 9)
        body.categoryBitMask = PhysicsCategory.grenade
        body.contactTestBitMask = PhysicsCategory.zombie
        body.collisionBitMask = PhysicsCategory.ground
        body.affectedByGravity = true
        body.restitution = 0.2
        body.velocity = CGVector(dx: 380 * direction, dy: 520)
        physicsBody = body
        run(.sequence([
            .wait(forDuration: 1.1),
            .run { [weak self] in
                guard let self else { return }
                self.onExplode(self.position)
                self.removeFromParent()
            }
        ]))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}

final class Explosion: SKSpriteNode {

    init() {
        let frames = AssetCatalog.explosionFrames()
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 240, height: 240))
        zPosition = 70
        let body = SKPhysicsBody(circleOfRadius: 110)
        body.categoryBitMask = PhysicsCategory.explosion
        body.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.player
        body.collisionBitMask = 0
        body.affectedByGravity = false
        body.isDynamic = false
        physicsBody = body
        run(AudioManager.sfx("GrenadeExplosionSound"))
        run(.sequence([
            .animate(with: frames, timePerFrame: 1.0/14.0),
            .removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError() }
}
