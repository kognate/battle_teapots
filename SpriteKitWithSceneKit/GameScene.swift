//
//  GameScene.swift
//  SpriteKitWithSceneKit
//
import SpriteKit
import SceneKit
import GameplayKit

let smokeEmitter = SKEmitterNode(fileNamed: "SmokeParticles.sks")

let randomDistribution = GKRandomDistribution(lowestValue: 0, highestValue: 200)

let shootSound = SKAction.playSoundFileNamed("pew.m4a", waitForCompletion: false)
let explosionSound = SKAction.playSoundFileNamed("explosion.m4a", waitForCompletion: false)

class GameScene: SKScene {
    
    var gameNode : SK3DNode = SK3DNode(viewportSize: CGSize(width: 150, height: 150.0))
    
    let enemyTeapotSM = GKStateMachine(states: [Hunting(), Targeting()])
    let enemyTeapotAgent = GKAgent2D()
    let playerAgent = GKAgent2D()
    var score = 0
    
    let etWanderGoal = GKGoal(toWander: 30)
    var etSeekGoal = GKGoal()
    
    private var lastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
        etSeekGoal = GKGoal(toInterceptAgent: playerAgent, maxPredictionTime: 1)
    }
    
    override func didMove(to view: SKView) {
        let teapotScene = SCNScene(named: "teapot.scn")
        let teapotNode = SK3DNode(viewportSize: CGSize(width: 200.0, height: 200.0))
        teapotNode.name = "enemy teapot"
        teapotNode.position = CGPoint(x: self.frame.maxX - 150, y: self.frame.maxY - 150)
        teapotNode.scnScene = teapotScene
        
        // rotation bug workaround
        teapotNode.run(SKAction.repeatForever(SKAction.rotate(byAngle: 0, duration: 0.5)))
        
        self.addChild(teapotNode)
        
        enemyTeapotSM.enter(Hunting.self)

        
        setupPlayer(location: CGPoint(x: self.frame.midX, y: 150))
        
//        let areaConstraint = SKConstraint.distance(SKRange(upperLimit: 600), to: CGPoint(x: CGFloat(self.frame.midX), y: CGFloat(self.frame.midY)))
//        teapotNode.constraints = [ areaConstraint ]
        
        // cohere seems to be broken
        let etCohereGoal = GKGoal(toCohereWith: [playerAgent], maxDistance: 10, maxAngle: Float(M_PI))
        
        enemyTeapotAgent.behavior = GKBehavior(goals: [etWanderGoal, etCohereGoal], andWeights: [5,10])
        enemyTeapotAgent.position = vector2(Float(teapotNode.position.x), Float(teapotNode.position.y))
        enemyTeapotAgent.maxAcceleration = 100
        enemyTeapotAgent.maxSpeed = 100
        
    }
    
    func setupPlayer(location: CGPoint) {
        let playerNode = SK3DNode(viewportSize: CGSize(width: 100.0, height: 100.0))

        let player = SCNScene(named: "bluebox.scn")

        playerNode.name = "player"
        //playerNode.position = CGPoint(x: self.frame.midX, y: 0)
        playerNode.position = location
        playerAgent.position = vector_float2(Float(playerNode.position.x), Float(playerNode.position.y))
        playerNode.scnScene = player
        self.addChild(playerNode)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let loc = firstTouch.location(in: self)
            if let playerNode = self.childNode(withName: "player") {
                playerNode.run(SKAction.move(to: loc, duration: 1))
                playerAgent.position = vector_float2( Float(loc.x), Float(loc.y))
            } else {
                setupPlayer(location: loc);
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {

        // Initialize _lastUpdateTime if it has not already been
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        self.lastUpdateTime = currentTime
        
        enemyTeapotSM.update(deltaTime: dt)
        enemyTeapotAgent.update(deltaTime: dt)
        
        if let enemyTeapot = self.childNode(withName: "enemy teapot") {
            enemyTeapot.position = CGPoint(x: CGFloat(enemyTeapotAgent.position.x), y: CGFloat(enemyTeapotAgent.position.y))

            if enemyTeapotAgent.position.x <= 10 || enemyTeapotAgent.position.x >= Float(self.size.width) - 10 || enemyTeapotAgent.position.y <= 10 || enemyTeapotAgent.position.y >= Float(self.size.height) - 10 {

                targetPlayer()
                return
            }

            if (distance(enemyTeapotAgent.position, playerAgent.position) < 500) {
                targetPlayer()
                
                if let _ = self.childNode(withName: "torpedo") {
                    
                } else {
                    let ift = SKSpriteNode(imageNamed: "spark.png")
                    ift.name = "torpedo"
                    ift.position = enemyTeapot.position
                    self.addChild(ift)
                    var x_1 = Float(randomDistribution.nextInt() - 100) / 100.0
                    var x_2 = Float(randomDistribution.nextInt() - 100) / 100.0
                    
                    while (x_1 * x_1) + (x_2 * x_2) >= 1 {
                       x_1 = Float(randomDistribution.nextInt() - 100) / 100.0
                       x_2 = Float(randomDistribution.nextInt() - 100) / 100.0
                    }
                    
                    let x = (pow(x_1,2) - pow(x_2,2)) / (pow(x_1,2) + pow(x_2,2))
                    let y = (2 * x_1 * x_2) / (pow(x_1,2) + pow(x_2,2))
                    ift.run(SKAction.sequence([shootSound, SKAction.move(to: CGPoint(x: CGFloat(x * 600.0), y: CGFloat(y * 600)), duration: 1),SKAction.removeFromParent()]))
                }
                
            } else {
                huntPlayer()
            }
        }
        
        if let player = self.childNode(withName: "player") {
            for node in self.nodes(at: player.position) {
                if (node.name == "powerUp") {
                    let puff = smokeEmitter!.copy() as! SKEmitterNode
                    self.addChild(puff)
                    puff.position = node.position
                    puff.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.run {
                        puff.particleBirthRate = 0
                        }, SKAction.wait(forDuration: 1), SKAction.removeFromParent()]))
                    node.removeFromParent()
                    score = score + 1
                } else if (node.name == "torpedo" || node.name == "enemy teapot") {
                    let puff = smokeEmitter!.copy() as! SKEmitterNode
                    puff.position = player.position
                    player.removeFromParent()
                    puff.run(SKAction.sequence([SKAction.wait(forDuration: 1), SKAction.run {
                        puff.particleBirthRate = 0
                        }, SKAction.wait(forDuration: 1), SKAction.removeFromParent()]))
                    score = score - 1
                    run(explosionSound)
                }
            }
        }
        
        if self.childNode(withName: "powerUp") == nil {
            resetPowerUps()
        }
        if let scoreLabel = self.childNode(withName: "score") as? SKLabelNode {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    func resetPowerUps() {
        for _ in 1...5 {
            let pu = SKSpriteNode(imageNamed: "Spaceship.png")
            pu.size = CGSize(width: 92.0, height: 112.0)
            pu.name = "powerUp"
            self.addChild(pu)
            let randValX = randomDistribution.nextUniform()
            let randValY = randomDistribution.nextUniform()
            pu.zRotation = CGFloat(randValX * Float(2.0 * M_PI))
            pu.position = CGPoint(x: CGFloat(randValX) * self.frame.maxX, y: CGFloat(randValY) * self.frame.maxY)
        }
    }
}

// MARK: - Helpers

extension GameScene {

    func targetPlayer() {
        if enemyTeapotSM.currentState is Targeting {
            return
        }
        print("Switching to Targeting Player (seeking)")
        enemyTeapotSM.enter(Targeting.self)
        enemyTeapotAgent.behavior?.setWeight(0, for: etWanderGoal)
        enemyTeapotAgent.behavior?.setWeight(10, for: etSeekGoal)
    }

    func huntPlayer() {
        if enemyTeapotSM.currentState is Hunting {
            return
        }
        print("Switching to Hunting player (wandering)")
        enemyTeapotSM.enter(Hunting.self)
        enemyTeapotAgent.behavior?.setWeight(0, for: etSeekGoal)
        enemyTeapotAgent.behavior?.setWeight(10, for: etWanderGoal)
    }

}
