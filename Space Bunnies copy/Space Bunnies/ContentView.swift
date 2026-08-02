//
//  ContentView.swift
//  Space Bunnies
//
//  Created by Elliot Williams on 2025-06-22.
//

import SwiftUI
import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game state
    var gameOver = false
    var gameStarted = false
    var score = 0 {
        didSet {
            scoreLabel.text = "Carrots: \(score)"
            updateLevel()
        }
    }
    var level = 1
    var health = 3 {
        didSet {
            updateHealthDisplay()
        }
    }
    
    // Power-ups
    var isShielded = false
    var shieldEndTime: TimeInterval = 0
    var speedBoostEndTime: TimeInterval = 0
    var doublePointsEndTime: TimeInterval = 0
    
    // Nodes
    let bunny: SKSpriteNode
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    let levelLabel = SKLabelNode(fontNamed: "Chalkduster")
    let healthLabel = SKLabelNode(fontNamed: "Chalkduster")
    let startLabel = SKLabelNode(fontNamed: "Chalkduster")
    var shieldNode: SKSpriteNode?
    var powerUpLabels: [SKLabelNode] = []
    var lastSpawnTime: TimeInterval = 0
    var lastPowerUpSpawn: TimeInterval = 0
    
    // Game parameters
    var spawnRate: TimeInterval = 0.8
    var objectSpeed: CGFloat = 150
    
    // Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let bunny: UInt32 = 0b1
        static let asteroid: UInt32 = 0b10
        static let carrot: UInt32 = 0b100
        static let powerUp: UInt32 = 0b1000
    }
    
    override init() {
        // Initialize bunny with fallback if image is missing
        // Always use emoji fallback for simplicity
        self.bunny = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 40))
        let bunnyEmoji = SKLabelNode(text: "🐰")
        bunnyEmoji.fontSize = 30
        bunnyEmoji.verticalAlignmentMode = .center
        self.bunny.addChild(bunnyEmoji)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        // Always use emoji fallback for simplicity
        self.bunny = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 40))
        let bunnyEmoji = SKLabelNode(text: "🐰")
        bunnyEmoji.fontSize = 30
        bunnyEmoji.verticalAlignmentMode = .center
        self.bunny.addChild(bunnyEmoji)
        
        super.init(coder: aDecoder)
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1)
        
        // Setup physics
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // Add stars background
        addStarField()
        
        // Setup bunny
        setupBunny()
        
        // Setup UI
        setupUI()
        
        // Show start screen
        showStartScreen()
    }
    
    func setupBunny() {
        bunny.position = CGPoint(x: size.width/2, y: 100)
        bunny.physicsBody = SKPhysicsBody(rectangleOf: bunny.size)
        bunny.physicsBody?.categoryBitMask = PhysicsCategory.bunny
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.carrot
        bunny.physicsBody?.collisionBitMask = PhysicsCategory.none
        bunny.physicsBody?.isDynamic = true
        addChild(bunny)
    }
    
    func setupScoreLabel() {
        scoreLabel.text = "Carrots: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 60)
        scoreLabel.fontColor = .white
        addChild(scoreLabel)
    }
    
    func addStarField() {
        // Create multiple star layers for depth using simple shapes instead of textures
        
        // Background distant stars
        let distantStars = SKEmitterNode()
        // Use programmatically created texture for consistency
        distantStars.particleTexture = createStarTexture(size: 2)
        distantStars.particleBirthRate = 8
        distantStars.particleLifetime = 50
        distantStars.particleScale = 0.01
        distantStars.particleScaleRange = 0.005
        distantStars.particleSpeed = 15
        distantStars.particleSpeedRange = 5
        distantStars.particleAlpha = 0.4
        distantStars.particleAlphaRange = 0.2
        distantStars.position = CGPoint(x: size.width/2, y: size.height)
        distantStars.particlePositionRange = CGVector(dx: size.width, dy: 0)
        distantStars.emissionAngle = -.pi/2
        distantStars.particleColor = .white
        distantStars.zPosition = -20
        addChild(distantStars)
        
        // Medium stars
        let mediumStars = SKEmitterNode()
        // Use programmatically created texture for consistency
        mediumStars.particleTexture = createStarTexture(size: 3)
        mediumStars.particleBirthRate = 5
        mediumStars.particleLifetime = 40
        mediumStars.particleScale = 0.02
        mediumStars.particleScaleRange = 0.01
        mediumStars.particleSpeed = 25
        mediumStars.particleSpeedRange = 10
        mediumStars.particleAlpha = 0.7
        mediumStars.particleAlphaRange = 0.3
        mediumStars.position = CGPoint(x: size.width/2, y: size.height)
        mediumStars.particlePositionRange = CGVector(dx: size.width, dy: 0)
        mediumStars.emissionAngle = -.pi/2
        mediumStars.particleColor = .white
        mediumStars.zPosition = -10
        addChild(mediumStars)
        
        // Foreground bright stars
        let brightStars = SKEmitterNode()
        // Use programmatically created texture for consistency
        brightStars.particleTexture = createStarTexture(size: 4)
        brightStars.particleBirthRate = 2
        brightStars.particleLifetime = 30
        brightStars.particleScale = 0.03
        brightStars.particleScaleRange = 0.02
        brightStars.particleSpeed = 35
        brightStars.particleSpeedRange = 15
        brightStars.particleAlpha = 1.0
        brightStars.particleAlphaRange = 0.2
        brightStars.position = CGPoint(x: size.width/2, y: size.height)
        brightStars.particlePositionRange = CGVector(dx: size.width, dy: 0)
        brightStars.emissionAngle = -.pi/2
        brightStars.particleColor = .white
        brightStars.zPosition = -5
        addChild(brightStars)
        
        // Add floating space objects
        addFloatingSpaceObjects()
    }
    
    func createStarTexture(size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        return SKTexture(image: image)
    }
    
    func addFloatingSpaceObjects() {
        // Create floating space objects that move slowly across the screen
        let spaceObjects = ["🌙", "🪐", "☄️", "🌟", "🌠", "🛸", "🌌", "⭐"]
        
        for i in 0..<6 {
            let delay = Double(i) * 3.0 // Stagger the appearance
            
            let waitAction = SKAction.wait(forDuration: delay)
            let spawnAction = SKAction.run {
                self.spawnFloatingObject(spaceObjects)
            }
            
            run(SKAction.sequence([waitAction, spawnAction]))
        }
        
        // Continue spawning space objects periodically
        let spawnTimer = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: 12.0),
                SKAction.run {
                    self.spawnFloatingObject(spaceObjects)
                }
            ])
        )
        run(spawnTimer)
    }
    
    func spawnFloatingObject(_ objects: [String]) {
        let randomObject = objects.randomElement() ?? "⭐"
        let objectNode = SKLabelNode(text: randomObject)
        objectNode.fontSize = CGFloat.random(in: 20...40)
        objectNode.alpha = 0.3
        objectNode.zPosition = -15
        
        // Random starting position (from any edge)
        let edge = Int.random(in: 0...3)
        switch edge {
        case 0: // Top
            objectNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: size.height + 50)
        case 1: // Right
            objectNode.position = CGPoint(x: size.width + 50, y: CGFloat.random(in: 0...size.height))
        case 2: // Bottom
            objectNode.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: -50)
        case 3: // Left
            objectNode.position = CGPoint(x: -50, y: CGFloat.random(in: 0...size.height))
        default:
            objectNode.position = CGPoint(x: size.width + 50, y: CGFloat.random(in: 0...size.height))
        }
        
        addChild(objectNode)
        
        // Slow floating movement
        let moveAction = SKAction.move(to: CGPoint(x: CGFloat.random(in: -100...size.width + 100), 
                                                 y: CGFloat.random(in: -100...size.height + 100)), 
                                     duration: Double.random(in: 15...25))
        
        // Gentle rotation
        let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -0.5...0.5), 
                                         duration: Double.random(in: 8...12))
        let repeatRotation = SKAction.repeatForever(rotateAction)
        
        // Gentle pulsing
        let pulseAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 2.0),
            SKAction.fadeAlpha(to: 0.2, duration: 2.0)
        ])
        let repeatPulse = SKAction.repeatForever(pulseAction)
        
        // Combine actions
        let combinedAction = SKAction.group([moveAction, repeatRotation, repeatPulse])
        
        objectNode.run(SKAction.sequence([
            combinedAction,
            SKAction.removeFromParent()
        ]))
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard !gameOver && gameStarted else { return }
        
        // Update power-ups
        updatePowerUps(currentTime)
        
        // Spawn objects based on level
        if currentTime - lastSpawnTime > spawnRate {
            lastSpawnTime = currentTime
            spawnObject()
        }
        
        // Spawn power-ups occasionally
        if currentTime - lastPowerUpSpawn > 8.0 {
            lastPowerUpSpawn = currentTime
            spawnPowerUp()
        }
    }
    
    func spawnObject() {
        guard size.width > 100 && size.height > 100 else { return }
        let objectType = arc4random_uniform(4) == 0 ? "carrot" : "asteroid"
        let object: SKSpriteNode
        
        // Always use emoji fallback for consistency
        object = SKSpriteNode(color: .clear, size: CGSize(width: 30, height: 30))
        let emoji = SKLabelNode(text: objectType == "carrot" ? "🥕" : "☄️")
        emoji.fontSize = 25
        emoji.verticalAlignmentMode = .center
        object.addChild(emoji)
        
        // Random position at top of screen
        let xPos = CGFloat.random(in: 50...size.width-50)
        object.position = CGPoint(x: xPos, y: size.height + object.size.height/2)
        
        // Physics setup
        object.physicsBody = SKPhysicsBody(rectangleOf: object.size)
        object.physicsBody?.velocity = CGVector(dx: 0, dy: -objectSpeed)
        object.physicsBody?.angularVelocity = CGFloat.random(in: -3...3)
        object.physicsBody?.linearDamping = 0
        object.physicsBody?.categoryBitMask = objectType == "carrot" ?
            PhysicsCategory.carrot : PhysicsCategory.asteroid
        object.physicsBody?.contactTestBitMask = PhysicsCategory.bunny
        object.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(object)
        
        // Remove when off screen
        let removeAction = SKAction.sequence([
            SKAction.wait(forDuration: 10),
            SKAction.removeFromParent()
        ])
        object.run(removeAction)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & PhysicsCategory.bunny != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.carrot != 0) {
            // Bunny collected carrot
            collectCarrot(secondBody.node as! SKSpriteNode)
        } else if (firstBody.categoryBitMask & PhysicsCategory.bunny != 0) &&
                    (secondBody.categoryBitMask & PhysicsCategory.asteroid != 0) {
            // Bunny hit asteroid
            hitAsteroid()
        } else if (firstBody.categoryBitMask & PhysicsCategory.bunny != 0) &&
                    (secondBody.categoryBitMask & PhysicsCategory.powerUp != 0) {
            // Bunny collected power-up
            collectPowerUp(secondBody.node as! SKSpriteNode)
        }
    }
    
    func collectCarrot(_ carrot: SKSpriteNode) {
        let pointsToAdd = doublePointsEndTime > 0 ? 2 : 1
        score += pointsToAdd
        
        // Increase bunny size with each carrot
        let newSize = bunny.size.width * 1.1
        bunny.size = CGSize(width: newSize, height: newSize)
        
        // Update physics body to match new size
        bunny.physicsBody = SKPhysicsBody(rectangleOf: bunny.size)
        bunny.physicsBody?.categoryBitMask = PhysicsCategory.bunny
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.carrot | PhysicsCategory.powerUp
        bunny.physicsBody?.collisionBitMask = PhysicsCategory.none
        bunny.physicsBody?.isDynamic = true
        
        // Update shield if active
        if isShielded, let shield = shieldNode {
            shield.size = CGSize(width: bunny.size.width + 20, height: bunny.size.height + 20)
        }
        
        // Scale emoji if using fallback bunny
        if let emojiNode = bunny.children.first as? SKLabelNode {
            let scaleFactor = bunny.size.width / 40.0 // Original size was 40
            emojiNode.fontSize = 30 * scaleFactor
        }
        carrot.removeFromParent()
        
        // Visual effect (skip sound if file missing)
        // Sound effects can crash if files don't exist, so we'll skip them for now
        // run(SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false))
        
        // Create simple particle effect if file is missing
        let particles: SKEmitterNode
        if let collectParticles = SKEmitterNode(fileNamed: "CollectParticle") {
            particles = collectParticles
        } else {
            particles = SKEmitterNode()
            particles.particleTexture = createStarTexture(size: 3)
            particles.particleBirthRate = 50
            particles.particleLifetime = 0.8
            particles.particleScale = 0.1
            particles.particleSpeed = 30
            particles.particleColor = .green
        }
        
        particles.position = carrot.position
        addChild(particles)
        particles.run(SKAction.sequence([
            SKAction.wait(forDuration: 1),
            SKAction.removeFromParent()
        ]))
    }
    
    func collectPowerUp(_ powerUp: SKSpriteNode) {
        guard let powerUpType = powerUp.name else { return }
        
        activatePowerUp(powerUpType, currentTime: CFAbsoluteTimeGetCurrent())
        powerUp.removeFromParent()
        
        // Visual effect
        let particles = SKEmitterNode()
        // Use programmatically created texture for consistency
        particles.particleTexture = createStarTexture(size: 3)
        particles.particleBirthRate = 100
        particles.particleLifetime = 1.0
        particles.particleScale = 0.1
        particles.particleScaleRange = 0.05
        particles.particleSpeed = 50
        particles.particleSpeedRange = 25
        particles.particleAlpha = 1.0
        particles.particleColor = .purple
        particles.position = powerUp.position
        addChild(particles)
        
        particles.run(SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.removeFromParent()
        ]))
    }
    
    func hitAsteroid() {
        // Check if shielded
        if isShielded {
            // Shield absorbs the hit
            isShielded = false
            shieldNode?.removeFromParent()
            shieldNode = nil
            removePowerUpLabel("Shield")
            
            // Visual effect for shield break
            let shieldBreak = SKEmitterNode()
            // Use programmatically created texture for consistency
            shieldBreak.particleTexture = createStarTexture(size: 3)
            shieldBreak.particleBirthRate = 200
            shieldBreak.particleLifetime = 0.5
            shieldBreak.particleScale = 0.1
            shieldBreak.particleSpeed = 100
            shieldBreak.particleColor = .cyan
            shieldBreak.position = bunny.position
            addChild(shieldBreak)
            
            shieldBreak.run(SKAction.sequence([
                SKAction.wait(forDuration: 1),
                SKAction.removeFromParent()
            ]))
            
            return
        }
        
        // Reduce health
        health -= 1
        
        if health <= 0 {
            // Game over logic
            gameOver = true
            
            // Visual explosion
            let explosion: SKEmitterNode
            if let explosionParticles = SKEmitterNode(fileNamed: "ExplosionParticle") {
                explosion = explosionParticles
            } else {
                explosion = SKEmitterNode()
                explosion.particleTexture = createStarTexture(size: 4)
                explosion.particleBirthRate = 200
                explosion.particleLifetime = 1.0
                explosion.particleScale = 0.2
                explosion.particleSpeed = 80
                explosion.particleColor = .red
            }
            explosion.position = bunny.position
            addChild(explosion)
            
            bunny.removeFromParent()
            
            // Game over message
            let gameOverLabel = SKLabelNode(fontNamed: "Chalkduster")
            gameOverLabel.text = "GAME OVER! Final Carrots: \(score)\n\nTap to Restart"
            gameOverLabel.numberOfLines = 0
            gameOverLabel.fontSize = 40
            gameOverLabel.horizontalAlignmentMode = .center
            gameOverLabel.verticalAlignmentMode = .center
            gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2)
            gameOverLabel.fontColor = .red
            addChild(gameOverLabel)
            
            // Sound effects can crash if files don't exist, so we'll skip them for now
            // run(SKAction.playSoundFileNamed("explosion.wav", waitForCompletion: false))
        } else {
            // Flash the bunny to show damage
            let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1)
            let flashBack = SKAction.colorize(with: .white, colorBlendFactor: 0.0, duration: 0.1)
            let flashSequence = SKAction.sequence([flashRed, flashBack])
            bunny.run(SKAction.repeat(flashSequence, count: 3))
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !gameStarted && !gameOver {
            startGame()
        } else if gameOver {
            restartGame()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !gameOver && gameStarted else { return }
        
        let location = touch.location(in: self)
        
        // Move bunny horizontally only
        bunny.position = CGPoint(x: location.x, y: bunny.position.y)
        
        // Constrain to screen bounds
        bunny.position.x = max(bunny.size.width/2, min(size.width - bunny.size.width/2, bunny.position.x))
    }
    
    // MARK: - Enhanced Game Methods
    
    func setupUI() {
        // Score label
        scoreLabel.text = "Carrots: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 60)
        scoreLabel.fontColor = .white
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        
        // Level label
        levelLabel.text = "Level: 1"
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width/2, y: size.height - 60)
        levelLabel.fontColor = .cyan
        levelLabel.fontSize = 24
        addChild(levelLabel)
        
        // Health label
        healthLabel.text = "❤️❤️❤️"
        healthLabel.horizontalAlignmentMode = .right
        healthLabel.position = CGPoint(x: size.width - 20, y: size.height - 60)
        healthLabel.fontSize = 24
        addChild(healthLabel)
    }
    
    func showStartScreen() {
        startLabel.text = "🐰 SPACE BUNNIES 🥕\n\nTap to Start!\n\nCollect carrots, avoid asteroids\nPower-ups will help you survive!"
        startLabel.numberOfLines = 0
        startLabel.horizontalAlignmentMode = .center
        startLabel.verticalAlignmentMode = .center
        startLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        startLabel.fontColor = .white
        startLabel.fontSize = 32
        addChild(startLabel)
    }
    
    func startGame() {
        gameStarted = true
        startLabel.removeFromParent()
        bunny.physicsBody?.contactTestBitMask = PhysicsCategory.asteroid | PhysicsCategory.carrot | PhysicsCategory.powerUp
    }
    
    func restartGame() {
        // Reset game state
        gameOver = false
        gameStarted = false
        score = 0
        level = 1
        health = 3
        spawnRate = 0.8
        objectSpeed = 150
        
        // Reset power-ups
        isShielded = false
        shieldEndTime = 0
        speedBoostEndTime = 0
        doublePointsEndTime = 0
        
        // Clear power-up labels
        powerUpLabels.forEach { $0.removeFromParent() }
        powerUpLabels.removeAll()
        
        // Remove shield
        shieldNode?.removeFromParent()
        shieldNode = nil
        
        // Reset bunny size
        bunny.size = CGSize(width: 40, height: 40)
        if let emojiNode = bunny.children.first as? SKLabelNode {
            emojiNode.fontSize = 30
        }
        
        // Remove all children except permanent ones
        removeAllChildren()
        
        // Re-setup the game
        addStarField()
        setupBunny()
        setupUI()
        showStartScreen()
    }
    
    func updateLevel() {
        let newLevel = (score / 10) + 1
        if newLevel > level {
            level = newLevel
            levelLabel.text = "Level: \(level)"
            
            // Increase difficulty
            spawnRate = max(0.3, 0.8 - (Double(level) * 0.05))
            objectSpeed = min(300, 150 + (CGFloat(level) * 10))
            
            // Level up effect
            let levelUpLabel = SKLabelNode(fontNamed: "Chalkduster")
            levelUpLabel.text = "LEVEL UP!"
            levelUpLabel.fontSize = 48
            levelUpLabel.fontColor = .yellow
            levelUpLabel.position = CGPoint(x: size.width/2, y: size.height/2)
            addChild(levelUpLabel)
            
            levelUpLabel.run(SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.3),
                SKAction.wait(forDuration: 1.0),
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    func updateHealthDisplay() {
        let hearts = String(repeating: "❤️", count: health)
        healthLabel.text = hearts
    }
    
    func spawnPowerUp() {
        guard size.width > 100 && size.height > 100 else { return }
        let powerUpTypes = ["shield", "speed", "double_points", "health"]
        let powerUpType = powerUpTypes[Int(arc4random_uniform(UInt32(powerUpTypes.count)))]
        
        // Create power-up with colored background
        let powerUp = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 40))
        let background = SKSpriteNode(color: .purple, size: CGSize(width: 40, height: 40))
        background.alpha = 0.7
        powerUp.addChild(background)
        
        // Add emoji based on type
        let emoji = SKLabelNode(text: getPowerUpEmoji(powerUpType))
        emoji.fontSize = 24
        emoji.verticalAlignmentMode = .center
        powerUp.addChild(emoji)
        
        // Position and physics
        let xPos = CGFloat.random(in: 50...size.width-50)
        powerUp.position = CGPoint(x: xPos, y: size.height + powerUp.size.height/2)
        powerUp.name = powerUpType
        
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.size)
        powerUp.physicsBody?.velocity = CGVector(dx: 0, dy: -objectSpeed * 0.7)
        powerUp.physicsBody?.categoryBitMask = PhysicsCategory.powerUp
        powerUp.physicsBody?.contactTestBitMask = PhysicsCategory.bunny
        powerUp.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        addChild(powerUp)
        
        // Remove when off screen
        powerUp.run(SKAction.sequence([
            SKAction.wait(forDuration: 10),
            SKAction.removeFromParent()
        ]))
    }
    
    func getPowerUpEmoji(_ type: String) -> String {
        switch type {
        case "shield": return "🛡️"
        case "speed": return "⚡"
        case "double_points": return "✨"
        case "health": return "💚"
        default: return "⭐"
        }
    }
    
    func updatePowerUps(_ currentTime: TimeInterval) {
        // Update shield
        if isShielded && currentTime > shieldEndTime {
            isShielded = false
            shieldNode?.removeFromParent()
            shieldNode = nil
            removePowerUpLabel("Shield")
        }
        
        // Update speed boost
        if speedBoostEndTime > 0 && currentTime > speedBoostEndTime {
            speedBoostEndTime = 0
            removePowerUpLabel("Speed Boost")
        }
        
        // Update double points
        if doublePointsEndTime > 0 && currentTime > doublePointsEndTime {
            doublePointsEndTime = 0
            removePowerUpLabel("Double Points")
        }
    }
    
    func activatePowerUp(_ type: String, currentTime: TimeInterval) {
        switch type {
        case "shield":
            isShielded = true
            shieldEndTime = currentTime + 8.0
            addShield()
            addPowerUpLabel("Shield Active!")
            
        case "speed":
            speedBoostEndTime = currentTime + 6.0
            addPowerUpLabel("Speed Boost!")
            
        case "double_points":
            doublePointsEndTime = currentTime + 10.0
            addPowerUpLabel("Double Points!")
            
        case "health":
            if health < 3 {
                health += 1
                addPowerUpLabel("Health Restored!")
            }
        default:
            break
        }
    }
    
    func addShield() {
        shieldNode = SKSpriteNode(color: .cyan, size: CGSize(width: bunny.size.width + 20, height: bunny.size.height + 20))
        shieldNode?.alpha = 0.3
        shieldNode?.position = bunny.position
        if let shield = shieldNode {
            addChild(shield)
            
            // Animate shield
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.6, duration: 0.5),
                SKAction.fadeAlpha(to: 0.3, duration: 0.5)
            ])
            shield.run(SKAction.repeatForever(pulse))
        }
    }
    
    func addPowerUpLabel(_ text: String) {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = text
        label.fontSize = 20
        label.fontColor = .yellow
        label.position = CGPoint(x: size.width/2, y: size.height - 120 - CGFloat(powerUpLabels.count * 25))
        addChild(label)
        powerUpLabels.append(label)
    }
    
    func removePowerUpLabel(_ text: String) {
        powerUpLabels.removeAll { label in
            if label.text?.contains(text) == true {
                label.removeFromParent()
                return true
            }
            return false
        }
    }
}

struct ContentView: View {
    var body: some View {
        SpriteView(scene: GameScene())
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
