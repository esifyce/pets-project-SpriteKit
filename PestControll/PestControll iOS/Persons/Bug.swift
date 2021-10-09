//
//  Bug.swift
//  PestControll iOS
//
//  Created by Sabir Myrzaev on 08.10.2021.
//

import SpriteKit

enum BugSettings {
    static let bugDistance: CGFloat = 16
}

class Bug: SKSpriteNode {
  
    var animations: [SKAction] = []
    
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    animations = aDecoder.decodeObject(forKey: "Bug.animations") as! [SKAction]
  }
  
  init() {
    let texture = SKTexture(pixelImageNamed: "bug_ft1")
    super.init(texture: texture, color: .white,
               size: texture.size())
    name = "Bug"
    
    physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
    physicsBody?.restitution = 0.5
    physicsBody?.allowsRotation = false
    physicsBody?.categoryBitMask = PhysicsCategory.Bug
    createAnimations(character: "bug")
  }
    
    override func encode(with coder: NSCoder) {
        coder.encode(animations, forKey: "Bug.animations")
        super.encode(with: coder)
    }
    
    @objc func moveBug() {
        
        let randomX = CGFloat(Int.random(min: -1, max: 1))
        let randomY = CGFloat(Int.random(min: -1, max: 1))
        
        let vector = CGVector(dx: randomX * BugSettings.bugDistance,
                              dy: randomY * BugSettings.bugDistance)
        
        let moveBy = SKAction.move(by: vector, duration: 1)
        let moveAgain = SKAction.perform(#selector(moveBug), onTarget: self)
        
        // direction animate with use object
        let direction = animationDirection(for: vector)
        // scale bugs
        if direction == .left {
            xScale = abs(xScale)
        } else if direction == .right {
            xScale = abs(xScale)
        }
        // run loop action animate
        run(animations[direction.rawValue], withKey: "animation")
        run(SKAction.sequence([moveBy, moveAgain]))
    }
    
    func die() {
        // remove animation and die bug
        removeAllActions()
        texture = SKTexture(pixelImageNamed: "bug_lt1")
        yScale = -1
        // remove physics body
        physicsBody = nil
        
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 3),
            SKAction.removeFromParent()
        ]))
    }
  
}

extension Bug: Animatable {}
