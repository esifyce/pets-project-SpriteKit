//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Sabir Myrzaev on 05.10.2021.
//  Copyright © 2021 Ray Wenderlich. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
  
  override func didMove(to view: SKView) {
    var background: SKSpriteNode
    background = SKSpriteNode(imageNamed: "MainMenu")
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    addChild(background)
  }
  
  // MARK: - Hooking up to touch events
  func sceneTapped() {
    // back to maun GameScene
      let myScene = GameScene(size: size)
      myScene.scaleMode = scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 1.5)
      view?.presentScene(myScene, transition: reveal)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    sceneTapped()
  }
}
