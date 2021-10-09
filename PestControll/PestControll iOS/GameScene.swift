//
//  GameScene.swift
//  PestControll Shared
//
//  Created by Sabir Myrzaev on 08.10.2021.
//

import SpriteKit



class GameScene: SKScene {
    
    var background: SKTileMapNode!
    var player = Player()
    
    var bugsNode = SKNode()
    var obstaclesTileMap: SKTileMapNode?
    var bugsprayTileMap: SKTileMapNode?
    
    var firebugCount: Int = 0
    
    var hud = HUD()
    
    var timeLimit: Int = 10
    var elapsedTime: Int = 0
    var startTime: Int?
    var currentLevel: Int = 1
    
    var gameState: GameState = .initial {
        didSet {
            hud.updateGameState(from: oldValue, to: gameState)
        }
    }
    // MARK: - Init(coder:)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        background = childNode(withName: "background") as? SKTileMapNode
        obstaclesTileMap = childNode(withName: "obstacles") as? SKTileMapNode
        
        if let timeLimit = userData?.object(forKey: "timeLimit") as? Int {
            self.timeLimit = timeLimit
        }
        let savedGameState = aDecoder.decodeInteger(forKey: "Scene.gameState")
        if let gameState = GameState(rawValue: savedGameState), gameState == .pause {
            self.gameState = gameState
            firebugCount = aDecoder.decodeInteger(forKey: "Scene.firebugCount")
            elapsedTime = aDecoder.decodeInteger(forKey: "Scene.elapsedTime")
            currentLevel = aDecoder.decodeInteger(forKey: "Scene.currentLevel")
            
            player = childNode(withName: "Player") as! Player
            hud = camera!.childNode(withName: "HUD") as! HUD
            bugsNode = childNode(withName: "Bugs")!
            bugsprayTileMap = childNode(withName: "Bugspray") as? SKTileMapNode
        }
        addObserver()
    }
    
    // MARK: - didMove
    override func didMove(to view: SKView) {
        if gameState == .initial {
            addChild(player)
            
            setupWorldPhysics()
            
            createBugs()
            
            setupObstaclePhysics()
            
            if firebugCount > 0 {
                createBugspray(count: firebugCount + 10)
            }
            
            setupHUD()
            gameState = .start
        }
        setupCamera()
    }
    
    // MARK: - Update
    override func update(_ currentTime: TimeInterval) {
        if gameState != .play {
            isPaused = true
            return
        }
        if !player.hasBugspray {
            updateBugspray()
        }
        advanceBreakableTile(locatedAt: player.position)
        
        updateHud(currentTime: currentTime)
        
        checkEndGame()
    }
    
    // MARK: - Touches Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        switch gameState {
        case .start:
            gameState = .play
            isPaused = false
            startTime = nil
            elapsedTime = 0
        case .play:
            player.move(target: touch.location(in: self))
        case .win:
            transitionToScene(level: currentLevel + 1)
        case .lose:
            transitionToScene(level: 1)
        case .reload:
            if let touchedNode = atPoint(touch.location(in: self)) as? SKLabelNode {
                if touchedNode.name == HUDMessages.yes {
                    isPaused = false
                    startTime = nil
                    gameState = .play
                } else if touchedNode.name == HUDMessages.no {
                    transitionToScene(level: 1)
                }
            }
        default:
            break
        }
    }
    
    // MARK: - HUD
    func setupHUD() {
        camera?.addChild(hud)
        hud.addTimer(time: timeLimit)
        hud.addBugCount(with: bugsNode.children.count)

    }
    
    func updateHud(currentTime: TimeInterval) {
        if let startTime = startTime {
            elapsedTime = Int(currentTime) - startTime
        } else {
            startTime = Int(currentTime) - elapsedTime
        }
        hud.updateTimer(time: timeLimit - elapsedTime)
    }
    
    func transitionToScene(level: Int) {
        guard let newScene = SKScene(fileNamed: "Level\(level)") as? GameScene else { fatalError("Level: \(level) not found") }
        newScene.currentLevel = level
        view?.presentScene(newScene, transition: SKTransition.flipVertical(withDuration: 0.5))
    }
    
    func updateBugspray() {
      guard let bugsprayTileMap = bugsprayTileMap else { return }
      let (column, row) = tileCoordinates(in: bugsprayTileMap,
                                          at: player.position)
      if tile(in: bugsprayTileMap, at: (column, row)) != nil {
        bugsprayTileMap.setTileGroup(nil, forColumn: column,
                                     row: row)
        player.hasBugspray = true
      }
    }
    
    func checkEndGame() {
        if bugsNode.children.count == 0 {
            player.physicsBody?.linearDamping = 1
            gameState = .win
        } else if timeLimit - elapsedTime <= 0 {
            player.physicsBody?.linearDamping = 1
            gameState = .lose
        }
    }
    
    // MARK: - camera follows the player
    func setupCamera() {
        guard let camera = camera, let view = view else { return }
        
        let zeroDistance = SKRange(constantValue: 0)
        let playerConstraint = SKConstraint.distance(zeroDistance, to: player)
        
        // наименьшее расстояние от каждого края
        let xInset = min(view.bounds.width/2 * camera.xScale, background.frame.width/2)
        let yInset = min(view.bounds.height/2 * camera.yScale, background.frame.height/2)
        
        // получаем ограничение границы
        let constaintRect = background.frame.insetBy(dx: xInset, dy: yInset)
        
        // устанавливаем ограничение для х и y с нижним и верхним пределом
        let xRange = SKRange(lowerLimit: constaintRect.minX,
                             upperLimit: constaintRect.maxX)
        let yRange = SKRange(lowerLimit: constaintRect.minY,
                             upperLimit: constaintRect.maxY)
        
        let edgeConstraint = SKConstraint.positionX(xRange,  y: yRange)
        edgeConstraint.referenceNode = background
        
        // edgeConstraint имеет более высокий приоритет, т.к. идет последним
        camera.constraints = [playerConstraint, edgeConstraint]
    }
    // bounds screen
    func setupWorldPhysics() {
        background.physicsBody = SKPhysicsBody(edgeLoopFrom: background.frame)
        background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
        physicsWorld.contactDelegate = self
    }
    
    func tile(in tileMap: SKTileMapNode, at coordinates: TileCoordinates) -> SKTileDefinition? {
        return tileMap.tileDefinition(atColumn: coordinates.column, row: coordinates.row)
    }
    
    // create node bugs
    func createBugs() {
        guard let bugsMap = childNode(withName: "bugs") as? SKTileMapNode else { return }
        
        for row in 0 ..< bugsMap.numberOfRows {
            for column in 0 ..< bugsMap.numberOfColumns {
                
                guard let tile = tile(in: bugsMap, at: (column, row)) else { continue }
                
                let bug: Bug
                if tile.userData?.object(forKey: "firebug") != nil {
                    bug = FireBug()
                    firebugCount += 1
                } else {
                    bug = Bug()
                }
                bug.position = bugsMap.centerOfTile(atColumn: column, row: row)
                bugsNode.addChild(bug)
                bug.moveBug()
            }
        }
        bugsNode.name = "Bugs"
        addChild(bugsNode)
        
        bugsMap.removeFromParent()
    }
    
    func createBugspray(count: Int) {
        // create tile with image spray
        let tile = SKTileDefinition (texture: SKTexture(pixelImageNamed: "bugspray"))
        
        // create tileRule with use tile
        let tilerule = SKTileGroupRule(adjacency: SKTileAdjacencyMask.adjacencyAll, tileDefinitions: [tile])
        
        // create group tile with use adjacency
        let tilegroup = SKTileGroup(rules: [tilerule])
        
        // create set tile with use tilegroup
        let tileSet = SKTileSet(tileGroups: [tilegroup])
        
        let columns = background.numberOfColumns
        let rows = background.numberOfRows
        
        // create tile node map
        bugsprayTileMap = SKTileMapNode(tileSet: tileSet, columns: columns, rows: rows, tileSize: tile.size)
        
        // random position spray
        for _ in 1...count {
            let column = Int.random(min: 0, max: columns-1)
            let row = Int.random(min: 0, max: rows-1)
            bugsprayTileMap?.setTileGroup(tilegroup, forColumn: column, row: row)
        }
        
        bugsprayTileMap?.name = "Bugspray"
        addChild(bugsprayTileMap!)
    }
    
    // MARK: - Setup obstacle Phusics
    func setupObstaclePhysics() {
        guard let obstaclesTileMap = obstaclesTileMap else { return }
        
        // create array for save physic body
        var physicsBodies = [SKPhysicsBody]()
        
        for row in 0 ..< obstaclesTileMap.numberOfRows {
            for column in 0 ..< obstaclesTileMap.numberOfColumns {
                guard let tile = tile(in: obstaclesTileMap, at: (column, row)) else { continue }
                
                // Checking tiles for existense
                guard tile.userData?.object(forKey: "obstacle") != nil else { continue }
    
                // create physics body for nodes
                let node = SKNode()
                node.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
                node.physicsBody?.isDynamic = false
                node.physicsBody?.friction = 0
                node.physicsBody?.categoryBitMask = PhysicsCategory.Breakable
                
                node.position = obstaclesTileMap.centerOfTile(atColumn: column, row: row)
                obstaclesTileMap.addChild(node)
            }
        }
    }
    
    // MARK: - tileCoordinates
    func tileCoordinates(in tileMap: SKTileMapNode, at position: CGPoint) -> TileCoordinates {
        let column = tileMap.tileColumnIndex(fromPosition: position)
        let row = tileMap.tileRowIndex(fromPosition: position)
        return (column, row)
    }
    
    func tileGroupForName(tileSet: SKTileSet, name: String) -> SKTileGroup? {
        let tileGroup = tileSet.tileGroups.filter{ $0.name == name }.first
        return tileGroup
    }
    
    func advanceBreakableTile(locatedAt nodePosition: CGPoint) {
        guard let obstaclesTileMap = obstaclesTileMap else { return }
        
        // get column and row
        let (column, row) = tileCoordinates(in: obstaclesTileMap, at: nodePosition)
        
        // get tile at column & row
        let obstacle = tile(in: obstaclesTileMap, at: (column, row))
        
        // get key breakable
        guard let nextTileGroupName = obstacle?.userData?.object(forKey: "breakable") as? String else { return }
        
        // Use helper method for get tile with 2 lvl tile
        if let nextTileGroup = tileGroupForName(tileSet: obstaclesTileMap.tileSet, name: nextTileGroupName) {
            obstaclesTileMap.setTileGroup(nextTileGroup, forColumn: column, row: row)
        }
    }
}

// MARK: - SK PhysycsContact delegate
extension GameScene: SKPhysicsContactDelegate {
    
    func remove(bug: Bug) {
        bug.removeFromParent()
        background.addChild(bug)
        bug.die()
        hud.updateBugCount(with: bugsNode.children.count)
    }
    
    // MARK: - didBegin
    func didBegin(_ contact: SKPhysicsContact) {
        let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
        
        switch other.categoryBitMask {
        case PhysicsCategory.Bug:
            if let bug = other.node as? Bug {
                remove(bug: bug)
                bug.removeFromParent()
                background.addChild(bug)
                bug.die()
            }
        case PhysicsCategory.Firebug:
            if player.hasBugspray {
                if let firebug = other.node as? FireBug {
                    remove(bug: firebug)
                    player.hasBugspray = false
                }
            }
        case PhysicsCategory.Breakable:
            if let obstacleNode = other.node {
                // change obstacle tile
                advanceBreakableTile(locatedAt: obstacleNode.position)
                obstacleNode.removeFromParent()
            }
        default:
            break
        }
        
        if let PhysicsBody = player.physicsBody {
            if PhysicsBody.velocity.length() > 0 {
                player.checkDirection()
            }
        }
    }
    
}

extension GameScene {
    func applicationDidBecomeActive() {
        print("* applicationDidBecomeActive")
    }
    
    func applicationWillResignActive() {
        print("* applicationWillResignActive")
    }
    
    func applicationDidEnterBackground() {
        print("* applicationDidEnterBackground")
    }
    
    func addObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidBecomeActive()
            if self?.gameState != .pause {
                self?.gameState = .reload
            }
        }
        notificationCenter.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationWillResignActive()
            if self?.gameState != .lose {
                self?.gameState = .pause
            }
        }
        notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidEnterBackground()
            if self?.gameState != .lose {
                self?.saveGame()
            }
        }
    }
}

// MARK: - Saving Games
extension GameScene {
    func saveGame() {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let saveURL = directory.appendingPathComponent("SavedGames")
        do {
            try fileManager.createDirectory(atPath: saveURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            fatalError("Failed to create directory: \(error.debugDescription)")
        }
        let fileURL = saveURL.appendingPathComponent("saved-game")
        print("* Saving: \(fileURL.path)")
        NSKeyedArchiver.archiveRootObject(self, toFile: fileURL.path)
    }
    
    override func encode(with coder: NSCoder) {
        coder.encode(firebugCount, forKey: "Scene.firebugCount")
        coder.encode(elapsedTime, forKey: "Scene.elapsedTime")
        coder.encode(gameState.rawValue, forKey: "Scene.gameState")
        coder.encode(currentLevel, forKey: "Scene.currentLevel")
        super.encode(with: coder)
    }
    
    class func loadGame() -> SKScene? {
      print("* loading game")
      var scene: SKScene?
      
      let fileManager = FileManager.default
      guard let directory =
        fileManager.urls(for: .libraryDirectory,
                         in: .userDomainMask).first
        else { return nil }
      
      let url = directory.appendingPathComponent(
        "SavedGames/saved-game")
      
      if FileManager.default.fileExists(atPath: url.path) {
        scene = NSKeyedUnarchiver.unarchiveObject(
          withFile: url.path) as? GameScene
        _ = try? fileManager.removeItem(at: url)
      }
      return scene
    }}
