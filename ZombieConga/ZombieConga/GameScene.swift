//
//  GameScene.swift
//  ZombieConga
//
//  Created by Sabir Myrzaev on 04.10.2021.
//

import  SpriteKit

class GameScene: SKScene {
  
  let zombie = SKSpriteNode(imageNamed: "zombie1")
  var lastUpdateTime: TimeInterval = 0
  var dt: TimeInterval = 0
  let zombieMovePointsPerSec: CGFloat = 480.0
  var velocity = CGPoint.zero
  let playableRect: CGRect
  var lastTouchLoaction: CGPoint?
  let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
  let zombieAnimation: SKAction
  var invincible = false
  let catMovePointPerSec: CGFloat = 480.0
  var lives = 5
  var gameOver = false
  let cameraNode = SKCameraNode()
  let cameraMovePointsPerSec: CGFloat = 200.0
  
  let livesLabel = SKLabelNode(fontNamed: "Glimstick")
  let catsLabel = SKLabelNode(fontNamed: "Glimstick")
  
  let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
  let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
  
  
  override init(size: CGSize) {
    // aspectRatio from 3:2 to 16:9
    let maxAspectRatio: CGFloat = 16.0 / 9.0
    let playableHeight = size.width / maxAspectRatio
    let playableMargin = (size.height - playableHeight) / 2.0
    playableRect = CGRect(x: 0,
                          y: playableMargin,
                          width: size.width,
                          height: playableHeight)
    
    
    var textures: [SKTexture] = []
    for i in 1...4 {
      textures.append(SKTexture(imageNamed: "zombie\(i)"))
    }
    textures.append(textures[2])
    textures.append(textures[1])
    
    zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
    super.init(size: size)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - debug Draw Playable Area
  func debugDrawPlayableArea() {
    let shape = SKShapeNode(rect: playableRect)
    shape.strokeColor = SKColor.red
    shape.lineWidth = 4.0
    addChild(shape)
  }
  
  // MARK: - didMove
  override func didMove(to view: SKView) {
    backgroundColor = SKColor.black

    // infinity background
    for i in 0...1 {
      let background = backgroundNode()
      background.anchorPoint = CGPoint.zero
      background.position = CGPoint(x: CGFloat(i) * background.size.width,
                                    y: 0)
      background.name = "background"
      background.zPosition = -1
      addChild(background)
    }

    zombie.position = CGPoint(x: 400, y: 400)
    zombie.zPosition = 100
    addChild(zombie)
   // zombie.run(SKAction.repeatForever(zombieAnimation))
    
    // Enemy action + spawn
    run(SKAction.repeatForever(SKAction.sequence([SKAction.run() { [weak self] in
      self?.spawnEnemy()
    }, SKAction.wait(forDuration: 2.0)])))
    // Cat action + spawn
    run(SKAction.repeatForever(SKAction.sequence([SKAction.run() { [weak self] in
      self?.spawnCat()
    }, SKAction.wait(forDuration: 1.0)])))
    
     // let mySize = background.size
    //    print("Размер фона: \(mySize)")
   // debugDrawPlayableArea()
    
    playBackgroundMusic(filename: "backgroundMusic.mp3")

    
    addChild(cameraNode)
    camera = cameraNode
    cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
    
    
    livesLabel.text = "Lives: X"
    livesLabel.fontColor = SKColor.black
    livesLabel.fontSize = 100
    livesLabel.zPosition = 150
    livesLabel.horizontalAlignmentMode = .left
    livesLabel.verticalAlignmentMode = .bottom
    livesLabel.position = CGPoint(x: -playableRect.size.width/2 + CGFloat(20),
                                  y: -playableRect.size.height/2 + CGFloat(20))
    cameraNode.addChild(livesLabel)
    
    catsLabel.text = "Cats: X"
    catsLabel.fontColor = SKColor.black
    catsLabel.fontSize = 100
    catsLabel.zPosition = 150
    catsLabel.horizontalAlignmentMode = .right
    catsLabel.verticalAlignmentMode = .bottom
    catsLabel.position = CGPoint(x: playableRect.size.width/2 - CGFloat(40),
                                  y: -playableRect.size.height/2 + CGFloat(40))
    cameraNode.addChild(catsLabel)
    
  }
  
  // MARK: - Update
  override func update(_ currentTime: TimeInterval) {
    if lastUpdateTime > 0 {
      dt = currentTime - lastUpdateTime
    } else {
      dt = 0
    }
    lastUpdateTime = currentTime
    //print("\(dt * 1000) миллисекунд с момента последнего обновления")
    // stop move on finish touch
  //  if let lastTouchLoaction = lastTouchLoaction {
   //   let diff = lastTouchLoaction - zombie.position
   //   if diff.length() <= zombieMovePointsPerSec * CGFloat(dt) {
   //     zombie.position = lastTouchLoaction
    //    velocity = CGPoint.zero
   //     stopZombieAnimation()
   //   } else {
        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
    //  }
    //}
    boundsCheckZombie()
    
    moveTrain()
    moveCamera()
    livesLabel.text = "Lives: \(lives)"
    
    if lives <= 0 && !gameOver {
      gameOver = true
      print("You lose!")
      backgroundMusicPlayer.stop()
      let gameOverScene = GameOverScene(size: size, won: false)
      gameOverScene.scaleMode = scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      view?.presentScene(gameOverScene, transition: reveal)
    }
    //cameraNode.position = zombie.position
  }
  
  override func didEvaluateActions() {
    checkCollisions()
  }
  
  // MARK: - move sprite
  func move(sprite: SKSpriteNode, velocity: CGPoint) {
    let amountToMove = velocity * CGFloat(dt)
    //print("Amount to move: \(amountToMove)")
    sprite.position += amountToMove
  }
  func moveZombieToward(location: CGPoint) {
    startZombieAnimation()
    let offset = location - zombie.position
    let direction = offset.normalized()
    velocity = direction * zombieMovePointsPerSec
  }
  
  // MARK: - Move Camera Background
  func moveCamera() {
    let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
    let amountToMove = backgroundVelocity * CGFloat(dt)
    cameraNode.position += amountToMove
    
    enumerateChildNodes(withName: "background") { node, _ in
      let background = node as! SKSpriteNode
      if background.position.x + background.size.width < self.cameraRect.origin.x {
        background.position = CGPoint(x: background.position.x + background.size.width * 2,
                                      y: background.position.y)
        }
      }
  }
  
  // MARK: - Rotate sprite
  func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
    let shortest = shortestAngleBetween(angle1: sprite.zRotation , angle2: velocity.angle)
    let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
    sprite.zRotation += shortest.sign() * amountToRotate
  }
  
  // MARK: - Enemy sprite
  func spawnEnemy() {
    let enemy = SKSpriteNode(imageNamed: "enemy")
    enemy.name = "enemy"
    enemy.position = CGPoint(x: cameraRect.maxX + enemy.size.width/2, y: CGFloat.random(
                              min: cameraRect.minY + enemy.size.height / 2,
                              max: cameraRect.maxY - enemy.size.height / 2))
    addChild(enemy)
    
    // action enemy
    let actionMove = SKAction.moveBy(x: -(size.width + enemy.size.width), y: 0, duration: 2.0)
    let actionRemove = SKAction.removeFromParent()
    enemy.run(SKAction.sequence([actionMove,actionRemove]))
  }
  
  // MARK: - Cat sprite
  func spawnCat() {
    // Create cat
    let cat = SKSpriteNode(imageNamed: "cat")
    cat.name = "cat"
    cat.position = CGPoint(x: CGFloat.random(min: cameraRect.minX,
                                             max: cameraRect.maxX),
                           y: CGFloat.random(min: cameraRect.minY,
                                             max: cameraRect.maxY))
    cat.zPosition = 50
    cat.setScale(0)
    addChild(cat)
    
    // Cat action
    let appear = SKAction.scale(to: 1.0, duration: 0.5)
    cat.zRotation = -π / 16.0
    let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
    let rightWiggle = leftWiggle.reversed()
    let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
   // let wiggleWait = SKAction.repeat(fullWiggle, count: 10)
    let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
    let scaleDown = scaleUp.reversed()
    let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
    let group = SKAction.group([fullScale, fullWiggle])
    let groupWAit = SKAction.repeat(group, count: 10)
    let disappear = SKAction.scale(to: 0, duration: 0.5)
    let removeFromParent = SKAction.removeFromParent()
    let actions = [appear, groupWAit, disappear, removeFromParent]
    cat.run(SKAction.sequence(actions))
  }
  
  // MARK: - Physycs sprite
  func zombieHit(cat: SKSpriteNode) {
    cat.name = "train"
    cat.removeAllActions()
    cat.setScale(1.0)
    cat.zRotation = 0
    
    let turnGreen = SKAction.colorize(with: SKColor.green,
                                      colorBlendFactor: 1.0,
                                      duration: 0.2)
    cat.run(turnGreen)
    
    run(catCollisionSound)
  }
  func zombieHit(enemy: SKSpriteNode) {
    invincible = true
    let blinkTimes = 10.0
    let duration = 3.0
    let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
      let slice = duration / blinkTimes
      let remainder = Double(elapsedTime).truncatingRemainder(dividingBy: slice)
      node.isHidden = remainder > slice / 2
    }
    let setHidden = SKAction.run() { [weak self] in
      self?.zombie.isHidden = false
      self?.invincible = false
    }
    zombie.run(SKAction.sequence([blinkAction, setHidden]))
    run(enemyCollisionSound)
    
    loseCats()
    lives -= 1
    //enemy.removeFromParent()
  }
  // MARK: - Collisions
  func checkCollisions() {
    var hitsCats: [SKSpriteNode] = []
    enumerateChildNodes(withName: "cat") { node, _ in
      let cat = node as! SKSpriteNode
      if cat.frame.intersects(self.zombie.frame) {
        hitsCats.append(cat)
      }
    }
    for cat in hitsCats {
      zombieHit(cat: cat)
    }
    
    if invincible {
      return
    }
    
    var hitEnemies: [SKSpriteNode] = []
    enumerateChildNodes(withName: "enemy") { node, _ in
      let enemy = node as! SKSpriteNode
      if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
        hitEnemies.append(enemy)
      }
    }
    for enemy in hitEnemies {
      zombieHit(enemy: enemy)
    }
  }
  
  // MARK: - Run & Stop Zombie Animation
  func startZombieAnimation() {
    if zombie.action(forKey: "animtaion") == nil {
      zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
    }
  }
  func stopZombieAnimation() {
    zombie.removeAction(forKey: "animation")
  }
  
  // MARK: - Bounds screen
  func boundsCheckZombie() {
    let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
    let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
    
    if zombie.position.x <= bottomLeft.x {
      zombie.position.x = bottomLeft.x
      velocity.x = -velocity.x
    }
    if zombie.position.x >= topRight.x {
      zombie.position.x = topRight.x
      velocity.x = -velocity.x
    }
    if zombie.position.y <= bottomLeft.y {
      zombie.position.y = bottomLeft.y
      velocity.y = -velocity.y
    }
    if zombie.position.y >= topRight.y {
      zombie.position.y = topRight.y
      velocity.y = -velocity.y
    }
  }
  
  // MARK: - Move Train
  func moveTrain() {
    var trainCount = 0
    var targetPosition = zombie.position
    
    enumerateChildNodes(withName: "train") { node, stop in
      trainCount += 1
      if !node.hasActions() {
        let actionDuration = 0.3
        let offset = targetPosition - node.position
        let direction = offset.normalized()
        let amountToMovePerSec = direction * self.catMovePointPerSec
        let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
        let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration)
        node.run(moveAction)
      }
      targetPosition = node.position
    }
    if trainCount >= 15 && !gameOver {
      backgroundMusicPlayer.stop()
      let gameOverScene = GameOverScene(size: size, won: true)
      gameOverScene.scaleMode = scaleMode
      let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
      view?.presentScene(gameOverScene, transition: reveal)
      print("Вы выйграли!")
    }
    catsLabel.text = "Cats: \(trainCount)"

  }
  
  // MARK: - Lose cats in Conga
  func loseCats() {
    
    var loseCount = 0
    enumerateChildNodes(withName: "train") { node, stop in
      var randomSpot = node.position
      // находим случайное смещение от текущего положения кошки
      randomSpot.x += CGFloat.random(min: -100, max: 100)
      randomSpot.y += CGFloat.random(min: -100, max: 100)
      // запускаем небольшую анимацию, чтобы кошка двигалась к случайному месту
      node.name = ""
      node.run(
        SKAction.sequence([
          SKAction.group([
            SKAction.rotate(byAngle: π*4, duration: 1.0),
            SKAction.move(to: randomSpot, duration: 1.0),
            SKAction.scale(to: 0, duration: 1.0)
          ]),
          SKAction.removeFromParent()
        ]))
      // обновляем переменную, отслеживающую количество кошек, которых вы удалили из линии конги
      loseCount += 1
      if loseCount >= 2 {
        stop[0] = true
      }
    }
  }
  
  // MARK: - Merge 2 background
  func backgroundNode() -> SKSpriteNode {
    
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"
    
    let background1 = SKSpriteNode(imageNamed: "background1")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    let background2 = SKSpriteNode(imageNamed: "background2")
    background2.anchorPoint = CGPoint.zero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
    
    backgroundNode.size = CGSize(width: background1.size.width + background2.size.width,
                                 height: background1.size.height)
    return backgroundNode
  }
  
  // MARK: - Hooking up to touch events
  func sceneTouched(touchLocation: CGPoint) {
    lastTouchLoaction = touchLocation
    moveZombieToward(location: touchLocation)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let touchLocation = touch.location(in: self)
    sceneTouched(touchLocation: touchLocation)
  }

// visible game area
var cameraRect: CGRect {
  let x = cameraNode.position.x - size.width/2 + (size.width - playableRect.width) / 2
  let y = cameraNode.position.y - size.height/2 + (size.height - playableRect.height) / 2
  return CGRect(x: x, y: y, width: playableRect.width, height: playableRect.height)
  }
}
