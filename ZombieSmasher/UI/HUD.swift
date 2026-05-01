import SpriteKit

final class HUD: SKNode {

    private let healthBar: SKShapeNode
    private let healthFill: SKShapeNode
    private let weaponLabel: SKLabelNode
    private let killsLabel: SKLabelNode
    private let grenadeLabel: SKLabelNode

    let pauseButton: SKLabelNode
    let grenadeButton: SKShapeNode

    private let barWidth: CGFloat = 180
    private let barHeight: CGFloat = 14

    override init() {
        healthBar = SKShapeNode(rectOf: CGSize(width: 180, height: 14), cornerRadius: 4)
        healthFill = SKShapeNode(rectOf: CGSize(width: 180, height: 14), cornerRadius: 4)
        weaponLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        killsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        grenadeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        pauseButton = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        grenadeButton = SKShapeNode(circleOfRadius: 36)
        super.init()
        zPosition = 900

        healthBar.fillColor = .black.withAlphaComponent(0.45)
        healthBar.strokeColor = .white
        healthBar.lineWidth = 1.5
        addChild(healthBar)

        healthFill.fillColor = .systemGreen
        healthFill.strokeColor = .clear
        addChild(healthFill)

        weaponLabel.fontSize = 16
        weaponLabel.fontColor = .white
        weaponLabel.horizontalAlignmentMode = .left
        addChild(weaponLabel)

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
        grenadeLabel.text = "G x0"
        grenadeLabel.fontSize = 14
        grenadeLabel.fontColor = .white
        grenadeLabel.verticalAlignmentMode = .center
        grenadeLabel.name = "grenade"
        grenadeButton.addChild(grenadeLabel)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func layout(in size: CGSize) {
        let topY = size.height/2 - 36
        healthBar.position = CGPoint(x: -size.width/2 + 100, y: topY)
        healthFill.position = healthBar.position
        weaponLabel.position = CGPoint(x: -size.width/2 + 16, y: topY - 28)
        killsLabel.position  = CGPoint(x:  size.width/2 - 16, y: topY)
        pauseButton.position = CGPoint(x:  size.width/2 - 20, y: topY - 30)
        grenadeButton.position = CGPoint(x: size.width/2 - 70, y: -size.height/2 + 110)
    }

    func setHealth(_ h: Int, max m: Int) {
        let pct = max(0, min(1, CGFloat(h) / CGFloat(m)))
        healthFill.xScale = pct
        healthFill.position.x = healthBar.position.x - barWidth/2 + (barWidth * pct)/2
        healthFill.fillColor = pct > 0.5 ? .systemGreen : (pct > 0.25 ? .systemYellow : .systemRed)
    }

    func setWeapon(_ w: WeaponKind, ammo: Int?) {
        if let ammo {
            weaponLabel.text = "\(w.label.uppercased())  ×\(ammo)"
        } else {
            weaponLabel.text = "\(w.label.uppercased())  ∞"
        }
    }

    func setKills(_ killed: Int, of needed: Int) {
        killsLabel.text = "ZOMBIES \(killed)/\(needed)"
    }

    func setGrenades(_ count: Int) {
        grenadeLabel.text = "G x\(count)"
        grenadeButton.alpha = count > 0 ? 1.0 : 0.4
    }
}
