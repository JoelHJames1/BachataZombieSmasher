import SpriteKit

final class Player: SKSpriteNode {

    enum State { case idle, still, run, jump, attack, dead }

    private(set) var state: State = .idle
    private(set) var weapon: WeaponKind = .handgun
    var maxHealth: Int = 100
    var health: Int = 100 { didSet { onHealthChanged?(health, maxHealth) } }
    var ammo: [WeaponKind: Int] = [.rifle: 0, .bow: 0, .bat: 0]
    var grenades: Int = 0

    var onHealthChanged: ((Int, Int) -> Void)?
    var onWeaponChanged: ((WeaponKind, Int?) -> Void)?

    private var runFrames: [SKTexture]
    private let jumpFrames: [SKTexture]
    private let idleFrames: [SKTexture]
    private var lastFireAt: TimeInterval = 0
    private var movingDir: CGFloat = 0
    private let jumpImpulse: CGFloat = 320
    private let idleDelay: TimeInterval = 5.0
    private var stoppedAt: TimeInterval = 0

    init() {
        let frames = AssetCatalog.playerWalkFrames(weapon: .handgun)
        runFrames = frames
        jumpFrames = AssetCatalog.playerJumpFrames()
        idleFrames = AssetCatalog.playerIdleDanceFrames()
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 110, height: 130))
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        setScale(1.0)
        zPosition = 50
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 70, height: 120))
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.pickup | PhysicsCategory.explosion
        body.collisionBitMask = PhysicsCategory.ground
        body.allowsRotation = false
        body.affectedByGravity = true
        body.friction = 0
        body.linearDamping = 0
        physicsBody = body
        enterStill()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Movement

    func move(direction: CGFloat) {
        movingDir = max(-1, min(1, direction))
        if abs(movingDir) > 0.05 {
            xScale = movingDir >= 0 ? 1 : -1
            if state == .idle || state == .still { enterRun() }
        } else if state == .run {
            enterStill()
        }
    }

    func update(dt: TimeInterval, currentTime: TimeInterval) {
        guard state != .dead else { return }
        let speed: CGFloat = 240
        physicsBody?.velocity.dx = movingDir * speed

        if state == .jump, let body = physicsBody, abs(body.velocity.dy) < 1 {
            if abs(movingDir) > 0.05 { enterRun() } else { enterStill() }
        }
        if state == .still, currentTime - stoppedAt >= idleDelay {
            enterIdle()
        }
    }

    func jump() {
        guard state != .dead, state != .jump, let body = physicsBody else { return }
        if abs(body.velocity.dy) > 1 { return }
        body.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
        enterJump()
    }

    // MARK: - States

    private func enterIdle() {
        state = .idle
        removeAction(forKey: "anim")
        guard !idleFrames.isEmpty else {
            texture = runFrames.first
            return
        }
        let anim = SKAction.animate(with: idleFrames, timePerFrame: 1.0/8.0)
        run(.repeatForever(anim), withKey: "anim")
    }

    private func enterStill() {
        state = .still
        stoppedAt = CACurrentMediaTime()
        removeAction(forKey: "anim")
        texture = runFrames.first
    }

    private func enterRun() {
        state = .run
        let anim = SKAction.animate(with: runFrames, timePerFrame: 1.0/12.0)
        run(.repeatForever(anim), withKey: "anim")
    }

    private func enterJump() {
        state = .jump
        removeAction(forKey: "anim")
        guard !jumpFrames.isEmpty else { return }
        let anim = SKAction.animate(with: jumpFrames, timePerFrame: 1.0/14.0)
        run(.repeatForever(anim), withKey: "anim")
    }

    func tryFire(at currentTime: TimeInterval, scene: GameScene) {
        guard state != .dead else { return }
        if currentTime - lastFireAt < weapon.fireInterval { return }
        if !weapon.hasInfiniteAmmo {
            let count = ammo[weapon, default: 0]
            if count <= 0 { return }
            ammo[weapon] = count - 1
            onWeaponChanged?(weapon, ammo[weapon])
        }
        lastFireAt = currentTime
        playAttackAnimation()
        scene.spawnAttack(from: self, weapon: weapon)
    }

    private func playAttackAnimation() {
        let frames = AssetCatalog.playerAttackFrames(weapon: weapon)
        let action = SKAction.animate(with: frames, timePerFrame: 1.0/16.0)
        run(.sequence([action, .run { [weak self] in
            guard let self else { return }
            if self.state == .run {
                let anim = SKAction.animate(with: self.runFrames, timePerFrame: 1.0/12.0)
                self.run(.repeatForever(anim), withKey: "anim")
            } else {
                self.texture = self.runFrames.first
            }
        }]), withKey: "anim")
    }

    func equip(_ w: WeaponKind, addAmmo: Int = 0) {
        weapon = w
        if addAmmo > 0, !w.hasInfiniteAmmo {
            ammo[w, default: 0] += addAmmo
        }
        runFrames = AssetCatalog.playerWalkFrames(weapon: w)
        if state == .run, !runFrames.isEmpty {
            let anim = SKAction.animate(with: runFrames, timePerFrame: 1.0/12.0)
            run(.repeatForever(anim), withKey: "anim")
        }
        onWeaponChanged?(w, w.hasInfiniteAmmo ? nil : ammo[w])
    }

    func takeDamage(_ amount: Int) {
        guard state != .dead else { return }
        health = max(0, health - amount)
        if health == 0 { die(byGrenade: false) }
    }

    func die(byGrenade: Bool) {
        guard state != .dead else { return }
        state = .dead
        physicsBody?.velocity = .zero
        physicsBody?.categoryBitMask = PhysicsCategory.none
        removeAction(forKey: "anim")
        let frames = AssetCatalog.playerDeathFrames()
        run(.animate(with: frames, timePerFrame: 1.0/10.0))
    }
}
