import UIKit
import SpriteKit

class GameViewController: UIViewController {

    static weak var current: GameViewController?
    static var preferredOrientations: UIInterfaceOrientationMask = .portrait
    static var pendingTransition: ((CGSize) -> Void)?

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            if let cb = Self.pendingTransition {
                Self.pendingTransition = nil
                cb(size)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Self.current = self

        guard let skView = view as? SKView else { return }

        let scene = MainMenuScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false
        AssetCatalog.preloadAll()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        Self.preferredOrientations
    }

    override var prefersStatusBarHidden: Bool { true }

    static func requestOrientationUpdate(_ mask: UIInterfaceOrientationMask) {
        preferredOrientations = mask
        guard let vc = current else { return }
        if #available(iOS 16.0, *) {
            vc.setNeedsUpdateOfSupportedInterfaceOrientations()
            DispatchQueue.main.async {
                let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                for scene in scenes {
                    let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
                    scene.requestGeometryUpdate(pref) { _ in }
                }
            }
        } else {
            let value: Int
            if mask.contains(.landscape) {
                value = UIInterfaceOrientation.landscapeRight.rawValue
            } else {
                value = UIInterfaceOrientation.portrait.rawValue
            }
            UIDevice.current.setValue(value, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
