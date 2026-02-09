import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    
    var startingLevel: Int = 1
    private var viewModel: GameViewModel!
    private var skView: SKView!
    
    override func loadView() {
        skView = SKView()
        view = skView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        viewModel = GameViewModel(startLevel: startingLevel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if skView.scene == nil {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            scene.gameViewModel = viewModel
            scene.onExitToMenu = { [weak self] in
                self?.dismiss(animated: true)
            }
            skView.presentScene(scene)
            skView.ignoresSiblingOrder = true
            skView.showsFPS = false
            skView.showsNodeCount = false
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .portrait }
    
    override var prefersStatusBarHidden: Bool { true }
}
