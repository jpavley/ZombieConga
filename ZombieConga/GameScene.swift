//
//  GameScene.swift
//  ZombieConga
//
//  Created by John Pavley on 11/25/15.
//  Copyright (c) 2015 John Pavley. All rights reserved.
//

/*
    OS calls didMoveToView() when the scene is loading.
    OS calls update() every chance it gets.
    OS calls touchesBegan() and touchesMoved() when user touches screen.

    update() calcs lastUpdateTime and calls moveSprite()
    touchesBegan() and touchesMoved() updates the touchLocation and calls sceneTouched()
    sceneTouched() calls moveZombieToward() which sets touchLocation as the target of the zombie
    moveSprite() moves the zombie with a constant rate towards the target
    boundsCheckZombie() keeps the zombie sprite inside the screen and reverses direction
*/

import SpriteKit

class GameScene: SKScene {
    
    let zombie:SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
    var dt: NSTimeInterval = 0
    var lastUpdateTime: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    
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
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        //print("\(dt*1000) milliseconds since last update")
        
        //zombie.position = CGPoint(x: zombie.position.x + 8, y: zombie.position.y)
        moveSprite(zombie, velocity: velocity)
        boundsCheckZombie()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        //print("Amount to move: \(amountToMove)")
        
        sprite.position = CGPoint(
            x: sprite.position.x + amountToMove.x,
            y: sprite.position.y + amountToMove.y)
    }
    
    func moveZombieToward(location: CGPoint) {
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        
        
    }
    
    // touches
    
    func sceneTouched(touchLocation: CGPoint) {
        moveZombieToward(touchLocation)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        sceneTouched(touchLocation)
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint.zero
        let topRight = CGPoint(x: size.width, y: size.height)
        
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
}
