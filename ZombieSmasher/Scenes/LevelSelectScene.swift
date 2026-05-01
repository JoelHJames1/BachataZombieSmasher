import SpriteKit

final class LevelSelectScene: SKScene {

    private let totalLevels = 5
    private var buttons: [SKShapeNode] = []

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = .black
        scaleMode = .resizeFill
        buildBackground()
        buildTitle()
        buildLevelGrid()
        buildBackButton()
    }

    private func buildBackground() {
        let bg = SKSpriteNode(imageNamed: AssetCatalog.menuBackground)
        let scale = max(size.width / bg.size.width, size.height / bg.size.height)
        bg.setScale(scale)
        bg.zPosition = 0
        addChild(bg)
        let dim = SKSpriteNode(color: .black.withAlphaComponent(0.55), size: size)
        dim.zPosition = 1
        addChild(dim)
    }

    private func buildTitle() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "SELECT LEVEL"
        label.fontSize = 36
        label.fontColor = .systemRed
        label.position = CGPoint(x: 0, y: size.height * 0.36)
        label.zPosition = 10
        addChild(label)
    }

    private func buildLevelGrid() {
        let highest = SaveManager.highestUnlockedLevel
        let buttonSize = CGSize(width: 220, height: 90)
        let spacing: CGFloat = 16
        let totalH = CGFloat(totalLevels) * (buttonSize.height + spacing)
        var y = totalH / 2 - buttonSize.height / 2 - 40

        for i in 1...totalLevels {
            let unlocked = i <= highest
            let btn = SKShapeNode(rectOf: buttonSize, cornerRadius: 14)
            btn.fillColor = unlocked ? .systemRed : .darkGray
            btn.strokeColor = .white
            btn.lineWidth = 3
            btn.position = CGPoint(x: 0, y: y)
            btn.zPosition = 10
            btn.name = unlocked ? "level_\(i)" : "locked"
            addChild(btn)
            buttons.append(btn)

            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = unlocked ? "LEVEL \(i)" : "LEVEL \(i)  🔒"
            label.fontSize = 26
            label.fontColor = .white
            label.verticalAlignmentMode = .center
            label.position = .zero
            btn.addChild(label)

            y -= buttonSize.height + spacing
        }
    }

    private func buildBackButton() {
        let back = SKLabelNode(fontNamed: "AvenirNext-Bold")
        back.text = "← BACK"
        back.fontSize = 20
        back.fontColor = .white
        back.position = CGPoint(x: -size.width * 0.4, y: size.height * 0.43)
        back.zPosition = 10
        back.name = "back"
        addChild(back)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        let nodes = self.nodes(at: p)
        for node in nodes {
            guard let name = node.name else { continue }
            if name == "back" {
                let scene = MainMenuScene(size: size)
                scene.scaleMode = .resizeFill
                view?.presentScene(scene, transition: .crossFade(withDuration: 0.3))
                return
            }
            if name == "locked" { return }
            if name.hasPrefix("level_"), let lv = Int(name.dropFirst("level_".count)) {
                let v = view
                GameViewController.pendingTransition = { newSize in
                    guard let v else { return }
                    let scene = GameScene(size: newSize, level: lv)
                    scene.scaleMode = .resizeFill
                    v.presentScene(scene, transition: .fade(withDuration: 0.3))
                }
                GameViewController.requestOrientationUpdate(.landscape)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let cb = GameViewController.pendingTransition {
                        GameViewController.pendingTransition = nil
                        cb(v?.bounds.size ?? .zero)
                    }
                }
                return
            }
        }
    }
}
