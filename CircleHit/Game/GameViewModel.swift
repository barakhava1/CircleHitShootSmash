import Foundation
import Combine
import CoreGraphics
import UIKit

struct GameState {
    var ballsRemaining: Int
    var circles: [CircleState]
    var projectiles: [ProjectileState]
    var gameOver: Bool
    var win: Bool
    var level: Int
    var timeRemaining: TimeInterval
    var maxTime: TimeInterval
    var stars: Int
}

struct CircleState: Identifiable {
    let id: String
    var position: CGPoint
    var radius: CGFloat
    var lives: Int
    var velocity: CGVector
}

struct ProjectileState: Identifiable {
    let id: String
    var position: CGPoint
    var velocity: CGVector
}

final class GameViewModel: ObservableObject {
    static let baseBalls = 3
    static let circleRadius: CGFloat = 28
    static let projectileRadius: CGFloat = 12
    static let baseTime: TimeInterval = 60
    
    @Published private(set) var state: GameState
    private var projectileCounter = 0
    private let initialLevel: Int
    
    init(startLevel: Int = 1) {
        initialLevel = startLevel
        state = GameState(
            ballsRemaining: Self.baseBalls,
            circles: [],
            projectiles: [],
            gameOver: false,
            win: false,
            level: startLevel,
            timeRemaining: Self.baseTime,
            maxTime: Self.baseTime,
            stars: 0
        )
    }
    
    func setupLevel(bounds: CGRect) {
        generateLevel(bounds: bounds, level: state.level)
    }
    
    private func generateLevel(bounds: CGRect, level: Int) {
        var circles: [CircleState] = []
        let cols = min(3 + level / 3, 5)
        let rows = min(2 + level / 3, 4)
        let padding: CGFloat = 50
        let circleSize = Self.circleRadius * 2
        let availableWidth = bounds.width - padding * 2
        let spacingX = max((availableWidth - CGFloat(cols) * circleSize) / CGFloat(max(cols - 1, 1)), 10)
        let spacingY: CGFloat = 70
        let topY = bounds.height - 180
        
        for row in 0..<rows {
            for col in 0..<cols {
                let x = padding + Self.circleRadius + CGFloat(col) * (circleSize + spacingX)
                let y = topY - CGFloat(row) * spacingY
                let id = "c\(row)-\(col)"
                var lives = 1
                if level >= 3 {
                    lives = 1 + (row + col) % 2
                }
                if level >= 6 {
                    lives = 1 + (row + col + level) % 3
                }
                if level >= 10 {
                    lives = 2 + (row + col) % 2
                }
                var velocity = CGVector.zero
                if level >= 2 && (row + col).isMultiple(of: 3) {
                    let speed: CGFloat = CGFloat(25 + level * 6)
                    velocity = CGVector(dx: (col.isMultiple(of: 2) ? speed : -speed), dy: 0)
                }
                circles.append(CircleState(
                    id: id,
                    position: CGPoint(x: x, y: y),
                    radius: Self.circleRadius,
                    lives: lives,
                    velocity: velocity
                ))
            }
        }
        
        let totalBalls = Self.baseBalls + level / 2
        let levelTime = Self.baseTime + TimeInterval(level * 5)
        
        state = GameState(
            ballsRemaining: totalBalls,
            circles: circles,
            projectiles: [],
            gameOver: false,
            win: false,
            level: level,
            timeRemaining: levelTime,
            maxTime: levelTime,
            stars: 0
        )
        projectileCounter = 0
    }
    
    func shoot(from start: CGPoint, direction: CGVector) -> ProjectileState? {
        guard state.ballsRemaining > 0, !state.gameOver else { return nil }
        state.ballsRemaining -= 1
        let speed: CGFloat = 700
        let len = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)
        guard len > 5 else {
            state.ballsRemaining += 1
            return nil
        }
        let dx = (direction.dx / len) * speed
        let dy = (direction.dy / len) * speed
        projectileCounter += 1
        let proj = ProjectileState(
            id: "p\(projectileCounter)",
            position: start,
            velocity: CGVector(dx: dx, dy: dy)
        )
        state.projectiles.append(proj)
        return proj
    }
    
    func updateProjectile(id: String, position: CGPoint, velocity: CGVector) {
        guard let idx = state.projectiles.firstIndex(where: { $0.id == id }) else { return }
        state.projectiles[idx].position = position
        state.projectiles[idx].velocity = velocity
    }
    
    func removeProjectile(id: String) {
        state.projectiles.removeAll { $0.id == id }
    }
    
    func hitCircle(id: String) {
        guard let idx = state.circles.firstIndex(where: { $0.id == id }) else { return }
        state.circles[idx].lives -= 1
        if state.circles[idx].lives <= 0 {
            state.circles.remove(at: idx)
        }
    }
    
    func updateCircle(id: String, position: CGPoint, velocity: CGVector) {
        guard let idx = state.circles.firstIndex(where: { $0.id == id }) else { return }
        state.circles[idx].position = position
        state.circles[idx].velocity = velocity
    }
    
    func updateTime(delta: TimeInterval) {
        guard !state.gameOver else { return }
        state.timeRemaining = max(0, state.timeRemaining - delta)
        if state.timeRemaining <= 0 && !state.circles.isEmpty {
            state.gameOver = true
            state.win = false
            state.stars = 0
        }
    }
    
    func checkGameOver() {
        guard !state.gameOver else { return }
        if state.circles.isEmpty {
            state.win = true
            state.gameOver = true
            let timeRatio = state.timeRemaining / state.maxTime
            if timeRatio > 0.6 {
                state.stars = 3
            } else if timeRatio > 0.3 {
                state.stars = 2
            } else if timeRatio > 0 {
                state.stars = 1
            } else {
                state.stars = 0
            }
            return
        }
        if state.ballsRemaining <= 0 && state.projectiles.isEmpty {
            state.gameOver = true
            state.win = false
            state.stars = 0
        }
    }
    
    func nextLevel(bounds: CGRect) {
        let nextLvl = state.level + 1
        generateLevel(bounds: bounds, level: nextLvl)
    }
    
    func restart(bounds: CGRect) {
        generateLevel(bounds: bounds, level: initialLevel)
    }
    
    func retryLevel(bounds: CGRect) {
        generateLevel(bounds: bounds, level: state.level)
    }
}
