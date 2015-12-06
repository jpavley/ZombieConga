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
    
    // properties
    
    let zombie:SKSpriteNode = SKSpriteNode(imageNamed: "zombie1")
    var dt: NSTimeInterval = 0
    var lastUpdateTime: NSTimeInterval = 0
    
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec: CGFloat = 4.0 * π
    
    let catMovePointsPerSec: CGFloat = 480.0
    
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var lastTouchLocation:CGPoint? // optional until the user touches the screen for the first time
    let attackTouchFlag = true
    
    let zombieAnimation: SKAction
    
    let catCollisionSound = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    var zombieInvinciable = false
    
    // functions
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0 / 9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        
        // setup animations
        var textures:[SKTexture] = []
        
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)
        
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
        zombie.zPosition = 100
        addChild(zombie)
        
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.runBlock(spawnEnemy),
            SKAction.waitForDuration(2.0)])))
        
        runAction(SKAction.repeatActionForever(SKAction.sequence([
            SKAction.runBlock(spawnCat),
            SKAction.waitForDuration(1.0)])))
        
        debugDrawPlayableArea()
    }
    
    override func update(currentTime: NSTimeInterval) {
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        if attackTouchFlag {
            if let lastTouchLocation = lastTouchLocation {
                // if the user has not yet touched the screen none of this code will execute
                let distanceToLastTouch = lastTouchLocation - zombie.position
                let distanceSpriteWillMove = zombieMovePointsPerSec * CGFloat(dt)
                
                if distanceToLastTouch.length() <= distanceSpriteWillMove {
                    zombie.position = lastTouchLocation
                    velocity = CGPointZero
                    stopZombieAnimation()
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
        
        // have to check for collisions after the actions are evaluated
        //checkCollisions()
        moveTrain()
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        
        let offset = location - zombie.position
        let direction = offset.normalized()
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
        enemy.name = "enemy"
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
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(SKAction.repeatActionForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeActionForKey("animation")
    }
    
    func spawnCat() {
        // make a cat
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(
            x: CGFloat.random(
                min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        addChild(cat)
        
        // pop a cat into view
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        
        // construct the wiggle wait sequence
        cat.zRotation = -π / 16.0
        
        // positive rotations go counter clockwise
        let leftWiggle = SKAction.rotateByAngle(π / 8.0, duration: 0.5)
        // negative rotations go clockwise
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        // scale up/down
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    // collision detection
    
    func zombieHitCat(cat: SKSpriteNode) {
        //cat.removeFromParent()
        
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        let turnGreen = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
        cat.runAction(turnGreen)
        
        runAction(catCollisionSound)
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        self.zombieInvinciable = true

        
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        
        let finishAction = SKAction.runBlock({
            self.zombie.hidden = false
            self.zombieInvinciable = false
        })
        
        zombie.runAction(SKAction.sequence([blinkAction, finishAction]))
        runAction(enemyCollisionSound)
    }
    
    func checkCollisions() {
        
        // deal with cats
        var hitCats: [SKSpriteNode] = []
        
        enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        
        // remove dead cats
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        // deal with enemies
        
        if zombieInvinciable {
            // skip the rest
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        
        enumerateChildNodesWithName("enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect(CGRectInset(node.frame, 20, 20), self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        
        // remove dead enemies
        for enemy in hitEnemies {
            zombieHitEnemy(enemy)
        }
    }
    
    func moveTrain() {
        
        var targetPosition = zombie.position
        
        enumerateChildNodesWithName("train") { node, stop in
            if !node.hasActions() {
                
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
            //print("targetPosition: \(targetPosition)")
        }
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
