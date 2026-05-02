import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    private let level: Int
    private var lastUpdate: TimeInterval = 0
    private var fireHeld = false
    private var killed = 0
    private var survivalStart: TimeInterval = 0
    private var survivalElapsed: TimeInterval = 0

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

    private var inventoryOverlay: SKNode?

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
        // Anchor bg's top at screen top; scale large enough that its dark
        // bottom region lands BELOW the road (off-screen), eliminating the
        // black gap between bg and road.
        let bgScaleFactor: CGFloat = 1.6
        addParallaxLayer(imageName: bgName,
                         parallax: 0.3,
                         zPosition: -10,
                         anchor: CGPoint(x: 0.5, y: 1.0),
                         positionY: size.height / 2,
                         scaleToHeight: true,
                         extraScale: bgScaleFactor)

        if let groundName = AssetCatalog.levelGround(level) {
            // road.png is 1916x821; visible road surface lives in the upper portion of the canvas.
            let topOfGroundInImageY: CGFloat = 360
            let imageH: CGFloat = 821
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
        player.onWeaponChanged = { [weak self] w, _ in
            guard let self else { return }
            self.hud.setWeapon(w, ammo: nil)
            self.refreshAmmoHud()
        }
        player.onFireArrowChanged = { [weak self] _ in self?.refreshAmmoHud() }
    }

    private func refreshAmmoHud() {
        hud.setAmmoCounts(
            handgun: player.ammo[.handgun, default: 0],
            rifle: player.ammo[.rifle, default: 0],
            normalArrow: player.ammo[.bow, default: 0],
            fireArrow: player.fireArrowAmmo
        )
    }

    private func buildHUD() {
        hud = HUD()
        addChild(hud)
        hud.layout(in: size)
        hud.setHealth(player.health, max: player.maxHealth)
        hud.setWeapon(player.weapon, ammo: nil)
        hud.setSurvival(time: 0, kills: 0)
        hud.setGrenades(player.grenades)
        refreshAmmoHud()
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

        if survivalStart == 0 { survivalStart = currentTime }
        if player.state != .dead {
            survivalElapsed = currentTime - survivalStart
        }

        player.move(direction: joystick.value)
        player.update(dt: dt, currentTime: currentTime)

        for z in zombies { z.update(dt: dt, currentTime: currentTime) }

        if fireHeld { player.tryFire(at: currentTime, scene: self) }

        if spawner.tick(now: currentTime) { spawnZombie() }

        updateParallax()
        hud.setSurvival(time: survivalElapsed, kills: killed)
    }

    private func addParallaxLayer(imageName: String,
                                   parallax: CGFloat,
                                   zPosition: CGFloat,
                                   anchor: CGPoint,
                                   positionY: CGFloat,
                                   scaleToHeight: Bool,
                                   extraScale: CGFloat = 1.0) {
        let a = SKSpriteNode(imageNamed: imageName)
        let b = SKSpriteNode(imageNamed: imageName)
        let baseScale = scaleToHeight ? size.height / a.size.height : size.width / a.size.width
        let scale = baseScale * extraScale
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
            self.hud.setSurvival(time: self.survivalElapsed, kills: self.killed)
        }
        z.onBite = { [weak self] _ in
            guard let self else { return }
            self.player.takeDamage(8)
            if self.player.state == .dead { self.failLevel() }
        }
        addChild(z)
        zombies.append(z)
    }

    private func maybeDropPickup(at pos: CGPoint) {
        let roll = Double.random(in: 0...1)
        // 5% grenade, 7% weapon swap, 13% ammo, 75% nothing.
        if roll < 0.05 {
            let g = GrenadePickup(amount: 1)
            g.position = CGPoint(x: pos.x, y: groundY + 30)
            addChild(g)
            return
        }
        if roll < 0.12 {
            let weapons: [WeaponKind] = [.rifle, .bow, .bat]
            let w = weapons.randomElement() ?? .rifle
            let p = Pickup(weapon: w, ammoBoost: w.hasInfiniteAmmo ? 0 : 10)
            p.position = CGPoint(x: pos.x, y: groundY + 30)
            addChild(p)
            return
        }
        if roll < 0.25 {
            let kinds: [AmmoKind] = [.rifle, .arrow, .fireArrow]
            let kind = kinds.randomElement() ?? .rifle
            let a = AmmoPickup(kind: kind, amount: 10)
            a.position = CGPoint(x: pos.x, y: groundY + 30)
            addChild(a)
        }
    }

    // MARK: - Combat

    func spawnAttack(from p: Player, weapon: WeaponKind, isFire: Bool = false) {
        let dir: CGFloat = p.xScale >= 0 ? 1 : -1
        if weapon.isRanged {
            let proj = Projectile(weapon: weapon, direction: dir, isFire: isFire)
            proj.position = CGPoint(x: p.position.x + 60 * dir, y: p.position.y + 8)
            addChild(proj)
        } else {
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
        SaveManager.recordSurvival(time: survivalElapsed, kills: killed)
        run(.sequence([.wait(forDuration: 1.5), .run { [weak self] in
            guard let self else { return }
            let go = GameOverScene(size: self.size,
                                   level: self.level,
                                   won: false,
                                   kills: self.killed,
                                   survivalTime: self.survivalElapsed)
            go.scaleMode = .resizeFill
            self.view?.presentScene(go, transition: .fade(withDuration: 0.6))
        }]))
    }

    // MARK: - Inventory overlay

    private func presentInventory() {
        guard inventoryOverlay == nil else { return }
        isPaused = true
        let overlay = SKNode()
        overlay.zPosition = 2000

        let dim = SKSpriteNode(color: .black.withAlphaComponent(0.65), size: size)
        dim.position = .zero
        dim.name = "inventoryDim"
        overlay.addChild(dim)

        let weapons: [WeaponKind] = [.handgun, .rifle, .bow, .bat]
        let slotSize: CGFloat = min(size.height * 0.30, 130)
        let gap: CGFloat = 16
        let panelW = CGFloat(weapons.count) * slotSize + CGFloat(weapons.count - 1) * gap + 40
        let panelH = slotSize + 80

        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 18)
        panel.fillColor = .black.withAlphaComponent(0.85)
        panel.strokeColor = .white
        panel.lineWidth = 2
        panel.position = .zero
        panel.zPosition = 1
        overlay.addChild(panel)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "INVENTORY"
        title.fontSize = 18
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelH/2 - 24)
        title.zPosition = 2
        overlay.addChild(title)

        let totalSlotsW = CGFloat(weapons.count) * slotSize + CGFloat(weapons.count - 1) * gap
        for (i, w) in weapons.enumerated() {
            let slotX = -totalSlotsW/2 + slotSize/2 + CGFloat(i) * (slotSize + gap)
            let slotY: CGFloat = -10
            let isSelected = w == player.weapon
            let available = canEquip(w)

            let slot = SKShapeNode(rectOf: CGSize(width: slotSize, height: slotSize), cornerRadius: 12)
            slot.fillColor = isSelected ? .systemGreen.withAlphaComponent(0.30) : .white.withAlphaComponent(0.05)
            slot.strokeColor = isSelected ? .white : .white.withAlphaComponent(0.4)
            slot.lineWidth = isSelected ? 3 : 1.5
            slot.position = CGPoint(x: slotX, y: slotY)
            slot.zPosition = 3
            slot.alpha = available ? (isSelected ? 1.0 : 0.55) : 0.20
            slot.name = available ? "invSlot_\(w.rawValue)" : "invSlotDisabled"
            overlay.addChild(slot)

            let iconTexture: SKTexture
            switch w {
            case .handgun:
                iconTexture = SKTexture(imageNamed: AssetCatalog.iconHandgun)
            default:
                iconTexture = AssetCatalog.pickupFrames(w).first ?? SKTexture()
            }
            let icon = SKSpriteNode(texture: iconTexture)
            icon.size = CGSize(width: slotSize * 0.85, height: slotSize * 0.85)
            icon.position = CGPoint(x: slotX, y: slotY)
            icon.zPosition = 4
            icon.alpha = available ? (isSelected ? 1.0 : 0.55) : 0.20
            icon.name = slot.name
            overlay.addChild(icon)

            let count = ammoCount(for: w)
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            if w.hasInfiniteAmmo {
                label.text = "\(w.label.uppercased())  ∞"
            } else if w == .bat {
                label.text = w.label.uppercased()
            } else {
                label.text = "\(w.label.uppercased())  ×\(count)"
            }
            label.fontSize = 12
            label.fontColor = available ? .white : .white.withAlphaComponent(0.4)
            label.verticalAlignmentMode = .top
            label.horizontalAlignmentMode = .center
            label.position = CGPoint(x: slotX, y: slotY - slotSize/2 - 4)
            label.zPosition = 5
            label.alpha = available ? (isSelected ? 1.0 : 0.7) : 0.4
            label.name = slot.name
            overlay.addChild(label)
        }

        let close = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        close.text = "✕ CLOSE"
        close.fontSize = 16
        close.fontColor = .white
        close.position = CGPoint(x: size.width/2 - 80, y: size.height/2 - 60)
        close.zPosition = 5
        close.name = "invClose"
        overlay.addChild(close)

        addChild(overlay)
        inventoryOverlay = overlay
    }

    private func dismissInventory() {
        inventoryOverlay?.removeFromParent()
        inventoryOverlay = nil
        isPaused = false
    }

    private func canEquip(_ w: WeaponKind) -> Bool {
        if w.hasInfiniteAmmo { return true }
        switch w {
        case .bow:
            return player.ammo[.bow, default: 0] > 0 || player.fireArrowAmmo > 0
        case .bat:
            return true
        default:
            return player.ammo[w, default: 0] > 0
        }
    }

    private func ammoCount(for w: WeaponKind) -> Int {
        switch w {
        case .bow: return player.ammo[.bow, default: 0] + player.fireArrowAmmo
        default:   return player.ammo[w, default: 0]
        }
    }

    // MARK: - Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)

            if let overlay = inventoryOverlay {
                let nodes = overlay.nodes(at: p) + self.nodes(at: p)
                for node in nodes {
                    if node.name == "invClose" || node.name == "inventoryDim" {
                        if node.name == "invClose" { dismissInventory() }
                        return
                    }
                    if let n = node.name, n.hasPrefix("invSlot_"),
                       let raw = Int(n.dropFirst("invSlot_".count)),
                       let w = WeaponKind(rawValue: raw) {
                        player.equip(w)
                        dismissInventory()
                        return
                    }
                }
                return
            }

            if let name = atPoint(p).name ?? atPoint(p).parent?.name {
                if name == "pause" {
                    isPaused.toggle()
                    return
                }
                if name == "grenade" {
                    throwGrenade()
                    return
                }
                if name == "inventory" {
                    presentInventory()
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
                let damage = arrow.isFire ? 30 : 12
                zombie.takeDamage(damage, kind: arrow.isFire ? .fireArrow : .arrow)
                arrow.removeFromParent()
            }
        } else if mask & (PhysicsCategory.grenade | PhysicsCategory.zombie) == (PhysicsCategory.grenade | PhysicsCategory.zombie) {
            let grenade = a.categoryBitMask == PhysicsCategory.grenade ? a.node as? Grenade : b.node as? Grenade
            if let grenade {
                detonate(at: grenade.position)
                grenade.removeFromParent()
            }
        } else if mask & (PhysicsCategory.pickup | PhysicsCategory.player) == (PhysicsCategory.pickup | PhysicsCategory.player) {
            let pickup = a.categoryBitMask == PhysicsCategory.pickup ? a.node : b.node
            if let p = pickup as? Pickup {
                player.equip(p.weapon, addAmmo: p.ammoBoost)
                p.removeFromParent()
            } else if let g = pickup as? GrenadePickup {
                player.grenades += g.amount
                hud.setGrenades(player.grenades)
                g.removeFromParent()
            } else if let a = pickup as? AmmoPickup {
                player.addAmmo(a.kind, amount: a.amount)
                a.removeFromParent()
            }
        }
    }
}
