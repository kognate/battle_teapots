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

class GameScene: SKScene {
    
    var gameNode : SK3DNode = SK3DNode(viewportSize: CGSize(width: 150, height: 150.0))
    let enemyTeapotSM = GKStateMachine(states: [Hunting(), Targeting(), Firing(), Reloading(), Destroyed()])
    let enemyTeapotAgent = GKAgent2D()
    
    let etWanderGoal = GKGoal(toWander: 30)
    let etReachSpeed = GKGoal(toReachTargetSpeed: 20.0)
    
    private var lastUpdateTime : TimeInterval = 0
    
    override func sceneDidLoad() {
        self.lastUpdateTime = 0
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

        enemyTeapotAgent.behavior = GKBehavior(goals: [etWanderGoal], andWeights: [5])
        enemyTeapotAgent.position = vector2(Float(teapotNode.position.x), Float(teapotNode.position.y))
        enemyTeapotAgent.maxAcceleration = 10
        enemyTeapotAgent.maxSpeed = 30
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let loc = firstTouch.location(in: self)
            gameNode.run(SKAction.move(to: loc, duration: 1))
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
        }
    }
}
