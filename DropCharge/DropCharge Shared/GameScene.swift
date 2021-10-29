//
//  GameScene.swift
//  DropCharge Shared
//
//  Created by Sabir Myrzaev on 10.10.2021.
//

import SpriteKit
import CoreMotion

// MARK: - Game States
enum GameStatus: Int {
    case waitingForTap = 0
    case waitingForBomb = 1
    case playing = 2
    case gameOver = 3
}

enum PlayerStatus: Int {
    case idle = 0
    case jump = 1
    case fall = 2
    case lava = 3
    case dead = 4
}

struct PhysicsCategory {
    static let None: UInt32 = 0 // 0
    static let Player: UInt32 = 0b1 // 1
    static let PlatformNormal: UInt32 = 0b10 // 2
    static let PlatformBreakable: UInt32 = 0b100 // 4
    static let CoinNormal: UInt32 = 0b1000 // 8
    static let CoinSpecial: UInt32 = 0b10000 // 16
    static let Edges: UInt32 = 0b100000 // 32
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Property
    // property background & foreground
    var bgNode: SKNode!
    var fgNode: SKNode!
    var backgroundOverlayTemplate: SKNode!
    var backgroundOverlayHeight: CGFloat!
    var player: SKSpriteNode!
    
    // property platforms & coins
    var platform5Across: SKSpriteNode!
    var coinArrow: SKSpriteNode!
    var lastOverlayPosition = CGPoint.zero
    var lastOverlayHeight: CGFloat = 0.0
    var levelPositionY: CGFloat = 0.0
    
    // check status game
    var gameState = GameStatus.waitingForTap
    var playerState = PlayerStatus.idle
    
    // Core Motion
    var motionManager = CMMotionManager()
    var xAcceleration = CGFloat(0)
    
    // Camera
    let cameraNode = SKCameraNode()
    
    // Lava
    var lava: SKSpriteNode!
    
    // Update
    var lastUpdateTimeInterval: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    
    // Game Over
    var lives = 3
    
    // MARK: - didMove
    override func didMove(to view: SKView) {
        
        setupNodes()
        setupLevel()
        setupPlayer()
        
        let scale = SKAction.scale(to: 1.0, duration: 0.5)
        fgNode.childNode(withName: "Ready")!.run(scale)
        
        physicsWorld.contactDelegate = self
        
        setupCoreMotion()
    }
    
    // MARK: - didBegin
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        switch other.categoryBitMask {
        case PhysicsCategory.CoinNormal:
            if let coin = other.node as? SKSpriteNode {
                coin.removeFromParent()
                jumpPlayer()
            }
        default:
            break
        }
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTimeInterval > 0 {
            deltaTime = currentTime - lastUpdateTimeInterval
        } else {
            deltaTime = 0
        }
        lastUpdateTimeInterval = currentTime
        
        if isPaused {
            return
        }
        
        if gameState == .playing {
            updateCamera()
            updateLevel()
            updatePlayer()
            updateLava(deltaTime)
            updateCollisionLava()
        }
    }
    
    // MARK: - Events
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameState == .waitingForTap {
            bombDrop()
        } else if gameState == .gameOver {
            let newScene = GameScene(fileNamed: "GameScene")
            newScene!.scaleMode = .aspectFill
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            view?.presentScene(newScene!, transition: reveal)
            
        }
    }
    
    func bombDrop() {
        gameState = .waitingForBomb
        
        // Scale out title & ready label
        let scale = SKAction.scaleX(to: 0, duration: 0.4)
        fgNode.childNode(withName: "Title")?.run(scale)
        fgNode.childNode(withName: "Ready")!.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), scale]))
        
        // Bounce bomb
        let scaleUp = SKAction.scale(to: 1.25, duration: 0.25)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatSeq = SKAction.repeatForever(sequence)
        
        fgNode.childNode(withName: "Bomb")!.run(SKAction.unhide())
        fgNode.childNode(withName: "Bomb")!.run(repeatSeq)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.run(startGame)
        ]))
    }
    
    func startGame() {
        fgNode.childNode(withName: "Bomb")!.removeFromParent()
        gameState = .playing
        player.physicsBody?.isDynamic = true
        superBoostPlayer()
    }
    
    func gameOver() {
        gameState = .gameOver
        playerState = .dead
        
        physicsWorld.contactDelegate = nil
        player.physicsBody?.isDynamic = false
        
        let moveUp = SKAction.moveBy(x: 0.0, y: size.height/2, duration: 0.5)
        moveUp.timingMode = .easeOut
        
        let moveDown = SKAction.moveBy(x: 0.0, y: -(size.height * 1.5), duration: 1.0)
        moveDown.timingMode = .easeIn
        
        player.run(SKAction.sequence([moveUp, moveDown]))
        
        let gameOverSprite = SKSpriteNode(imageNamed: "GameOver")
        gameOverSprite.position = camera!.position
        gameOverSprite.zPosition = 10
        addChild(gameOverSprite)
        
    }
    
    // MARK: - Setup
    func setupNodes() {
        let worldNode = childNode(withName: "World")!
        bgNode = worldNode.childNode(withName: "Background")!
        backgroundOverlayTemplate = bgNode.childNode(withName: "Overlay")!.copy() as? SKNode
        backgroundOverlayHeight = backgroundOverlayTemplate.calculateAccumulatedFrame().height
        fgNode = worldNode.childNode(withName: "Foreground")!
        player = fgNode.childNode(withName: "Player") as? SKSpriteNode
        fgNode.childNode(withName: "Bomb")?.run(SKAction.hide())
        
        platform5Across = loadForegroundOverlayTemplate("Platform5Across")
        coinArrow = loadForegroundOverlayTemplate("CoinArrow")
        
        addChild(cameraNode)
        camera = cameraNode
        
        lava = fgNode.childNode(withName: "Lava") as? SKSpriteNode
    }
    
    func setupLevel() {
        // Place initial platform
        let initialPlatform = platform5Across.copy() as! SKSpriteNode
        var overlayPosition = player.position
        overlayPosition.y = player.position.y - (player.size.height * 0.5 + initialPlatform.size.height * 0.20)
        initialPlatform.position = overlayPosition
        fgNode.addChild(initialPlatform)
        lastOverlayPosition = overlayPosition
        lastOverlayHeight = initialPlatform.size.height / 2.0
        
        // create random level
        levelPositionY = bgNode.childNode(withName: "Overlay")!.position.y + backgroundOverlayHeight
        while lastOverlayPosition.y < levelPositionY {
            addRandomForegroundOverlay()
        }
    }
    
    func setupPlayer() {
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.3)
        player.physicsBody!.isDynamic = false
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = PhysicsCategory.Player
        player.physicsBody!.collisionBitMask = 0
    }
    
    // MARK: - CoreMotion
    func setupCoreMotion() {
        motionManager.accelerometerUpdateInterval = 0.2
        let queue = OperationQueue()
        motionManager.startAccelerometerUpdates(to: queue) { accelerometerData, error in
            guard let accelerometerData = accelerometerData else {
                return
            }
            let acceleration = accelerometerData.acceleration
            self.xAcceleration = CGFloat(acceleration.x) * 0.75  + self.xAcceleration * 0.25
        }
    }
    
    func sceneCropAmount() -> CGFloat {
        guard let view = view else { return 0 }
        let scale = view.bounds.size.height / size.height
        let scaleWidth = size.width * scale
        let scaleOverlap = scaleWidth - view.bounds.size.width
        return scaleOverlap / scale
    }
    
    // MARK: - Update Events
    
    func updatePlayer() {
        // Set velocity basen on core animation
        player.physicsBody?.velocity.dx = xAcceleration * 1000.0
        
        // Wrap player around edjes pf screen
        var playerPosition = convert(player.position, from: fgNode)
        let rightLimit = size.width/2 - sceneCropAmount()/2 + player.size.width/2
        let leftLimit = -rightLimit
        
        if playerPosition.x < leftLimit {
            playerPosition = convert(CGPoint(x: rightLimit, y: 0.0), to: fgNode)
            player.position.x = playerPosition.x
        }  else if playerPosition.x > rightLimit {
            playerPosition = convert(CGPoint(x: leftLimit, y: 0.0), to: fgNode)
            player.position.x = playerPosition.x
        }
        
        // Check player state
        if player.physicsBody!.velocity.dy < CGFloat(0.0) && playerState != .fall {
            playerState = .fall
            print("Failing")
        } else if player.physicsBody!.velocity.dy > CGFloat(0.0) && playerState != .jump {
            playerState = .jump
            print("Jumping")
        }
        
    }
    
    func updateCamera() {
        let cameraTarget = convert(player.position, from: fgNode)
        
        var targetPositionY = cameraTarget.y - (size.height * 0.10)
        let lavaPos = convert(lava.position, from: fgNode)
        targetPositionY = max(targetPositionY, lavaPos.y)
        // calculate diff between target camera and current position
        let diff = targetPositionY - camera!.position.y
        
        let cameraLagFactor: CGFloat = 0.2
        let lagDiff = diff * cameraLagFactor
        let newCameraPositionY = camera!.position.y + lagDiff
        
        camera!.position.y = newCameraPositionY
    }
    
    func updateLevel() {
        let cameraPos = camera!.position
        if cameraPos.y > levelPositionY - size.height {
            createBackgroundOverlay()
            while lastOverlayPosition.y < levelPositionY {
                addRandomForegroundOverlay()
            }
        }
    }
    
    func updateLava(_ dt: TimeInterval) {
        let bottomOfScreenY = camera!.position.y - (size.height/2)
        let bottomOfScreenFg = convert(CGPoint(x: 0, y: bottomOfScreenY), to: fgNode).y
        
        let lavaVelocity = CGFloat(120)
        let lavaStep = lavaVelocity * CGFloat(dt)
        var newLavaPositionY = lava.position.y + lavaStep
        
        newLavaPositionY = max(newLavaPositionY, bottomOfScreenFg - 125.0)
        
        lava.position.y = newLavaPositionY
    }
    
    func updateCollisionLava() {
        if player.position.y < lava.position.y + 90 {
            playerState = .lava
            print("Lava")
            boostPlayer()
        }
    }
    
    // MARK: - Velocity
    func setPlayerVelocity(_ amount: CGFloat) {
        let gain: CGFloat = 2.5
        player.physicsBody!.velocity.dy = max(player.physicsBody!.velocity.dy, amount * gain)
    }
    
    func jumpPlayer() {
        setPlayerVelocity(650)
    }
    
    func boostPlayer() {
        setPlayerVelocity(1200)
        lives -= 1
        if lives <= 0 {
            gameOver()
        }
    }
    
    func superBoostPlayer() {
        setPlayerVelocity(1700)
    }
    
    // MARK: - Overlay nodes
    func loadForegroundOverlayTemplate(_ fileName: String) -> SKSpriteNode {
        let overlayScene = SKScene(fileNamed: fileName)!
        let overlayTemplete = overlayScene.childNode(withName: "Overlay")
        return overlayTemplete as! SKSpriteNode
    }
    
    func createForegroundOverlay(_ overlayTemplate: SKSpriteNode, flipX: Bool) {
        let foregroundOverlay = overlayTemplate.copy() as! SKSpriteNode
        lastOverlayPosition.y = lastOverlayPosition.y + (lastOverlayHeight + (foregroundOverlay.size.height / 2.0))
        lastOverlayHeight = foregroundOverlay.size.height / 2.0
        foregroundOverlay.position = lastOverlayPosition
        if flipX == true {
            foregroundOverlay.xScale = -1.0
        }
        fgNode.addChild(foregroundOverlay)
    }
    
    // generate random number and add platform in 60 percent case
    func addRandomForegroundOverlay() {
        let overlaySprite: SKSpriteNode!
        let platformPercentage = 60
        if Int.random(min: 1, max: 100) <= platformPercentage {
            overlaySprite = platform5Across
        } else {
            overlaySprite = coinArrow
        }
        createForegroundOverlay(overlaySprite, flipX: false)
    }
    
    func createBackgroundOverlay() {
        let backgroundOverlay = backgroundOverlayTemplate.copy() as! SKNode
        backgroundOverlay.position = CGPoint(x: 0.0, y: levelPositionY)
        bgNode.addChild(backgroundOverlay)
        levelPositionY += backgroundOverlayHeight
    }
    
    
}
