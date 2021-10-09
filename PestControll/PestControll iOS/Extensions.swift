//
//  Extensions.swift
//  PestControll iOS
//
//  Created by Sabir Myrzaev on 08.10.2021.
//

import SpriteKit

extension SKTexture {
    convenience init(pixelImageNamed: String) {
        self.init(imageNamed: pixelImageNamed)
        self.filteringMode = .nearest
    }
}
