//
//  GameScene.swift
//  ZombieConga
//
//  Created by John Pavley on 11/25/15.
//  Copyright (c) 2015 John Pavley. All rights reserved.
//

/*
    OS calls didMoveToView() when the scene is loading
    OS calls update() every chance it gets
    OS calls touchesBegan() and touchesMoved() when user touches screen
    OS calls init() to calc a universally playable rectable in the center of the screen

    update() calcs lastUpdateTime and calls moveSprite(), boundsCheckZombie(), rotateSprite()
    touchesBegan() and touchesMoved() updates the touchLocation and calls sceneTouched()
    sceneTouched() calls moveZombieToward() which sets touchLocation as the target of the zombie
    moveSprite() moves the zombie with a constant rate towards the target
    boundsCheckZombie() keeps the zombie sprite inside the screen and reverses direction
    rotateSprite() uses basic trig to face the zombie in the direction it is traveling
*/

import SpriteKit

class GameScene: SKScene {
    
    let zombie:SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
    var dt: NSTimeInterval = 0
    var lastUpdateTime: NSTimeInterval = 0
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var lastTouchLocation:CGPoint? // optional until the user touches the screen for the first time
    let attackTouchFlag = false
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        
        backgroundColor = SKColor.blackColor()
        
        let background = SKSpriteNode(imageNamed: "background1")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1 // keep it under every other sprite
        addChild(background)
        
        let mySize = background.size
        print("size: \(mySize)")
        
        zombie.position = CGPoint(x: 400, y: 400)
        addChild(zombie)
        spawnEnemy()
        
        debugDrawPlayableArea()
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        if !isSpriteMoving() {
            // if the sprite is stationary save some CPU cycles
            return
        }
        
        if attackTouchFlag {
            if let lastTouchLocation = lastTouchLocation {
                // if the user has not yet touched the screen none of this code will execute
                let distanceToLastTouch = lastTouchLocation - zombie.position
                let distanceSpriteWillMove = zombieMovePointsPerSec * CGFloat(dt)
                
                if distanceToLastTouch.length() <= distanceSpriteWillMove {
                    zombie.position = lastTouchLocation
                    velocity = CGPointZero
                } else {
                    moveSprite(zombie, velocity: velocity)
                    rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
                }
            }
        } else {
            moveSprite(zombie, velocity: velocity)
            rotateSprite(zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            boundsCheckZombie()
        }
        
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        let offset = location - zombie.position
        
        let direction = offset.normalize()
        velocity = direction * zombieMovePointsPerSec
        
        
    }
    
    func isSpriteMoving() -> Bool {
        var result = false
        if velocity != CGPointZero {
            result = true
        }
        return result
    }
    
    // touches
    
    func sceneTouched(touchLocation: CGPoint) {
        lastTouchLocation = touchLocation
        
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
        let bottomLeft = CGPoint(x: 0, y: CGRectGetMinY(playableRect))
        let topRight = CGPoint(x: size.width, y: CGRectGetMaxY(playableRect))
        
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
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        // this works because initially zombie is facing to the right
        
        let shortest = shortestAngleBetween(sprite.zRotation, angle2: direction.angle)
        var amtToRotate = zombieRotateRadiansPerSec * CGFloat(dt)
        
        if abs(shortest) < amtToRotate {
            amtToRotate = abs(shortest)
        }
        
        sprite.zRotation += amtToRotate * shortest.sign()
    }
    
    func spawnEnemy() {
        
        // create
        let enemy = SKSpriteNode(imageNamed: "enemy")
        let enemyCenterX = enemy.size.width / 2
        let enemyCenterY = enemy.size.height / 2
        enemy.position = CGPoint(
            x: size.width + enemyCenterX,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemyCenterY,
                max: CGRectGetMaxY(playableRect) - enemyCenterY))
        addChild(enemy)
        
        // move
        
        let actionMove = SKAction.moveToX(-enemyCenterX, duration: 2.0)
        enemy.runAction(actionMove)
    }
    
    // debug functions
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
}
