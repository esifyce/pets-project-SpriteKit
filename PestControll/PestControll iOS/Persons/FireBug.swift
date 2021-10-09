//
//  FireBug.swift
//  PestControll iOS
//
//  Created by Sabir Myrzaev on 09.10.2021.
//

import SpriteKit

class FireBug: Bug {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
        name = "Firebug"
        color = .red
        colorBlendFactor = 0.8
        physicsBody?.categoryBitMask = PhysicsCategory.Firebug
    }
}
