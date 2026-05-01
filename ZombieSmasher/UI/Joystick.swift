import SpriteKit

final class Joystick: SKNode {

    private let base: SKShapeNode
    private let stick: SKShapeNode
    private let radius: CGFloat = 60
    private(set) var value: CGFloat = 0
    private var trackingTouch: UITouch?

    override init() {
        base  = SKShapeNode(circleOfRadius: 60)
        stick = SKShapeNode(circleOfRadius: 28)
        super.init()
        base.fillColor = .white.withAlphaComponent(0.15)
        base.strokeColor = .white.withAlphaComponent(0.5)
        base.lineWidth = 2
        stick.fillColor = .white.withAlphaComponent(0.6)
        stick.strokeColor = .white
        stick.lineWidth = 2
        addChild(base)
        addChild(stick)
        zPosition = 1000
        isUserInteractionEnabled = false
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    func beginTracking(_ touch: UITouch, in scene: SKScene) {
        trackingTouch = touch
    }

    func update(touches: Set<UITouch>, in scene: SKScene) {
        guard let t = trackingTouch, touches.contains(t) else { return }
        let p = t.location(in: self)
        let dx = max(-radius, min(radius, p.x))
        stick.position = CGPoint(x: dx, y: 0)
        value = dx / radius
    }

    func endTracking(_ touch: UITouch) {
        guard touch == trackingTouch else { return }
        trackingTouch = nil
        stick.run(.move(to: .zero, duration: 0.1))
        value = 0
    }

    func owns(_ touch: UITouch) -> Bool { touch == trackingTouch }
}
