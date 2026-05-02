import SpriteKit

final class MainMenuScene: SKScene {

    private var startButton: SKNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        buildBackground()
        buildLogo()
        buildStartButton()
        buildFooter()
    }

    private func buildBackground() {
        let bg = SKSpriteNode(imageNamed: AssetCatalog.menuBackground)
        bg.zPosition = 0
        let scale = max(size.width / bg.size.width, size.height / bg.size.height)
        bg.setScale(scale)
        bg.position = .zero
        addChild(bg)

        let dim = SKSpriteNode(color: .black.withAlphaComponent(0.15), size: size)
        dim.zPosition = 1
        addChild(dim)
    }

    private func buildLogo() {
        let frames = AssetCatalog.menuLogoFrames()
        let logo = SKSpriteNode(texture: frames.first)
        let maxH = size.height * 0.32
        logo.setScale(maxH / logo.size.height)
        logo.position = CGPoint(x: 0, y: -size.height * 0.02)
        logo.zPosition = 10
        addChild(logo)

        if !frames.isEmpty {
            logo.run(.repeatForever(.animate(with: frames, timePerFrame: 0.25)))
        }
    }

    private func buildStartButton() {
        let btnSize = CGSize(width: 160, height: 56)
        let container = SKNode()
        container.position = CGPoint(x: 0, y: -size.height * 0.20)
        container.zPosition = 10
        container.name = "start"
        addChild(container)

        let shadow = SKShapeNode(rectOf: btnSize, cornerRadius: 18)
        shadow.fillColor = .black.withAlphaComponent(0.45)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -4)
        shadow.zPosition = -1
        shadow.name = "start"
        container.addChild(shadow)

        let body = SKShapeNode(rectOf: btnSize, cornerRadius: 14)
        body.fillColor = .systemGreen
        body.strokeColor = .white
        body.lineWidth = 2.5
        body.name = "start"
        container.addChild(body)

        let highlight = SKShapeNode(
            rectOf: CGSize(width: btnSize.width - 14, height: btnSize.height / 2 - 6),
            cornerRadius: 10
        )
        highlight.fillColor = .white.withAlphaComponent(0.20)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 0, y: btnSize.height / 4)
        highlight.name = "start"
        container.addChild(highlight)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "START"
        label.fontSize = 22
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "start"
        container.addChild(label)

        startButton = container

        let pulse = SKAction.sequence([
            .scale(to: 1.04, duration: 0.7),
            .scale(to: 1.0, duration: 0.7)
        ])
        container.run(.repeatForever(pulse))
    }

    private func buildFooter() {
        let footer = SKLabelNode(fontNamed: "AvenirNext-Bold")
        footer.text = "v1.0  ·  TAP START TO PLAY"
        footer.fontSize = 14
        footer.fontColor = .white.withAlphaComponent(0.7)
        footer.position = CGPoint(x: 0, y: -size.height * 0.45)
        footer.zPosition = 10
        addChild(footer)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let p = touch.location(in: self)
        if startButton.contains(p) {
            startButton.run(.sequence([
                .scale(to: 0.92, duration: 0.05),
                .scale(to: 1.0, duration: 0.08),
                .run { [weak self] in self?.goToLevelSelect() }
            ]))
        }
    }

    private func goToLevelSelect() {
        // Survival mode: skip level selection, jump straight into the arena.
        let v = view
        GameViewController.pendingTransition = { newSize in
            guard let v else { return }
            let scene = GameScene(size: newSize, level: 1)
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
    }
}
