import SpriteKit

/// A single platform tile rendered with `road.png` content. Has an edge
/// physics body on its top surface. Spans `[startX, startX + width]` in scene-x
/// at `topY` in scene-y. Players and zombies stand on it.
final class Platform: SKNode {

    let startX: CGFloat
    let width: CGFloat
    let topY: CGFloat
    let visual: SKSpriteNode

    init(startX: CGFloat, width: CGFloat, topY: CGFloat, imageName: String,
         imageH: CGFloat = 1098, topInImageY: CGFloat = 0) {
        self.startX = startX
        self.width = width
        self.topY = topY
        let tex = SKTexture(imageNamed: imageName)
        visual = SKSpriteNode(texture: tex)
        super.init()
        // Scale the road texture so its full image width = platform width.
        let scale = width / visual.size.width
        visual.setScale(scale)
        // Anchor so the visible road TOP (image_y = topInImageY) sits at topY.
        visual.anchorPoint = CGPoint(x: 0, y: 1.0 - topInImageY / imageH)
        visual.position = CGPoint(x: startX, y: topY)
        visual.zPosition = -5
        addChild(visual)

        let body = SKPhysicsBody(edgeFrom: CGPoint(x: startX, y: topY),
                                 to:        CGPoint(x: startX + width, y: topY))
        body.categoryBitMask = PhysicsCategory.ground
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.zombie | PhysicsCategory.grenade
        body.contactTestBitMask = 0
        body.isDynamic = false
        physicsBody = body
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    /// True if a world-space x position sits on this platform.
    func contains(x: CGFloat) -> Bool {
        x >= startX && x <= startX + width
    }

    var endX: CGFloat { startX + width }
}
