import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private let level: Int
    private var lastUpdate: TimeInterval = 0
    private var fireHeld = false
    private var killed = 0

    private struct ParallaxLayer {
        let copies: [SKSpriteNode]
        let parallax: CGFloat
        let width: CGFloat
    }

    private var world: SKNode!
    private var parallaxLayers: [ParallaxLayer] = []

    private var player: Player!
    private var zombies: [Zombie] = []
    private var spawner: SpawnDirector!

    private var joystick: Joystick!
    private var fireButton: SKShapeNode!
    private var jumpButton: SKShapeNode!
    private var hud: HUD!

    private var groundY: CGFloat = 0

    init(size: CGSize, level: Int) {
        self.level = level
        super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        scaleMode = .resizeFill
        spawner = SpawnDirector(level: level)
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self

        buildWorld()
        buildPlayer()
        buildHUD()
        buildControls()
    }

    // MARK: - Build

    private func buildWorld() {
        world = SKNode()
        addChild(world)

        groundY = -size.height * 0.38

        let bgName = AssetCatalog.levelBackground(level)
        addParallaxLayer(imageName: bgName,
                         parallax: 0.3,
                         zPosition: -10,
                         anchor: CGPoint(x: 0.5, y: 0.5),
                         positionY: 0,
                         scaleToHeight: true)

        if let groundName = AssetCatalog.levelGround(level) {
            let topOfGroundInImageY: CGFloat = 320
            let imageH: CGFloat = 724
            addParallaxLayer(imageName: groundName,
                             parallax: 1.0,
                             zPosition: -5,
                             anchor: CGPoint(x: 0.5, y: 1.0 - topOfGroundInImageY / imageH),
                             positionY: groundY,
                             scaleToHeight: false)
        }

        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundY)
        let body = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width * 5, y: 0),
                                 to:        CGPoint(x:  size.width * 5, y: 0))
        body.categoryBitMask = PhysicsCategory.ground
        body.collisionBitMask = PhysicsCategory.player | PhysicsCategory.zombie | PhysicsCategory.grenade
        body.contactTestBitMask = 0
        body.isDynamic = false
        ground.physicsBody = body
        addChild(ground)
    }

    private func buildPlayer() {
        player = Player()
        player.position = CGPoint(x: -size.width * 0.25, y: groundY + 65)
        addChild(player)

        player.onHealthChanged = { [weak self] h, m in self?.hud.setHealth(h, max: m) }
        player.onWeaponChanged = { [weak self] w, ammo in self?.hud.setWeapon(w, ammo: ammo) }
    }

    private func buildHUD() {
        hud = HUD()
        addChild(hud)
        hud.layout(in: size)
        hud.setHealth(player.health, max: player.maxHealth)
        hud.setWeapon(player.weapon, ammo: nil)
        hud.setKills(0, of: spawner.zombieGoal)
        hud.setGrenades(player.grenades)
    }

    private func buildControls() {
        joystick = Joystick()
        joystick.position = CGPoint(x: -size.width * 0.32, y: -size.height * 0.32)
        addChild(joystick)

        fireButton = SKShapeNode(circleOfRadius: 50)
        fireButton.fillColor = .systemRed.withAlphaComponent(0.7)
        fireButton.strokeColor = .white
        fireButton.lineWidth = 2
        fireButton.name = "fire"
        fireButton.zPosition = 1000
        fireButton.position = CGPoint(x: size.width * 0.34, y: -size.height * 0.32)
        addChild(fireButton)
        let lbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        lbl.text = "FIRE"; lbl.fontSize = 18; lbl.fontColor = .white; lbl.verticalAlignmentMode = .center
        fireButton.addChild(lbl)

        jumpButton = SKShapeNode(circleOfRadius: 42)
        jumpButton.fillColor = .systemBlue.withAlphaComponent(0.7)
        jumpButton.strokeColor = .white
        jumpButton.lineWidth = 2
        jumpButton.name = "jump"
        jumpButton.zPosition = 1000
        jumpButton.position = CGPoint(x: size.width * 0.22, y: -size.height * 0.22)
        addChild(jumpButton)
        let jlbl = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        jlbl.text = "JUMP"; jlbl.fontSize = 16; jlbl.fontColor = .white; jlbl.verticalAlignmentMode = .center
        jumpButton.addChild(jlbl)
    }

    // MARK: - Update

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : currentTime - lastUpdate
        lastUpdate = currentTime

        player.move(direction: joystick.value)
        player.update(dt: dt, currentTime: currentTime)

        for z in zombies { z.update(dt: dt) }

        if fireHeld { player.tryFire(at: currentTime, scene: self) }

        if zombies.isEmpty, spawner.tick(now: currentTime) { spawnZombie() }

        updateParallax()
        checkLevelComplete()
    }

    private func addParallaxLayer(imageName: String,
                                   parallax: CGFloat,
                                   zPosition: CGFloat,
                                   anchor: CGPoint,
                                   positionY: CGFloat,
                                   scaleToHeight: Bool) {
        let a = SKSpriteNode(imageNamed: imageName)
        let b = SKSpriteNode(imageNamed: imageName)
        let scale = scaleToHeight ? size.height / a.size.height : size.width / a.size.width
        a.setScale(scale)
        b.setScale(scale)
        a.anchorPoint = anchor
        b.anchorPoint = anchor
        a.zPosition = zPosition
        b.zPosition = zPosition
        let w = a.size.width
        a.position = CGPoint(x: 0, y: positionY)
        b.position = CGPoint(x: w, y: positionY)
        world.addChild(a)
        world.addChild(b)
        parallaxLayers.append(ParallaxLayer(copies: [a, b], parallax: parallax, width: w))
    }

    private func updateParallax() {
        let camX = player.position.x
        for layer in parallaxLayers {
            let offset = -camX * layer.parallax
            let r = offset.truncatingRemainder(dividingBy: layer.width)
            let baseX = r > 0 ? r - layer.width : r
            layer.copies[0].position.x = baseX
            layer.copies[1].position.x = baseX + layer.width
        }
    }

    private func spawnZombie() {
        let z = Zombie()
        let x = size.width * 0.55
        z.position = CGPoint(x: x, y: groundY + 65)
        z.target = player
        z.onDied = { [weak self] z in
            guard let self else { return }
            self.zombies.removeAll { $0 === z }
            self.killed += 1
            self.maybeDropPickup(at: z.position)
            SaveManager.totalKills += 1
            self.hud.setKills(self.killed, of: self.spawner.zombieGoal)
        }
        addChild(z)
        zombies.append(z)
    }

    private func maybeDropPickup(at pos: CGPoint) {
        let roll = Double.random(in: 0...1)
        if roll < 0.10 {
            let g = GrenadePickup(amount: 1)
            g.position = CGPoint(x: pos.x, y: groundY + 30)
            addChild(g)
            return
        }
        if roll < 0.55 {
            let weapons: [WeaponKind] = [.rifle, .bow, .bat]
            let w = weapons.randomElement() ?? .rifle
            let p = Pickup(weapon: w, ammoBoost: w.hasInfiniteAmmo ? 0 : 12)
            p.position = CGPoint(x: pos.x, y: groundY + 30)
            addChild(p)
        }
    }

    private func checkLevelComplete() {
        guard !spawner.hasMoreToSpawn, zombies.isEmpty, player.state != .dead else { return }
        SaveManager.unlock(level: level + 1)
        let go = GameOverScene(size: size, level: level, won: true, kills: killed)
        go.scaleMode = .resizeFill
        view?.presentScene(go, transition: .fade(withDuration: 0.6))
    }

    // MARK: - Combat

    func spawnAttack(from p: Player, weapon: WeaponKind) {
        let dir: CGFloat = p.xScale >= 0 ? 1 : -1
        if weapon.isRanged {
            let proj = Projectile(weapon: weapon, direction: dir)
            proj.position = CGPoint(x: p.position.x + 60 * dir, y: p.position.y + 8)
            addChild(proj)
        } else {
            // Melee — quick rect contact in front
            for z in zombies where z.state != .dead {
                let dx = z.position.x - p.position.x
                if (dir > 0 && dx > 0 && dx < 90) || (dir < 0 && dx < 0 && dx > -90) {
                    z.takeDamage(weapon.damage, kind: .melee)
                    z.physicsBody?.applyImpulse(CGVector(dx: 80 * dir, dy: 30))
                }
            }
        }
    }

    func throwGrenade() {
        guard player.grenades > 0, player.state != .dead else { return }
        player.grenades -= 1
        hud.setGrenades(player.grenades)
        let dir: CGFloat = player.xScale >= 0 ? 1 : -1
        let g = Grenade(direction: dir) { [weak self] pos in
            self?.detonate(at: pos)
        }
        g.position = CGPoint(x: player.position.x + 30 * dir, y: player.position.y + 20)
        addChild(g)
    }

    private func detonate(at pos: CGPoint) {
        let ex = Explosion()
        ex.position = pos
        addChild(ex)
        for z in zombies where z.state != .dead {
            let d = hypot(z.position.x - pos.x, z.position.y - pos.y)
            if d < 140 { z.die(kind: .grenade) }
        }
        if hypot(player.position.x - pos.x, player.position.y - pos.y) < 90 {
            player.die(byGrenade: true)
            failLevel()
        }
    }

    private func failLevel() {
        run(.sequence([.wait(forDuration: 1.2), .run { [weak self] in
            guard let self else { return }
            let go = GameOverScene(size: self.size, level: self.level, won: false, kills: self.killed)
            go.scaleMode = .resizeFill
            self.view?.presentScene(go, transition: .fade(withDuration: 0.6))
        }]))
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)

            if let name = atPoint(p).name ?? atPoint(p).parent?.name {
                if name == "pause" {
                    isPaused.toggle()
                    return
                }
                if name == "grenade" {
                    throwGrenade()
                    return
                }
            }
            if fireButton.contains(p) {
                fireHeld = true
                continue
            }
            if jumpButton.contains(p) {
                player.jump()
                continue
            }
            if p.x < 0 {
                joystick.position = p
                joystick.beginTracking(t, in: self)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        joystick.update(touches: touches, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            joystick.endTracking(t)
            let p = t.location(in: self)
            if fireButton.contains(p) || fireHeld { fireHeld = false }
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Contacts

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        let mask = a.categoryBitMask | b.categoryBitMask

        if mask & (PhysicsCategory.bullet | PhysicsCategory.zombie) == (PhysicsCategory.bullet | PhysicsCategory.zombie) {
            let bullet = a.categoryBitMask == PhysicsCategory.bullet ? a.node as? Projectile : b.node as? Projectile
            let zombie = a.categoryBitMask == PhysicsCategory.zombie ? a.node as? Zombie : b.node as? Zombie
            if let bullet, let zombie {
                zombie.takeDamage(bullet.weapon.damage, kind: .bullet)
                bullet.removeFromParent()
            }
        } else if mask & (PhysicsCategory.arrow | PhysicsCategory.zombie) == (PhysicsCategory.arrow | PhysicsCategory.zombie) {
            let arrow = a.categoryBitMask == PhysicsCategory.arrow ? a.node as? Projectile : b.node as? Projectile
            let zombie = a.categoryBitMask == PhysicsCategory.zombie ? a.node as? Zombie : b.node as? Zombie
            if let arrow, let zombie {
                zombie.takeDamage(arrow.weapon.damage, kind: .arrow)
                arrow.removeFromParent()
            }
        } else if mask & (PhysicsCategory.grenade | PhysicsCategory.zombie) == (PhysicsCategory.grenade | PhysicsCategory.zombie) {
            let grenade = a.categoryBitMask == PhysicsCategory.grenade ? a.node as? Grenade : b.node as? Grenade
            if let grenade {
                detonate(at: grenade.position)
                grenade.removeFromParent()
            }
        } else if mask & (PhysicsCategory.zombie | PhysicsCategory.player) == (PhysicsCategory.zombie | PhysicsCategory.player) {
            player.takeDamage(8)
            if player.state == .dead { failLevel() }
        } else if mask & (PhysicsCategory.pickup | PhysicsCategory.player) == (PhysicsCategory.pickup | PhysicsCategory.player) {
            let pickup = a.categoryBitMask == PhysicsCategory.pickup ? a.node : b.node
            if let p = pickup as? Pickup {
                player.equip(p.weapon, addAmmo: p.ammoBoost)
                p.removeFromParent()
            } else if let g = pickup as? GrenadePickup {
                player.grenades += g.amount
                hud.setGrenades(player.grenades)
                g.removeFromParent()
            }
        }
    }
}
