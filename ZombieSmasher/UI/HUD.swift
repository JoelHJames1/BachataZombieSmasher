import SpriteKit

final class HUD: SKNode {

    private let healthBar: SKShapeNode
    private let healthFill: SKShapeNode
    private let weaponLabel: SKLabelNode
    private let killsLabel: SKLabelNode
    private let grenadeLabel: SKLabelNode
    private let grenadeIcon: SKSpriteNode

    // Per-weapon ammo counters (always visible, dimmed when 0 / inactive)
    private let handgunAmmoLabel: SKLabelNode
    private let rifleAmmoLabel: SKLabelNode
    private let arrowAmmoLabel: SKLabelNode
    private let fireArrowLabel: SKLabelNode

    let pauseButton: SKLabelNode
    let grenadeButton: SKShapeNode
    let inventoryButton: SKSpriteNode

    private let barWidth: CGFloat = 180
    private let barHeight: CGFloat = 14

    private var activeWeapon: WeaponKind = .handgun

    override init() {
        healthBar = SKShapeNode(rectOf: CGSize(width: 180, height: 14), cornerRadius: 4)
        healthFill = SKShapeNode(rectOf: CGSize(width: 180, height: 14), cornerRadius: 4)
        weaponLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        killsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        grenadeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        handgunAmmoLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        rifleAmmoLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        arrowAmmoLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        fireArrowLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseButton = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        grenadeButton = SKShapeNode(circleOfRadius: 36)
        grenadeIcon = SKSpriteNode(imageNamed: AssetCatalog.grenadeImage)
        inventoryButton = SKSpriteNode(imageNamed: AssetCatalog.inventoryButton)
        super.init()
        zPosition = 900

        healthBar.fillColor = .black.withAlphaComponent(0.45)
        healthBar.strokeColor = .white
        healthBar.lineWidth = 1.5
        addChild(healthBar)

        healthFill.fillColor = .systemGreen
        healthFill.strokeColor = .clear
        addChild(healthFill)

        weaponLabel.fontSize = 14
        weaponLabel.fontColor = .systemYellow
        weaponLabel.horizontalAlignmentMode = .left
        addChild(weaponLabel)

        for lbl in [handgunAmmoLabel, rifleAmmoLabel, arrowAmmoLabel, fireArrowLabel] {
            lbl.fontSize = 13
            lbl.fontColor = .white
            lbl.horizontalAlignmentMode = .left
            addChild(lbl)
        }

        killsLabel.fontSize = 16
        killsLabel.fontColor = .white
        killsLabel.horizontalAlignmentMode = .right
        addChild(killsLabel)

        pauseButton.text = "❚❚"
        pauseButton.fontSize = 22
        pauseButton.fontColor = .white
        pauseButton.name = "pause"
        addChild(pauseButton)

        grenadeButton.fillColor = .systemOrange.withAlphaComponent(0.7)
        grenadeButton.strokeColor = .white
        grenadeButton.lineWidth = 2
        grenadeButton.name = "grenade"
        addChild(grenadeButton)

        grenadeIcon.size = CGSize(width: 44, height: 44)
        grenadeIcon.position = CGPoint(x: 0, y: 4)
        grenadeIcon.zPosition = 1
        grenadeIcon.name = "grenade"
        grenadeButton.addChild(grenadeIcon)

        grenadeLabel.text = "×0"
        grenadeLabel.fontSize = 13
        grenadeLabel.fontColor = .white
        grenadeLabel.verticalAlignmentMode = .center
        grenadeLabel.horizontalAlignmentMode = .center
        grenadeLabel.position = CGPoint(x: 0, y: -22)
        grenadeLabel.zPosition = 2
        grenadeLabel.name = "grenade"
        grenadeButton.addChild(grenadeLabel)

        let invSize: CGFloat = 60
        inventoryButton.size = CGSize(width: invSize, height: invSize)
        inventoryButton.name = "inventory"
        addChild(inventoryButton)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func layout(in size: CGSize) {
        let topY = size.height/2 - 36
        let leftX = -size.width/2 + 16
        healthBar.position = CGPoint(x: -size.width/2 + 100, y: topY)
        healthFill.position = healthBar.position
        weaponLabel.position = CGPoint(x: leftX, y: topY - 28)

        // Stack of ammo counters under the weapon line
        let lineH: CGFloat = 18
        handgunAmmoLabel.position = CGPoint(x: leftX, y: topY - 28 - lineH)
        rifleAmmoLabel.position   = CGPoint(x: leftX, y: topY - 28 - lineH * 2)
        arrowAmmoLabel.position   = CGPoint(x: leftX, y: topY - 28 - lineH * 3)
        fireArrowLabel.position   = CGPoint(x: leftX, y: topY - 28 - lineH * 4)

        killsLabel.position  = CGPoint(x:  size.width/2 - 16, y: topY)
        pauseButton.position = CGPoint(x:  size.width/2 - 20, y: topY - 30)
        grenadeButton.position = CGPoint(x: size.width/2 - 70, y: -size.height/2 + 110)
        inventoryButton.position = CGPoint(x: -size.width/2 + 60, y: -size.height/2 + 60)
    }

    func setHealth(_ h: Int, max m: Int) {
        let pct = max(0, min(1, CGFloat(h) / CGFloat(m)))
        healthFill.xScale = pct
        healthFill.position.x = healthBar.position.x - barWidth/2 + (barWidth * pct)/2
        healthFill.fillColor = pct > 0.5 ? .systemGreen : (pct > 0.25 ? .systemYellow : .systemRed)
    }

    func setWeapon(_ w: WeaponKind, ammo: Int?) {
        activeWeapon = w
        weaponLabel.text = "▶ \(w.label.uppercased())"
        // Highlight the active weapon's row in the ammo stack via fontColor
        refreshActiveStyling()
    }

    private func refreshActiveStyling() {
        let active = UIColor.systemYellow
        let dim = UIColor.white.withAlphaComponent(0.55)
        handgunAmmoLabel.fontColor = activeWeapon == .handgun ? active : dim
        rifleAmmoLabel.fontColor   = activeWeapon == .rifle   ? active : dim
        // Bow shows on either arrow row
        let bowActive = activeWeapon == .bow
        arrowAmmoLabel.fontColor   = bowActive ? active : dim
        fireArrowLabel.fontColor   = bowActive ? .systemOrange : dim
    }

    /// Update all ammo counters at once.
    func setAmmoCounts(handgun: Int, rifle: Int, normalArrow: Int, fireArrow: Int) {
        handgunAmmoLabel.text = "HANDGUN ×\(handgun)"
        rifleAmmoLabel.text   = "RIFLE ×\(rifle)"
        arrowAmmoLabel.text   = "ARROW ×\(normalArrow)"
        fireArrowLabel.text   = "🔥 ARROW ×\(fireArrow)"
        refreshActiveStyling()
    }

    func setKills(_ killed: Int, of needed: Int) {
        killsLabel.text = "KILLS \(killed)"
    }

    func setSurvival(time: TimeInterval, kills: Int) {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        killsLabel.text = String(format: "TIME %d:%02d  KILLS %d", minutes, seconds, kills)
    }

    func setGrenades(_ count: Int) {
        grenadeLabel.text = "×\(count)"
        grenadeButton.alpha = count > 0 ? 1.0 : 0.4
    }

    func setFireArrowAmmo(_ count: Int) {
        // Kept for backward compat with existing call site; prefer setAmmoCounts.
        fireArrowLabel.text = "🔥 ARROW ×\(count)"
        refreshActiveStyling()
    }
}
