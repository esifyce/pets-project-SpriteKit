//
//  MessageNode.swift
//  CatNap
//
//  Created by Sabir Myrzaev on 06.10.2021.
//

import SpriteKit

class MessageNode: SKLabelNode {
    convenience init(message: String) {
        self.init(fontNamed: "AvenirNext-Regular")
        
        text = message
        fontSize = 256.0
        fontColor = SKColor.gray
        zPosition = 100
        
        let front = SKLabelNode(fontNamed: "AvenirNext-Regular")
        front.text = message
        front.fontSize = 256.0
        front.fontColor = SKColor.white
        front.position = CGPoint(x: -2, y: -2)
        addChild(front)
        
        physicsBody = SKPhysicsBody(circleOfRadius: 10)
        physicsBody!.collisionBitMask = PhysicsCategory.Edge
        physicsBody!.categoryBitMask = PhysicsCategory.Label
        physicsBody!.contactTestBitMask = PhysicsCategory.Edge // challenge 1
        physicsBody!.restitution = 0.7
    }
    
    private var bounceCount = 0
    
    func didBounce() {
        bounceCount += 1
        if bounceCount >= 4 {
            removeFromParent()
        }
    }
}

