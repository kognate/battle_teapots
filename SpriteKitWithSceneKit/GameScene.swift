//
//  GameScene.swift
//  SpriteKitWithSceneKit
//
//  Created by Jonathan Blocksom on 8/20/16.
//  Copyright © 2016 GollyGee Software, Inc. All rights reserved.
//

import SpriteKit
import SceneKit
import GameplayKit

let smokeEmitter = SKEmitterNode(fileNamed: "SmokeParticles.sks")

class GameScene: SKScene {
    
    var gameNode : SK3DNode = SK3DNode(viewportSize: CGSize(width: 150, height: 150.0))
    let playerNode = SK3DNode(viewportSize: CGSize(width: 100.0, height: 100.0))
    
    let enemyTeapotSM = GKStateMachine(states: [Hunting(), Targeting()])
    let enemyTeapotAgent = GKAgent2D()
    let playerAgent = GKAgent2D()
    
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

        
        let player = SCNScene(named: "bluebox.scn")

        playerNode.name = "player"
        //playerNode.position = CGPoint(x: self.frame.midX, y: 0)
        playerNode.position = CGPoint(x: self.frame.midX, y: 150)
        playerAgent.position = vector_float2(Float(playerNode.position.x), Float(playerNode.position.y))
        playerNode.scnScene = player
        self.addChild(playerNode)
        
        // cohere seems to be broken
        let etCohereGoal = GKGoal(toCohereWith: [playerAgent], maxDistance: 10, maxAngle: Float(M_PI))
        
        enemyTeapotAgent.behavior = GKBehavior(goals: [etWanderGoal, etCohereGoal], andWeights: [5,10])
        enemyTeapotAgent.position = vector2(Float(teapotNode.position.x), Float(teapotNode.position.y))
        enemyTeapotAgent.maxAcceleration = 100
        enemyTeapotAgent.maxSpeed = 100
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let loc = firstTouch.location(in: self)
            playerNode.run(SKAction.move(to: loc, duration: 1))
            playerAgent.position = vector_float2( Float(loc.x), Float(loc.y))
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

            if (distance(enemyTeapotAgent.position, playerAgent.position) < 500) {
                enemyTeapotSM.enter(Targeting.self)
                enemyTeapotAgent.behavior?.setWeight(0, for: etWanderGoal)
                enemyTeapotAgent.behavior?.setWeight(10, for: etSeekGoal)
            } else {
                enemyTeapotSM.enter(Hunting.self)
                enemyTeapotAgent.behavior?.setWeight(0, for: etSeekGoal)
                enemyTeapotAgent.behavior?.setWeight(10, for: etWanderGoal)
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
                }
            }
        }

    }
}
