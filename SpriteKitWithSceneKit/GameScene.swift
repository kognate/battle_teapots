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
    
    override func didMove(to view: SKView) {
        
        if true {
            let newScene = SCNScene()
            let geom = SCNBox(width: 10.0, height: 10.0, length: 10.0, chamferRadius: 0.5)
            let geomNode = SCNNode(geometry: geom)
            newScene.rootNode.addChildNode(geomNode)
            
            let camNode = SCNNode()
            camNode.camera = SCNCamera()
            camNode.position = SCNVector3Make(0.0, 10.0, 20.0)
            camNode.rotation = SCNVector4Make(1.0, 0.0, 0.0, -atan2f(10.0, 20.0))
            newScene.rootNode.addChildNode(camNode)
            
            let lightBlue = UIColor(colorLiteralRed: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
            let light = SCNLight()
            light.type = .directional
            light.color = lightBlue
            let lightNode = SCNNode()
            lightNode.light = light
            camNode.addChildNode(lightNode)

            gameNode.position = CGPoint(x: 0.0, y: 250.0)
            gameNode.scnScene = newScene
            self.addChild(gameNode)
            geomNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0.01, z: 0, duration: 1.0 / 60.0)))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let firstTouch = touches.first {
            let loc = firstTouch.location(in: self)
            gameNode.run(SKAction.move(to: loc, duration: 1))
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
