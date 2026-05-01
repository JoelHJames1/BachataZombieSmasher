import SpriteKit

final class Projectile: SKSpriteNode {

    let weapon: WeaponKind

    init(weapon: WeaponKind, direction: CGFloat) {
        self.weapon = weapon
        let size: CGSize
        let color: UIColor
        switch weapon {
        case .handgun: size = CGSize(width: 14, height: 5);  color = .systemYellow
        case .rifle:   size = CGSize(width: 18, height: 4);  color = .systemOrange
        case .bow:     size = CGSize(width: 32, height: 4);  color = .brown
        default:       size = CGSize(width: 8, height: 8);   color = .red
        }
        super.init(texture: nil, color: color, size: size)
        zPosition = 60
        xScale = direction >= 0 ? 1 : -1
        let body = SKPhysicsBody(rectangleOf: size)
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
        super.init(texture: nil, color: .darkGray, size: CGSize(width: 18, height: 18))
        zPosition = 60
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
        super.init(texture: tex, color: .clear, size: CGSize(width: 220, height: 220))
        zPosition = 70
        let body = SKPhysicsBody(circleOfRadius: 100)
        body.categoryBitMask = PhysicsCategory.explosion
        body.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.player
        body.collisionBitMask = 0
        body.affectedByGravity = false
        body.isDynamic = false
        physicsBody = body
        run(.sequence([
            .animate(with: frames, timePerFrame: 1.0/14.0),
            .removeFromParent()
        ]))
    }

    required init?(coder: NSCoder) { fatalError() }
}
