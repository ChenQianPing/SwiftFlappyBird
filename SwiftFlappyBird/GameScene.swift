//
//  GameScene.swift
//  SwiftFlappyBird
//
//  Created by ChenQianPing on 16/7/31.
//  Copyright (c) 2016年 ChenQianPing. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let verticalPipeGap = 150.0
    
    var bird:SKSpriteNode!            // 鸟精灵
    var skyColor:SKColor!             // 天空颜色
    var pipeTextureUp:SKTexture!      // 柱子纹理上
    var pipeTextureDown:SKTexture!    // 柱子纹理下
    var movePipesAndRemove:SKAction!  // 移动柱子并且消除动作
    var moving:SKNode!                // 移动节点
    var pipes:SKNode!                 // 柱子节点
    var canRestart = Bool()           // 能否重新开始
    var scoreLabelNode:SKLabelNode!   // 分数标签
    var score = NSInteger()           // 分数
    
    // 物理引擎标识
    let birdCategory: UInt32 = 1 << 0   // 鸟
    let worldCategory: UInt32 = 1 << 1  // 地面
    let pipeCategory: UInt32 = 1 << 2   // 柱子
    let scoreCategory: UInt32 = 1 << 3  // 分数
    
    // 切换入视图
    override func didMove(to view: SKView) {
        
        canRestart = false  // 是否能重新开始为否
        
        // setup physics
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )  // 重力
        self.physicsWorld.contactDelegate = self                   // 物体碰撞检测回调函数
        
        // setup background color
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
        let groundTexture = SKTexture(imageNamed: "land")   // 地面图片
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        
        // 地面的动画
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))

        // 地面图片拼接
        let groundWidth = Int(2.0 + self.frame.size.width / (groundTexture.size().width * 2.0))
        for i in 0 ..< groundWidth {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(2.0)
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "sky")  // 天空图片
        skyTexture.filteringMode = .nearest
        
        // 天空动作
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        // 播放动作
        let skyWidth = Int(2.0 + self.frame.size.width / (skyTexture.size().width * 2.0))
        for i in 0 ..< skyWidth {
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2.0 + groundTexture.size().height * 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // create the pipes movement actions
        // 柱子动作
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        // 2秒生产一对柱子
        let spawn = SKAction.run({() in self.spawnPipes()})   // 执行函数动画
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        // setup our bird
        let birdTexture1 = SKTexture(imageNamed: "bird-01")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "bird-02")
        birdTexture2.filteringMode = .nearest
        let birdTexture3 = SKTexture(imageNamed: "bird-03")
        birdTexture3.filteringMode = .nearest
        let birdTexture4 = SKTexture(imageNamed: "bird-04")
        birdTexture4.filteringMode = .nearest
        
        let anim = SKAction.animate(with: [birdTexture1, birdTexture2 ,birdTexture3 ,birdTexture4], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(anim)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.setScale(2.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.35, y:self.frame.size.height * 0.6)
        bird.run(flap)
        
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory  // 自己的掩码
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory   // 弹开的掩码
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory // 碰撞事件掩码
        
        self.addChild(bird)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundTexture.size().height * 2.0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        
    }
    
    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
        pipePair.zPosition = -10
        
        let height = UInt32( self.frame.size.height / 4)
        let y = Double(arc4random_uniform(height) + height);
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
        
    }
    
    func resetScene (){
        // Move bird to original position and reset velocity
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        if moving.speed > 0  {
            for touch: AnyObject in touches {   // 多点触摸
                _ = touch.location(in: self)
                
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)      // 把速度设为0,不设的话有加速度
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30))  // 推力
                
            }
        } else if canRestart {
            self.resetScene()
        }
    }
    
    // TODO: Move to utilities somewhere. There's no reason this should be a member function
    func clamp(_ min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if( value > max ) {
            return max
        } else if( value < min ) {
            return min
        } else {
            return value
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        
        // 鸟的角度
        bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 ) )
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // 如果通过分数区域
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {   // 如果碰撞到其他的物体
                
                moving.speed = 0
                
                // 碰到柱子后只能和地面有碰撞
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(  SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
                
                
                // Flash background if contact is detected
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                    self.backgroundColor = self.skyColor
                }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                    self.canRestart = true
                })]), withKey: "flash")
            }
        }
    }
}
