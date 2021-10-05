//
//  GameViewController.swift
//  ActionCatalogs
//
//  Created by Sabir Myrzaev on 04.10.2021.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let scene = MoveScene(size:CGSize(width: 1024, height: 768))
    let skView = self.view as! SKView
    skView.showsFPS = false
    skView.showsNodeCount = false
    skView.ignoresSiblingOrder = true
    scene.scaleMode = .aspectFill
    skView.presentScene(scene)
    
  }
  
}

