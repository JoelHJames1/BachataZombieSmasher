import SpriteKit

final class Pickup: SKSpriteNode {

    let weapon: WeaponKind
    let ammoBoost: Int

    init(weapon: WeaponKind, ammoBoost: Int = 12) {
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
        run(.repeatForever(.animate(with: frames, timePerFrame: 1.0/6.0)))
        run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.6),
            .moveBy(x: 0, y: -8, duration: 0.6)
        ])))
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }
}

final class GrenadePickup: SKSpriteNode {
    let amount: Int
    init(amount: Int = 2) {
        self.amount = amount
        let tex = SKTexture(imageNamed: AssetCatalog.playerGrenadeDeath)
        super.init(texture: nil, color: .systemOrange, size: CGSize(width: 50, height: 50))
        _ = tex
        zPosition = 40
        let label = SKLabelNode(text: "G")
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 30
        label.verticalAlignmentMode = .center
        addChild(label)
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
