//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by John Pavley on 12/6/15.
//  Copyright © 2015 John Pavley. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        
        background.position = CGPoint(
            x: self.size.width / 2,
            y: self.size.height / 2
        )
        self.addChild(background)       
    }
}
