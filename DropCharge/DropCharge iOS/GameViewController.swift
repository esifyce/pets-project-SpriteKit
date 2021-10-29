//
//  GameViewController.swift
//  DropCharge iOS
//
//  Created by Sabir Myrzaev on 10.10.2021.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let view = self.view as! SKView? {
      // Load the SKScene from 'GameScene.sks'
        let scene = GameScene.init(fileNamed: "GameScene")
        // Set the scale mode to scale to fit the window
        scene?.scaleMode = .aspectFill
        
        // Present the scene
        view.presentScene(scene)
      
      view.ignoresSiblingOrder = true
      
      view.showsFPS = true
      view.showsNodeCount = true
      view.showsPhysics = true
    }
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
}
