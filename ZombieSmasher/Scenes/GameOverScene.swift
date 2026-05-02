import SpriteKit

final class GameOverScene: SKScene {

    private let level: Int
    private let won: Bool
    private let kills: Int
    private let survivalTime: TimeInterval

    init(size: CGSize, level: Int, won: Bool, kills: Int, survivalTime: TimeInterval = 0) {
        self.level = level
        self.won = won
        self.kills = kills
        self.survivalTime = survivalTime
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
        title.text = "YOU DIED"
        title.fontSize = 40
        title.fontColor = .systemRed
        title.position = CGPoint(x: 0, y: size.height * 0.28)
        title.zPosition = 10
        addChild(title)

        let minutes = Int(survivalTime) / 60
        let seconds = Int(survivalTime) % 60
        let timeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        timeLabel.text = String(format: "Survived  %d:%02d", minutes, seconds)
        timeLabel.fontSize = 26
        timeLabel.fontColor = .white
        timeLabel.position = CGPoint(x: 0, y: size.height * 0.16)
        timeLabel.zPosition = 10
        addChild(timeLabel)

        let killsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        killsLabel.text = "Kills  \(kills)"
        killsLabel.fontSize = 22
        killsLabel.fontColor = .white
        killsLabel.position = CGPoint(x: 0, y: size.height * 0.08)
        killsLabel.zPosition = 10
        addChild(killsLabel)

        // Best stats
        let bestMin = Int(SaveManager.bestSurvivalTime) / 60
        let bestSec = Int(SaveManager.bestSurvivalTime) % 60
        let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bestLabel.text = String(format: "Best  %d:%02d  ·  %d kills",
                                bestMin, bestSec, SaveManager.bestSurvivalKills)
        bestLabel.fontSize = 16
        bestLabel.fontColor = .systemYellow
        bestLabel.position = CGPoint(x: 0, y: size.height * 0.01)
        bestLabel.zPosition = 10
        addChild(bestLabel)

        addButton(text: "RETRY",     y: -size.height * 0.10, name: "again", color: .systemRed)
        addButton(text: "MAIN MENU", y: -size.height * 0.32, name: "menu",  color: .darkGray)
    }

    private func addButton(text: String, y: CGFloat, name: String, color: UIColor) {
        let btn = SKShapeNode(rectOf: CGSize(width: 240, height: 64), cornerRadius: 14)
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
        label.name = name
        btn.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        for node in nodes(at: p) {
            switch node.name {
            case "again":
                let scene = GameScene(size: size, level: level)
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
