//
//  GameScene.swift
//  Spacegame
//
//  Created by 楊振東 on 2021/8/18.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    var startfield: SKEmitterNode!
    var player: SKSpriteNode!
    var scoreLabel : SKLabelNode!
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer: Timer!
    
    var possibleAliens = ["alien", "alien2", "alien3","alien4", "alien5", "alien6","alien7", "alien8", "alien9","alien10", "alien11"]
    
    let alienCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    
    override func didMove(to view: SKView) {
        startfield = SKEmitterNode(fileNamed: "Starfield")
        startfield.position = CGPoint(x: 0, y: 1472)
        startfield.advanceSimulationTime(10)
        self.addChild(startfield)
        
        startfield.zPosition = -1
        
        player = SKSpriteNode(imageNamed: "shuttle")
        
        player.position = CGPoint(x: 0 , y: player.size.height / 2 - 500)
        player.size = CGSize(width: 100.0, height: 100.0)
        self.addChild(player)
        
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: -280, y: frame.size.height - 850)
        scoreLabel.fontName = "AmericanTypewriter-Bold"
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = UIColor.white
        score = 0
        self.addChild(scoreLabel)
    
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error: Error?) in
            if let accelerometerData = data {
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x) * 0.75 + self.xAcceleration * 0.25
            }
        }
        
       
        }
    
    @objc func addAlien() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        
        let randomAlienPostion = GKRandomDistribution(lowestValue: -414, highestValue: 414)
        let postion = CGFloat(randomAlienPostion.nextInt())
        alien.position = CGPoint(x: postion, y: self.frame.size.height + alien.size.height)
        alien.size = CGSize(width: 100.0, height: 80.0)
        
        alien.physicsBody = SKPhysicsBody(circleOfRadius: max(alien.size.width / 2, alien.size.height / 2 ))
        alien.physicsBody? .isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        print(alien.size)
        
        self.addChild(alien)
        
        let animationDuration: TimeInterval = 5
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: postion, y: -alien.size.height - 500), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        alien.run(SKAction.sequence(actionArray))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    func fireTorpedo() {
        self.run(SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false))
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.size = CGSize(width: 60.0, height: 60.0)
        torpedoNode.position = player.position
        torpedoNode.position.y += 5
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask = alienCategory
        torpedoNode.physicsBody?.collisionBitMask = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(torpedoNode)
        
        let animationDuration: TimeInterval = 0.5
        
        
        var actionArray = [SKAction]()
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.height + 10), duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        torpedoNode.run(SKAction.sequence(actionArray))
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedoNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
        
    }
    
    func torpedoDidCollideWithAlien (torpedoNode: SKSpriteNode, alienNode: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alienNode.position
        self.addChild(explosion)
        self.run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        torpedoNode.removeFromParent()
        alienNode.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2)) {
            explosion.removeFromParent()
        }
        
        score += 5
        
        
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 40
        if player.position.x < -350 {
            player.position = CGPoint(x: self.size.width + 20, y: player.position.y)
        } else if player.position.x > self.size.width + 20 {
            player.position = CGPoint(x: -350, y: player.position.y)
        }
    }
        
     
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
