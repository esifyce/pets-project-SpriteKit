//
//  Player.swift
//  PestControll iOS
//
//  Created by Sabir Myrzaev on 08.10.2021.
//

import SpriteKit

enum PlayerSettings {
    static let playerSpeed: CGFloat = 280.0
}

class Player: SKSpriteNode {
    
    var animations: [SKAction] = []
    var hasBugspray: Bool = false {
        didSet {
            blink(color: .green, on: hasBugspray)
        }
    }
    
    init () {
        let texture = SKTexture(imageNamed: "player_ft1")
        super.init(texture: texture, color: .white, size: texture.size())
        name = "Player"
        zPosition = 50
        
        physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
        // отскочить без потери энернии
        physicsBody?.restitution = 1.0
        // постепенно терять скорость
        physicsBody?.linearDamping = 0.5
        // скольжение
        physicsBody?.friction = 0
        // вращение
        physicsBody?.allowsRotation = false
        
        physicsBody?.categoryBitMask = PhysicsCategory.Player
        physicsBody?.contactTestBitMask = PhysicsCategory.All
        
        createAnimations(character: "player")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        animations = aDecoder.decodeObject(forKey: "Player.animations") as! [SKAction]
        hasBugspray = aDecoder.decodeBool(forKey: "Player.hasBugspray")
        
        if hasBugspray {
            removeAction(forKey: "blink")
            blink(color: .green, on: hasBugspray)
        }
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(hasBugspray, forKey: "Player.hasBugspray")
        coder.encode(animations, forKey: "Player.animations")
        super.encode(with: coder)
    }
    
    // заставляет игрока двигаться навстречу target
    func move(target: CGPoint) {
        guard let physicsBody = physicsBody else { return }
        
        let newVelocity = (target - position).normalized() * PlayerSettings.playerSpeed
        physicsBody.velocity = CGVector(point: newVelocity)
        
        //print("\(animationDirection(for: physicsBody.velocity))")
        checkDirection()
    }
    
    func checkDirection() {
        guard let physicsBody = physicsBody else { return }
        
        let direction = animationDirection(for: physicsBody.velocity)
        
        if direction == .left {
            xScale = abs(xScale)
        }
        if direction == .right {
            xScale = -abs(xScale)
        }
        run(animations[direction.rawValue], withKey: "animation")
    }
    
    func blink(color: SKColor, on: Bool) {
        // clear color Arnie
        let blinkOff = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.2)
        
        if on {
            // mix Color on Player
            let blinkOn = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 0.2)
            let blink = SKAction.repeatForever(SKAction.sequence([blinkOn, blinkOff]))
            xScale = xScale < 0 ? -1.5 : 1.5
            yScale = 1.5
            run(blink, withKey: "blink")
        } else {
            // off blink
            xScale = xScale < 0 ? -1.0 : 1.0
            yScale = 1.0
            removeAction(forKey: "blink")
            run(blinkOff)
        }
    }
}

extension Player : Animatable {}
