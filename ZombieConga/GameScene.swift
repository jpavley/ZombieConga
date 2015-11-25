//
//  GameScene.swift
//  ZombieConga
//
//  Created by John Pavley on 11/25/15.
//  Copyright (c) 2015 John Pavley. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let zombie:SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
    
    override func didMoveToView(view: SKView) {
        
        backgroundColor = SKColor.blackColor()
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        //background.anchorPoint = CGPoint.zero
        //background.position = CGPoint.zero
        //background.zRotation = CGFloat(M_PI) / 16
        background.zPosition = -1
        addChild(background)
        
        let mySize = background.size
        print("size: \(mySize)")
        
        zombie.position = CGPoint(x: 400, y: 400)
        //zombie.setScale(2.0)
        addChild(zombie)
        
    }
    
    override func update(currentTime: NSTimeInterval) {
        zombie.position = CGPoint(x: zombie.position.x + 8, y: zombie.position.y)
    }
}
