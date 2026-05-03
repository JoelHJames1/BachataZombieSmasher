import SpriteKit

/// Flying enemy that hovers above the player, dives down to fire a fireball,
/// then climbs back up. Mini health bar shows damage.
/// Killed by bullets/arrows → crashes down. Killed by grenade → explodes.
final class Gargoyle: SKSpriteNode {

    enum State { case fly, dive, attack, retreat, dead }

    private(set) var state: State = .fly
    var maxHealth: Int = 25
    var health: Int = 25 { didSet { updateHealthBar() } }
    var moveSpeed: CGFloat = 70
    weak var target: SKNode?

    private let flyFrames: [SKTexture]
    private let attackFrames: [SKTexture]
    var onDied: ((Gargoyle) -> Void)?
    var onShoot: ((Gargoyle, CGFloat) -> Void)?

    private let aggroRange: CGFloat = 420
    private let preferredHoverY: CGFloat
    private var diveTargetY: CGFloat = 0
    private var lastDiveAt: TimeInterval = 0
    private let diveInterval: TimeInterval = 3.5
    private var bobAccumulator: TimeInterval = 0

    // Mini health bar
    private let healthBarBg: SKShapeNode
    private let healthBarFill: SKShapeNode
    private let healthBarWidth: CGFloat = 60
    private let healthBarHeight: CGFloat = 6

    init(hoverY: CGFloat) {
        let frames = AssetCatalog.gargoyleFlyFrames()
        flyFrames = frames
        attackFrames = AssetCatalog.gargoyleFireAttackFrames()
        preferredHoverY = hoverY

        healthBarBg = SKShapeNode(rectOf: CGSize(width: 60, height: 6), cornerRadius: 2)
        healthBarFill = SKShapeNode(rectOf: CGSize(width: 60, height: 6), cornerRadius: 2)

        let tex = frames.first ?? SKTexture()
        // Fixed display size — keeps gargoyle proportional regardless of which
        // frame is showing (fly square-ish vs attack wide-with-fire-breath).
        super.init(texture: tex, color: .clear, size: CGSize(width: 70, height: 56))
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        zPosition = 55

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 90, height: 70))
        body.categoryBitMask = PhysicsCategory.gargoyle
        body.contactTestBitMask = PhysicsCategory.bullet | PhysicsCategory.arrow | PhysicsCategory.explosion | PhysicsCategory.grenade
        body.collisionBitMask = 0
        body.affectedByGravity = false
        body.allowsRotation = false
        physicsBody = body

        // Mini health bar above the gargoyle
        healthBarBg.fillColor = .black.withAlphaComponent(0.6)
        healthBarBg.strokeColor = .white
        healthBarBg.lineWidth = 1
        healthBarBg.position = CGPoint(x: 0, y: 90)
        healthBarBg.zPosition = 100
        addChild(healthBarBg)

        healthBarFill.fillColor = .systemRed
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: 0, y: 90)
        healthBarFill.zPosition = 101
        addChild(healthBarFill)
        updateHealthBar()

        startFly()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func updateHealthBar() {
        let pct = max(0, min(1, CGFloat(health) / CGFloat(maxHealth)))
        healthBarFill.xScale = pct
        healthBarFill.position.x = -healthBarWidth/2 + (healthBarWidth * pct)/2
        healthBarFill.fillColor = pct > 0.5 ? .systemGreen : (pct > 0.25 ? .systemYellow : .systemRed)
        // Hide when full / hide when dead
        healthBarBg.isHidden = state == .dead
        healthBarFill.isHidden = state == .dead
    }

    private func startFly() {
        state = .fly
        removeAction(forKey: "anim")
        let anim = SKAction.animate(with: flyFrames,
                                    timePerFrame: 1.0/10.0,
                                    resize: false,
                                    restore: false)
        run(.repeatForever(anim), withKey: "anim")
    }

    private func startAttack() {
        state = .attack
        removeAction(forKey: "anim")
        let anim = SKAction.animate(with: attackFrames,
                                    timePerFrame: 1.0/12.0,
                                    resize: false,
                                    restore: false)
        run(.sequence([anim, .run { [weak self] in self?.beginRetreat() }]), withKey: "anim")
    }

    private func beginRetreat() {
        state = .retreat
        removeAction(forKey: "anim")
        let anim = SKAction.animate(with: flyFrames,
                                    timePerFrame: 1.0/10.0,
                                    resize: false,
                                    restore: false)
        run(.repeatForever(anim), withKey: "anim")
    }

    func update(dt: TimeInterval, currentTime: TimeInterval) {
        guard state != .dead, let target else { return }
        bobAccumulator += dt

        let dx = target.position.x - position.x
        let dir: CGFloat = dx >= 0 ? 1 : -1
        xScale = dir

        switch state {
        case .fly:
            // Cruise toward player at hover height with gentle bob.
            let dy = preferredHoverY - position.y
            let vx = abs(dx) > 30 ? dir * moveSpeed : 0
            let vy = dy * 1.5 + sin(bobAccumulator * 2) * 12
            physicsBody?.velocity = CGVector(dx: vx, dy: vy)

            // If close enough, start a dive attack on cooldown.
            if abs(dx) < aggroRange,
               currentTime - lastDiveAt > diveInterval {
                lastDiveAt = currentTime
                state = .dive
                // Dive low — close to the player's head so the swoop is
                // dramatic and the fireball tracks horizontally at body level.
                diveTargetY = target.position.y + 40
            }

        case .dive:
            // Fighter-jet style dive: aim straight at the player, accelerate
            // hard, rotate sprite to point along velocity vector. Strafes
            // across the player's altitude before pulling out of the dive.
            let approachX = target.position.x - position.x
            let approachY = target.position.y + 40 - position.y
            let len = max(1, hypot(approachX, approachY))
            let speed: CGFloat = 320
            let vx = approachX / len * speed
            let vy = approachY / len * speed
            physicsBody?.velocity = CGVector(dx: vx, dy: vy)
            zRotation = atan2(vy, vx) * (dir > 0 ? 1 : -1) * 0.3   // slight bank
            if hypot(approachX, approachY) < 70 {
                physicsBody?.velocity = .zero
                zRotation = 0
                startAttack()
                run(.sequence([.wait(forDuration: 0.25), .run { [weak self] in
                    guard let self else { return }
                    self.onShoot?(self, dir)
                }]))
            }

        case .attack:
            // Hold position while the fire-breath animation plays.
            physicsBody?.velocity = .zero

        case .retreat:
            // Climb back up to hover height.
            let dy = preferredHoverY - position.y
            let vx = -dir * moveSpeed * 0.8   // drift away from player
            let vy = dy * 3
            physicsBody?.velocity = CGVector(dx: vx, dy: vy)
            if abs(dy) < 20 {
                startFly()
            }

        case .dead:
            break
        }
    }

    func takeDamage(_ amount: Int, kind: HitKind) {
        guard state != .dead else { return }
        health -= amount
        if health <= 0 { die(kind: kind) }
    }

    func die(kind: HitKind) {
        guard state != .dead else { return }
        state = .dead
        physicsBody?.categoryBitMask = PhysicsCategory.none
        physicsBody?.contactTestBitMask = 0
        physicsBody?.velocity = .zero
        // Always crash down on death — gargoyle becomes a falling corpse that
        // lands on the ground/platform regardless of what killed it. Grenade
        // death uses its own animation (the explosion sheet) but still falls.
        physicsBody?.affectedByGravity = true
        physicsBody?.collisionBitMask = PhysicsCategory.ground
        physicsBody?.allowsRotation = true
        physicsBody?.angularDamping = 1.5
        removeAction(forKey: "anim")
        healthBarBg.isHidden = true
        healthBarFill.isHidden = true

        let frames: [SKTexture]
        switch kind {
        case .grenade: frames = AssetCatalog.gargoyleGrenadeDeathFrames()
        default:       frames = AssetCatalog.gargoyleDeathFrames()
        }
        let anim = SKAction.animate(with: frames,
                                    timePerFrame: 1.0/10.0,
                                    resize: true,
                                    restore: false)
        run(.sequence([
            anim,
            .run { [weak self] in self?.onDied?(self!) },
            .wait(forDuration: 4.0),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }
}
