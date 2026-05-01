import SpriteKit

final class GameOverScene: SKScene {

    private let level: Int
    private let won: Bool
    private let kills: Int

    init(size: CGSize, level: Int, won: Bool, kills: Int) {
        self.level = level
        self.won = won
        self.kills = kills
        super.init(size: size)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        scaleMode = .resizeFill

        let bg = SKSpriteNode(imageNamed: AssetCatalog.menuBackground)
        let scale = max(size.width / bg.size.width, size.height / bg.size.height)
        bg.setScale(scale)
        bg.zPosition = 0
        addChild(bg)
        let dim = SKSpriteNode(color: .black.withAlphaComponent(0.6), size: size)
        dim.zPosition = 1
        addChild(dim)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = won ? "LEVEL \(level) CLEARED" : "YOU DIED"
        title.fontSize = 38
        title.fontColor = won ? .systemGreen : .systemRed
        title.position = CGPoint(x: 0, y: size.height * 0.25)
        title.zPosition = 10
        addChild(title)

        let stat = SKLabelNode(fontNamed: "AvenirNext-Bold")
        stat.text = "Kills: \(kills)"
        stat.fontSize = 22
        stat.fontColor = .white
        stat.position = CGPoint(x: 0, y: size.height * 0.12)
        stat.zPosition = 10
        addChild(stat)

        addButton(text: won ? "NEXT LEVEL" : "RETRY", y: -size.height * 0.05, name: "again", color: .systemRed)
        addButton(text: "MAIN MENU", y: -size.height * 0.18, name: "menu", color: .darkGray)
    }

    private func addButton(text: String, y: CGFloat, name: String, color: UIColor) {
        let btn = SKShapeNode(rectOf: CGSize(width: 240, height: 70), cornerRadius: 14)
        btn.fillColor = color
        btn.strokeColor = .white
        btn.lineWidth = 3
        btn.position = CGPoint(x: 0, y: y)
        btn.name = name
        btn.zPosition = 10
        addChild(btn)
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        btn.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        for node in nodes(at: p) {
            switch node.name {
            case "again":
                let next = (won && level < 5) ? level + 1 : level
                let scene = GameScene(size: size, level: next)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .fade(withDuration: 0.4))
                return
            case "menu":
                let v = view
                GameViewController.pendingTransition = { newSize in
                    guard let v else { return }
                    let scene = MainMenuScene(size: newSize)
                    scene.scaleMode = .resizeFill
                    v.presentScene(scene, transition: .crossFade(withDuration: 0.3))
                }
                GameViewController.requestOrientationUpdate(.portrait)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let cb = GameViewController.pendingTransition {
                        GameViewController.pendingTransition = nil
                        cb(v?.bounds.size ?? .zero)
                    }
                }
                return
            default: break
            }
        }
    }
}
