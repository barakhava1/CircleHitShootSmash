import SpriteKit
import GameplayKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    
    weak var gameViewModel: GameViewModel?
    var onExitToMenu: (() -> Void)?
    
    private var projectileNodes: [String: SKShapeNode] = [:]
    private var circleNodes: [String: SKShapeNode] = [:]
    private var borderNodes: [SKNode] = []
    private var aimLine: SKShapeNode?
    private var touchStart: CGPoint?
    private var cannonNode: SKShapeNode?
    private var aimIndicator: SKShapeNode?
    private var lastUpdateTime: TimeInterval = 0
    private var isGamePaused = false
    
    private let categoryProjectile: UInt32 = 1 << 0
    private let categoryCircle: UInt32 = 1 << 1
    private let categoryBorder: UInt32 = 1 << 2
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        guard let vm = gameViewModel else { return }
        vm.setupLevel(bounds: frame)
        addBorders()
        addCannon()
        syncCirclesFromViewModel()
        addHUD()
        addDecorations()
    }
    
    private func addDecorations() {
        for _ in 0..<15 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2))
            star.fillColor = SKColor(white: 1, alpha: CGFloat.random(in: 0.1...0.3))
            star.strokeColor = .clear
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: size.height * 0.5...size.height))
            star.zPosition = -50
            addChild(star)
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: Double.random(in: 2...4)),
                SKAction.fadeAlpha(to: 0.3, duration: Double.random(in: 2...4))
            ])
            star.run(SKAction.repeatForever(pulse))
        }
    }
    
    private func addCannon() {
        let cannonBase = SKShapeNode(rectOf: CGSize(width: 80, height: 16), cornerRadius: 8)
        cannonBase.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)
        cannonBase.strokeColor = SKColor(red: 0.35, green: 0.35, blue: 0.45, alpha: 1)
        cannonBase.lineWidth = 2
        cannonBase.position = CGPoint(x: size.width / 2, y: 35)
        cannonBase.zPosition = 5
        addChild(cannonBase)
        
        cannonNode = SKShapeNode(circleOfRadius: 22)
        cannonNode?.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        cannonNode?.strokeColor = SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 1)
        cannonNode?.lineWidth = 2
        cannonNode?.position = CGPoint(x: size.width / 2, y: 55)
        cannonNode?.zPosition = 6
        if let cannon = cannonNode {
            addChild(cannon)
        }
    }
    
    private func addBorders() {
        let thickness: CGFloat = 20
        
        let left = SKNode()
        left.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: thickness, height: size.height + 100))
        left.physicsBody?.isDynamic = false
        left.physicsBody?.categoryBitMask = categoryBorder
        left.physicsBody?.restitution = 1
        left.physicsBody?.friction = 0
        left.position = CGPoint(x: -thickness / 2, y: size.height / 2)
        addChild(left)
        borderNodes.append(left)
        
        let right = SKNode()
        right.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: thickness, height: size.height + 100))
        right.physicsBody?.isDynamic = false
        right.physicsBody?.categoryBitMask = categoryBorder
        right.physicsBody?.restitution = 1
        right.physicsBody?.friction = 0
        right.position = CGPoint(x: size.width + thickness / 2, y: size.height / 2)
        addChild(right)
        borderNodes.append(right)
        
        let top = SKNode()
        top.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width + 100, height: thickness))
        top.physicsBody?.isDynamic = false
        top.physicsBody?.categoryBitMask = categoryBorder
        top.physicsBody?.restitution = 1
        top.physicsBody?.friction = 0
        top.position = CGPoint(x: size.width / 2, y: size.height + thickness / 2)
        addChild(top)
        borderNodes.append(top)
        
        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: size.width + 100, height: thickness))
        bottom.physicsBody?.isDynamic = false
        bottom.physicsBody?.categoryBitMask = categoryBorder
        bottom.physicsBody?.restitution = 1
        bottom.physicsBody?.friction = 0
        bottom.position = CGPoint(x: size.width / 2, y: -thickness / 2)
        addChild(bottom)
        borderNodes.append(bottom)
    }
    
    private func syncCirclesFromViewModel() {
        guard let vm = gameViewModel else { return }
        let idsToRemove = circleNodes.keys.filter { id in vm.state.circles.first(where: { $0.id == id }) == nil }
        for id in idsToRemove {
            if let node = circleNodes[id] {
                addHitEffect(at: node.position)
            }
            circleNodes[id]?.removeFromParent()
            circleNodes.removeValue(forKey: id)
        }
        for circle in vm.state.circles {
            if circleNodes[circle.id] == nil {
                let node = makeCircleNode(radius: circle.radius, lives: circle.lives)
                node.name = circle.id
                node.position = circle.position
                node.physicsBody = SKPhysicsBody(circleOfRadius: circle.radius)
                node.physicsBody?.isDynamic = true
                node.physicsBody?.categoryBitMask = categoryCircle
                node.physicsBody?.contactTestBitMask = categoryProjectile
                node.physicsBody?.collisionBitMask = categoryProjectile | categoryBorder | categoryCircle
                node.physicsBody?.restitution = 0.9
                node.physicsBody?.friction = 0
                node.physicsBody?.linearDamping = 0
                node.physicsBody?.velocity = CGVector(dx: circle.velocity.dx, dy: circle.velocity.dy)
                addChild(node)
                circleNodes[circle.id] = node
            } else {
                if let n = circleNodes[circle.id] {
                    updateCircleAppearance(node: n, lives: circle.lives)
                }
            }
        }
    }
    
    private func makeCircleNode(radius: CGFloat, lives: Int) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.zPosition = 20
        updateCircleAppearance(node: node, lives: lives)
        let label = SKLabelNode(text: "\(lives)")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = radius * 0.85
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "lives"
        label.zPosition = 21
        node.addChild(label)
        return node
    }
    
    private func updateCircleAppearance(node: SKShapeNode, lives: Int) {
        let colors: [(fill: SKColor, stroke: SKColor)] = [
            (SKColor(red: 0.95, green: 0.55, blue: 0.2, alpha: 1), SKColor(red: 1, green: 0.7, blue: 0.35, alpha: 1)),
            (SKColor(red: 0.85, green: 0.3, blue: 0.25, alpha: 1), SKColor(red: 1, green: 0.45, blue: 0.35, alpha: 1)),
            (SKColor(red: 0.6, green: 0.25, blue: 0.55, alpha: 1), SKColor(red: 0.8, green: 0.4, blue: 0.7, alpha: 1))
        ]
        let colorIndex = min(lives - 1, colors.count - 1)
        let color = colors[max(0, colorIndex)]
        node.fillColor = color.fill
        node.strokeColor = color.stroke
        node.lineWidth = 3
        (node.childNode(withName: "lives") as? SKLabelNode)?.text = "\(lives)"
    }
    
    private func addHitEffect(at position: CGPoint) {
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            particle.fillColor = SKColor(red: 1, green: CGFloat.random(in: 0.5...0.8), blue: 0.2, alpha: 1)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 50
            addChild(particle)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let distance = CGFloat.random(in: 40...100)
            let move = SKAction.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.35)
            let fade = SKAction.fadeOut(withDuration: 0.35)
            particle.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }
    
    private func addHUD() {
        guard let vm = gameViewModel else { return }
        
        let hudBg = SKShapeNode(rectOf: CGSize(width: 100, height: 40), cornerRadius: 20)
        hudBg.fillColor = SKColor(white: 0, alpha: 0.5)
        hudBg.strokeColor = SKColor(white: 1, alpha: 0.2)
        hudBg.lineWidth = 1
        hudBg.position = CGPoint(x: 70, y: size.height - 55)
        hudBg.zPosition = 100
        hudBg.name = "hudBg"
        addChild(hudBg)
        
        let ballIcon = SKShapeNode(circleOfRadius: 8)
        ballIcon.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        ballIcon.strokeColor = .clear
        ballIcon.position = CGPoint(x: -25, y: 0)
        hudBg.addChild(ballIcon)
        
        let ballsLabel = SKLabelNode(text: "x\(vm.state.ballsRemaining)")
        ballsLabel.name = "ballsLabel"
        ballsLabel.fontName = "AvenirNext-Bold"
        ballsLabel.fontSize = 18
        ballsLabel.fontColor = .white
        ballsLabel.verticalAlignmentMode = .center
        ballsLabel.horizontalAlignmentMode = .left
        ballsLabel.position = CGPoint(x: -10, y: 0)
        hudBg.addChild(ballsLabel)
        
        let timerBg = SKShapeNode(rectOf: CGSize(width: 80, height: 40), cornerRadius: 20)
        timerBg.fillColor = SKColor(white: 0, alpha: 0.5)
        timerBg.strokeColor = SKColor(white: 1, alpha: 0.2)
        timerBg.lineWidth = 1
        timerBg.position = CGPoint(x: size.width - 60, y: size.height - 55)
        timerBg.zPosition = 100
        timerBg.name = "timerBg"
        addChild(timerBg)
        
        let timerLabel = SKLabelNode(text: formatTime(vm.state.timeRemaining))
        timerLabel.name = "timerLabel"
        timerLabel.fontName = "AvenirNext-Bold"
        timerLabel.fontSize = 18
        timerLabel.fontColor = .white
        timerLabel.verticalAlignmentMode = .center
        timerLabel.position = CGPoint(x: 0, y: 0)
        timerBg.addChild(timerLabel)
        
        let levelLabel = SKLabelNode(text: "Level \(vm.state.level)")
        levelLabel.name = "levelLabel"
        levelLabel.fontName = "AvenirNext-DemiBold"
        levelLabel.fontSize = 16
        levelLabel.fontColor = SKColor(white: 1, alpha: 0.6)
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 55)
        levelLabel.zPosition = 100
        addChild(levelLabel)
        
        let pauseButton = SKShapeNode(circleOfRadius: 18)
        pauseButton.fillColor = SKColor(white: 0, alpha: 0.5)
        pauseButton.strokeColor = SKColor(white: 1, alpha: 0.3)
        pauseButton.lineWidth = 1
        pauseButton.position = CGPoint(x: size.width / 2, y: size.height - 90)
        pauseButton.zPosition = 100
        pauseButton.name = "pauseButton"
        addChild(pauseButton)
        
        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.fontSize = 16
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.horizontalAlignmentMode = .center
        pauseIcon.position = CGPoint(x: 0, y: 0)
        pauseButton.addChild(pauseIcon)
    }
    
    private func showPauseMenu() {
        isGamePaused = true
        physicsWorld.speed = 0
        
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.name = "pauseOverlay"
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(white: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.zPosition = 300
        addChild(overlay)
        
        let panel = SKShapeNode(rectOf: CGSize(width: 260, height: 220), cornerRadius: 20)
        panel.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        panel.strokeColor = SKColor(white: 0.3, alpha: 1)
        panel.lineWidth = 2
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition = 301
        panel.name = "pausePanel"
        addChild(panel)
        
        let title = SKLabelNode(text: "Paused")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 60)
        title.zPosition = 302
        panel.addChild(title)
        
        let resumeButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        resumeButton.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        resumeButton.strokeColor = .clear
        resumeButton.position = CGPoint(x: 0, y: 0)
        resumeButton.zPosition = 302
        resumeButton.name = "resumeButton"
        panel.addChild(resumeButton)
        
        let resumeLabel = SKLabelNode(text: "Resume")
        resumeLabel.fontName = "AvenirNext-Bold"
        resumeLabel.fontSize = 20
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeButton.addChild(resumeLabel)
        
        let exitButton = SKShapeNode(rectOf: CGSize(width: 180, height: 50), cornerRadius: 25)
        exitButton.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.25, alpha: 1)
        exitButton.strokeColor = .clear
        exitButton.position = CGPoint(x: 0, y: -65)
        exitButton.zPosition = 302
        exitButton.name = "exitButton"
        panel.addChild(exitButton)
        
        let exitLabel = SKLabelNode(text: "Exit to Menu")
        exitLabel.fontName = "AvenirNext-Bold"
        exitLabel.fontSize = 18
        exitLabel.fontColor = .white
        exitLabel.verticalAlignmentMode = .center
        exitButton.addChild(exitLabel)
        
        panel.setScale(0.5)
        panel.alpha = 0
        let appear = SKAction.group([
            SKAction.scale(to: 1, duration: 0.2),
            SKAction.fadeIn(withDuration: 0.2)
        ])
        panel.run(appear)
    }
    
    private func hidePauseMenu() {
        isGamePaused = false
        childNode(withName: "pauseOverlay")?.removeFromParent()
        childNode(withName: "pausePanel")?.removeFromParent()
        physicsWorld.speed = 1
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func updateHUD() {
        guard let vm = gameViewModel else { return }
        if let hudBg = childNode(withName: "hudBg"), let label = hudBg.childNode(withName: "ballsLabel") as? SKLabelNode {
            label.text = "x\(vm.state.ballsRemaining)"
        }
        if let timerBg = childNode(withName: "timerBg"), let label = timerBg.childNode(withName: "timerLabel") as? SKLabelNode {
            label.text = formatTime(vm.state.timeRemaining)
            label.fontColor = vm.state.timeRemaining < 10 ? SKColor(red: 1, green: 0.3, blue: 0.3, alpha: 1) : .white
        }
        if let levelLabel = childNode(withName: "levelLabel") as? SKLabelNode {
            levelLabel.text = "Level \(vm.state.level)"
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let vm = gameViewModel, !isGamePaused else {
            lastUpdateTime = currentTime
            return
        }
        
        if lastUpdateTime > 0 {
            let delta = currentTime - lastUpdateTime
            vm.updateTime(delta: delta)
        }
        lastUpdateTime = currentTime
        
        for (id, node) in projectileNodes {
            if let body = node.physicsBody {
                vm.updateProjectile(id: id, position: node.position, velocity: body.velocity)
            }
        }
        
        for (id, node) in circleNodes {
            guard let body = node.physicsBody else { continue }
            vm.updateCircle(id: id, position: node.position, velocity: body.velocity)
        }
        
        syncCirclesFromViewModel()
        syncProjectilesFromViewModel()
        updateHUD()
        
        vm.checkGameOver()
        
        if vm.state.gameOver, childNode(withName: "gameOverOverlay") == nil {
            let timeUsed = vm.state.maxTime - vm.state.timeRemaining
            StorageService.shared.saveLevelStats(
                level: vm.state.level,
                stars: vm.state.stars,
                time: timeUsed,
                won: vm.state.win
            )
            showGameOver(won: vm.state.win, stars: vm.state.stars)
        }
    }
    
    private func syncProjectilesFromViewModel() {
        guard let vm = gameViewModel else { return }
        let idsToRemove = projectileNodes.keys.filter { id in
            guard let proj = vm.state.projectiles.first(where: { $0.id == id }) else { return true }
            let pos = proj.position
            return pos.y < -50 || pos.y > size.height + 50 || pos.x < -50 || pos.x > size.width + 50
        }
        for id in idsToRemove {
            projectileNodes[id]?.removeFromParent()
            projectileNodes.removeValue(forKey: id)
            vm.removeProjectile(id: id)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA = contact.bodyA
        let bodyB = contact.bodyB
        var circleNode: SKNode?
        if bodyA.categoryBitMask == categoryCircle && bodyB.categoryBitMask == categoryProjectile {
            circleNode = bodyA.node
        } else if bodyB.categoryBitMask == categoryCircle && bodyA.categoryBitMask == categoryProjectile {
            circleNode = bodyB.node
        }
        guard let circle = circleNode, let circleName = circle.name else { return }
        addSmallHitEffect(at: contact.contactPoint)
        gameViewModel?.hitCircle(id: circleName)
    }
    
    private func addSmallHitEffect(at position: CGPoint) {
        for _ in 0..<5 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            spark.fillColor = SKColor(white: 1, alpha: 0.9)
            spark.strokeColor = .clear
            spark.position = position
            spark.zPosition = 60
            addChild(spark)
            let angle = CGFloat.random(in: 0...(CGFloat.pi * 2))
            let dist = CGFloat.random(in: 15...35)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.15)
            let fade = SKAction.fadeOut(withDuration: 0.15)
            spark.run(SKAction.sequence([SKAction.group([move, fade]), SKAction.removeFromParent()]))
        }
    }
    
    func launchProjectile(from start: CGPoint, velocity: CGVector) {
        guard let vm = gameViewModel else { return }
        guard let projState = vm.shoot(from: start, direction: velocity) else { return }
        
        let node = SKShapeNode(circleOfRadius: GameViewModel.projectileRadius)
        node.name = projState.id
        node.position = projState.position
        node.strokeColor = SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 1)
        node.lineWidth = 2
        node.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 1)
        node.zPosition = 30
        node.physicsBody = SKPhysicsBody(circleOfRadius: GameViewModel.projectileRadius)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.categoryBitMask = categoryProjectile
        node.physicsBody?.contactTestBitMask = categoryCircle
        node.physicsBody?.collisionBitMask = categoryCircle | categoryBorder
        node.physicsBody?.restitution = 1
        node.physicsBody?.friction = 0
        node.physicsBody?.linearDamping = 0
        node.physicsBody?.velocity = projState.velocity
        node.physicsBody?.usesPreciseCollisionDetection = true
        addChild(node)
        projectileNodes[projState.id] = node
    }
    
    private func showGameOver(won: Bool, stars: Int) {
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.name = "gameOverOverlay"
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.fillColor = SKColor(white: 0, alpha: 0.75)
        overlay.strokeColor = .clear
        overlay.zPosition = 200
        addChild(overlay)
        
        let panel = SKShapeNode(rectOf: CGSize(width: 280, height: 260), cornerRadius: 20)
        panel.fillColor = SKColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
        panel.strokeColor = won ? SKColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1) : SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1)
        panel.lineWidth = 3
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.zPosition = 201
        panel.name = "panel"
        addChild(panel)
        
        let text = SKLabelNode(text: won ? "Level Complete!" : "Time's Up!")
        text.fontName = "AvenirNext-Bold"
        text.fontSize = 28
        text.fontColor = won ? SKColor(red: 0.3, green: 0.85, blue: 0.4, alpha: 1) : SKColor(red: 0.9, green: 0.4, blue: 0.3, alpha: 1)
        text.position = CGPoint(x: 0, y: 75)
        text.zPosition = 202
        panel.addChild(text)
        
        if won {
            let starsContainer = SKNode()
            starsContainer.position = CGPoint(x: 0, y: 25)
            starsContainer.zPosition = 202
            panel.addChild(starsContainer)
            for i in 0..<3 {
                let starNode = SKLabelNode(text: i < stars ? "★" : "☆")
                starNode.fontName = "AvenirNext-Bold"
                starNode.fontSize = 36
                starNode.fontColor = i < stars ? SKColor(red: 1, green: 0.85, blue: 0.2, alpha: 1) : SKColor(white: 0.4, alpha: 1)
                starNode.position = CGPoint(x: CGFloat(i - 1) * 50, y: 0)
                starNode.verticalAlignmentMode = .center
                starsContainer.addChild(starNode)
            }
        }
        
        if let vm = gameViewModel {
            let levelText = SKLabelNode(text: "Level \(vm.state.level)")
            levelText.fontName = "AvenirNext-DemiBold"
            levelText.fontSize = 18
            levelText.fontColor = SKColor(white: 0.6, alpha: 1)
            levelText.position = CGPoint(x: 0, y: won ? -20 : 20)
            levelText.zPosition = 202
            panel.addChild(levelText)
        }
        
        let sub = SKLabelNode(text: won ? "Tap for next level" : "Tap to retry")
        sub.fontName = "AvenirNext-Medium"
        sub.fontSize = 16
        sub.fontColor = SKColor(white: 0.7, alpha: 1)
        sub.position = CGPoint(x: 0, y: won ? -55 : -25)
        sub.zPosition = 202
        panel.addChild(sub)
        
        panel.setScale(0.5)
        panel.alpha = 0
        let appear = SKAction.group([
            SKAction.scale(to: 1, duration: 0.25),
            SKAction.fadeIn(withDuration: 0.25)
        ])
        panel.run(appear)
    }
    
    private func clearLevel() {
        children.filter { $0.zPosition >= 200 }.forEach { $0.removeFromParent() }
        for (_, node) in projectileNodes {
            node.removeFromParent()
        }
        projectileNodes.removeAll()
        for (_, node) in circleNodes {
            node.removeFromParent()
        }
        circleNodes.removeAll()
        lastUpdateTime = 0
    }
    
    func restart() {
        clearLevel()
        gameViewModel?.restart(bounds: frame)
        syncCirclesFromViewModel()
        updateHUD()
    }
    
    func nextLevel() {
        clearLevel()
        gameViewModel?.nextLevel(bounds: frame)
        syncCirclesFromViewModel()
        updateHUD()
    }
    
    func retryLevel() {
        clearLevel()
        gameViewModel?.retryLevel(bounds: frame)
        syncCirclesFromViewModel()
        updateHUD()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        
        if isGamePaused {
            if let panel = childNode(withName: "pausePanel") {
                let panelLoc = touch.location(in: panel)
                if let resumeBtn = panel.childNode(withName: "resumeButton"), resumeBtn.contains(panelLoc) {
                    hidePauseMenu()
                    return
                }
                if let exitBtn = panel.childNode(withName: "exitButton"), exitBtn.contains(panelLoc) {
                    hidePauseMenu()
                    onExitToMenu?()
                    return
                }
            }
            return
        }
        
        if let pauseBtn = childNode(withName: "pauseButton"), pauseBtn.contains(loc) {
            showPauseMenu()
            return
        }
        
        guard let vm = gameViewModel, !vm.state.gameOver else {
            if let vm = gameViewModel, vm.state.gameOver {
                if vm.state.win {
                    nextLevel()
                } else {
                    retryLevel()
                }
            }
            return
        }
        
        if vm.state.ballsRemaining > 0 {
            touchStart = CGPoint(x: size.width / 2, y: 55)
            aimLine?.removeFromParent()
            aimLine = SKShapeNode()
            aimLine?.strokeColor = SKColor(white: 1, alpha: 0.4)
            aimLine?.lineWidth = 2
            aimLine?.zPosition = 50
            if let line = aimLine {
                addChild(line)
            }
            aimIndicator?.removeFromParent()
            aimIndicator = SKShapeNode(circleOfRadius: 12)
            aimIndicator?.fillColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 0.4)
            aimIndicator?.strokeColor = SKColor(red: 0.3, green: 0.7, blue: 0.95, alpha: 0.7)
            aimIndicator?.lineWidth = 2
            aimIndicator?.position = loc
            aimIndicator?.zPosition = 51
            if let indicator = aimIndicator {
                addChild(indicator)
            }
            updateAimLine(to: loc)
        }
    }
    
    private func updateAimLine(to loc: CGPoint) {
        guard let start = touchStart else { return }
        let dx = loc.x - start.x
        let dy = loc.y - start.y
        let len = sqrt(dx * dx + dy * dy)
        if len > 10 {
            let normX = dx / len
            let normY = dy / len
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: CGPoint(x: start.x + normX * 120, y: start.y + normY * 120))
            let dashPattern: [CGFloat] = [8, 4]
            aimLine?.path = path.copy(dashingWithPhase: 0, lengths: dashPattern)
        } else {
            aimLine?.path = nil
        }
        aimIndicator?.position = loc
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touchStart != nil, let vm = gameViewModel, !vm.state.gameOver else { return }
        updateAimLine(to: touch.location(in: self))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        if let vm = gameViewModel, vm.state.gameOver {
            if vm.state.win {
                nextLevel()
            } else {
                retryLevel()
            }
            return
        }
        guard let start = touchStart, let vm = gameViewModel, vm.state.ballsRemaining > 0 else {
            touchStart = nil
            aimLine?.removeFromParent()
            aimLine = nil
            aimIndicator?.removeFromParent()
            aimIndicator = nil
            return
        }
        let dx = loc.x - start.x
        let dy = loc.y - start.y
        aimLine?.removeFromParent()
        aimLine = nil
        aimIndicator?.removeFromParent()
        aimIndicator = nil
        touchStart = nil
        launchProjectile(from: start, velocity: CGVector(dx: dx, dy: dy))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = nil
        aimLine?.removeFromParent()
        aimLine = nil
        aimIndicator?.removeFromParent()
        aimIndicator = nil
    }
}
