import SpriteKit

enum AmmoKind { case rifle, arrow, fireArrow }

final class Pickup: SKSpriteNode {

    let weapon: WeaponKind
    let ammoBoost: Int

    init(weapon: WeaponKind, ammoBoost: Int = 10) {
        self.weapon = weapon
        self.ammoBoost = ammoBoost
        let frames = AssetCatalog.pickupFrames(weapon)
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 70, height: 70))
        zPosition = 40
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask = PhysicsCategory.pickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        body.affectedByGravity = false
        physicsBody = body
        if !frames.isEmpty {
            run(.repeatForever(.animate(with: frames, timePerFrame: 1.0/6.0)))
        }
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.6),
            .moveBy(x: 0, y: -8, duration: 0.6)
        ])))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}

final class AmmoPickup: SKSpriteNode {
    let kind: AmmoKind
    let amount: Int

    init(kind: AmmoKind, amount: Int = 10) {
        self.kind = kind
        self.amount = amount
        let frames = AssetCatalog.ammoPickupFrames(kind)
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 72, height: 72))
        zPosition = 40
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask = PhysicsCategory.pickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        body.affectedByGravity = false
        physicsBody = body
        if !frames.isEmpty {
            run(.repeatForever(.animate(with: frames, timePerFrame: 1.0/6.0)))
        }
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 6, duration: 0.5),
            .moveBy(x: 0, y: -6, duration: 0.5)
        ])))
    }

    required init?(coder: NSCoder) { fatalError() }
}

final class GrenadePickup: SKSpriteNode {
    let amount: Int
    init(amount: Int = 2) {
        self.amount = amount
        let tex = SKTexture(imageNamed: AssetCatalog.grenadeImage)
        super.init(texture: tex, color: .clear, size: CGSize(width: 60, height: 60))
        zPosition = 40
        let body = SKPhysicsBody(rectangleOf: size)
        body.categoryBitMask = PhysicsCategory.pickup
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = 0
        body.affectedByGravity = false
        physicsBody = body
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.5),
            .moveBy(x: 0, y: -8, duration: 0.5)
        ])))
    }
    required init?(coder: NSCoder) { fatalError() }
}
