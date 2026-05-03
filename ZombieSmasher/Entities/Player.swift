import SpriteKit

final class Player: SKSpriteNode {

    enum State { case idle, still, run, jump, attack, hit, dead }

    private(set) var state: State = .idle
    private(set) var weapon: WeaponKind = .bow
    var maxHealth: Int = 100
    var health: Int = 100 { didSet { onHealthChanged?(health, maxHealth) } }
    var ammo: [WeaponKind: Int] = [.handgun: 40, .rifle: 0, .bow: 0, .bat: 0]
    var fireArrowAmmo: Int = 30
    var grenades: Int = 10

    var onHealthChanged: ((Int, Int) -> Void)?
    var onWeaponChanged: ((WeaponKind, Int?) -> Void)?
    var onFireArrowChanged: ((Int) -> Void)?

    private var runFrames: [SKTexture]
    private let jumpFrames: [SKTexture]
    private let idleFrames: [SKTexture]
    private let hurtFrames: [SKTexture]
    private let fireHurtFrames: [SKTexture]
    private let deathFrames: [SKTexture]
    private var lastFireAt: TimeInterval = 0
    private var movingDir: CGFloat = 0
    private let jumpImpulse: CGFloat = 320
    private let idleDelay: TimeInterval = 5.0
    private var stoppedAt: TimeInterval = 0

    var isUsingFireArrow: Bool { weapon == .bow && fireArrowAmmo > 0 }

    init() {
        let frames = AssetCatalog.playerWalkFrames(weapon: .bow)
        runFrames = frames
        jumpFrames = AssetCatalog.playerJumpFrames()
        idleFrames = AssetCatalog.playerIdleDanceFrames()
        hurtFrames = AssetCatalog.playerHurtFrames()
        fireHurtFrames = AssetCatalog.playerFireHurtFrames()
        deathFrames = AssetCatalog.playerDeathFrames()
        let tex = frames.first ?? SKTexture()
        super.init(texture: tex, color: .clear, size: CGSize(width: 110, height: 130))
        anchorPoint = CGPoint(x: 0.5, y: 0.62)
        setScale(1.0)
        zPosition = 50
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 70, height: 120))
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.zombie | PhysicsCategory.pickup | PhysicsCategory.explosion | PhysicsCategory.fireball
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
        guard state != .hit, state != .dead else { return }
        movingDir = max(-1, min(1, direction))
        if abs(movingDir) > 0.05 {
            xScale = movingDir >= 0 ? 1 : -1
            if state == .idle || state == .still {
                if state == .idle { AudioManager.stopMusic() }
                enterRun()
            } else if state == .run, action(forKey: "anim") == nil {
                // Walk loop got dropped (e.g., after an attack sequence) —
                // restart it so the player isn't stuck on a static frame.
                enterRun()
            }
        } else if state == .run {
            enterStill()
        }
    }

    func update(dt: TimeInterval, currentTime: TimeInterval) {
        guard state != .dead else { return }
        let speed: CGFloat = 240
        if state == .hit {
            physicsBody?.velocity.dx = 0
        } else {
            physicsBody?.velocity.dx = movingDir * speed
        }

        if state == .jump, let body = physicsBody, abs(body.velocity.dy) < 1 {
            if abs(movingDir) > 0.05 { enterRun() } else { enterStill() }
        }
        if state == .still, currentTime - stoppedAt >= idleDelay {
            enterIdle()
        }
    }

    func jump() {
        guard state != .dead, state != .jump, state != .hit, let body = physicsBody else { return }
        if abs(body.velocity.dy) > 1 { return }
        if state == .idle { AudioManager.stopMusic() }
        body.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
        enterJump()
    }

    // MARK: - States

    private func enterIdle() {
        state = .idle
        removeAction(forKey: "anim")
        AudioManager.playMusic(named: "BachateBGSound")
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

    private func enterHit(useFireFrames: Bool = false) {
        state = .hit
        physicsBody?.velocity.dx = 0
        removeAction(forKey: "anim")
        let frames = useFireFrames ? fireHurtFrames : hurtFrames
        guard !frames.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.exitHit()
            }
            return
        }
        let anim = SKAction.animate(with: frames, timePerFrame: 1.0/14.0)
        run(.sequence([anim, .run { [weak self] in self?.exitHit() }]), withKey: "anim")
    }

    private func exitHit() {
        guard state == .hit else { return }
        if abs(movingDir) > 0.05 { enterRun() } else { enterStill() }
    }

    func tryFire(at currentTime: TimeInterval, scene: GameScene) {
        guard state != .dead, state != .hit else { return }
        if currentTime - lastFireAt < weapon.fireInterval { return }
        if state == .idle { AudioManager.stopMusic() }

        var firedFire = false
        if weapon == .bow, fireArrowAmmo > 0 {
            fireArrowAmmo -= 1
            firedFire = true
            onFireArrowChanged?(fireArrowAmmo)
        } else if !weapon.hasInfiniteAmmo {
            let count = ammo[weapon, default: 0]
            if count <= 0 { return }
            ammo[weapon] = count - 1
            onWeaponChanged?(weapon, ammo[weapon])
        }
        lastFireAt = currentTime
        playAttackAnimation(useFireArrow: firedFire)
        scene.spawnAttack(from: self, weapon: weapon, isFire: firedFire)

        switch weapon {
        case .handgun:  run(AudioManager.sfx("HandGunShootingSound"))
        case .bow:      run(AudioManager.sfx("BowShootingSound"))
        case .rifle:    run(AudioManager.sfx("HandGunShootingSound"))
        default:        break
        }
    }

    private func playAttackAnimation(useFireArrow: Bool) {
        let frames = AssetCatalog.playerAttackFrames(weapon: weapon, useFireArrow: useFireArrow)
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

    func addAmmo(_ kind: AmmoKind, amount: Int) {
        switch kind {
        case .rifle:
            ammo[.rifle, default: 0] += amount
            if weapon == .rifle { onWeaponChanged?(.rifle, ammo[.rifle]) }
        case .arrow:
            ammo[.bow, default: 0] += amount
            if weapon == .bow { onWeaponChanged?(.bow, ammo[.bow]) }
        case .fireArrow:
            fireArrowAmmo += amount
            onFireArrowChanged?(fireArrowAmmo)
        }
    }

    func takeDamage(_ amount: Int) {
        guard state != .dead, state != .hit else { return }
        if state == .idle { AudioManager.stopMusic() }
        health = max(0, health - amount)
        if health == 0 {
            die(byGrenade: false)
            return
        }
        enterHit(useFireFrames: false)
    }

    /// Player hit by fire (e.g. gargoyle fireball). Plays the dedicated
    /// fire-damage animation instead of the regular hurt frames.
    func takeFireDamage(_ amount: Int) {
        guard state != .dead, state != .hit else { return }
        if state == .idle { AudioManager.stopMusic() }
        health = max(0, health - amount)
        if health == 0 {
            die(byGrenade: false)
            return
        }
        enterHit(useFireFrames: true)
    }

    func die(byGrenade: Bool) {
        guard state != .dead else { return }
        AudioManager.stopMusic()
        state = .dead
        physicsBody?.velocity = .zero
        physicsBody?.categoryBitMask = PhysicsCategory.none
        removeAction(forKey: "anim")
        let frames = byGrenade ? AssetCatalog.explosionFrames() : deathFrames
        run(.animate(with: frames, timePerFrame: 1.0/10.0))
    }
}
