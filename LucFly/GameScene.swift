//
//  GameScene.swift
//  LucFly
//
//  Created by Lucas Ortigoso on 26/07/18.
//  Copyright © 2018 Lucas Ortigoso. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreData


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var lblTimer : SKLabelNode?
    private var lblScore : SKLabelNode?
    private var lblRecord : SKLabelNode?
    private var lblGameOver : SKLabelNode?
    private var score = 0
    private var maxScore: Int64 = 0
    private var spinnyNode : SKShapeNode?
    private var moski: SKSpriteNode?
    private var bgTexture = SKTexture(imageNamed: "hills")
    private var bg: SKSpriteNode?
    private var bgScale = CGFloat(0.95)
    var totalSeconds:Int = 0
    var speedPipe = CGFloat(100)
    
    let zPosMoski = CGFloat(10)
    let zPosBg = CGFloat(0)
    let zPosTimer = CGFloat(9)
    let zPosPipes = CGFloat(2)
    
    var startedGame = false
    var gameOver = false
    let moskiGroup:UInt32 = 1
    let pipeGroup:UInt32 = 2
    let emptyPipeGroup:UInt32 = 0 << 3
    
    var sceneMoveObject = SKNode()
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        self.addChild(sceneMoveObject)
        createMoski()
        createFloorAndTop()
        createBg()
        createLabelTimer()
        createLabelScore()
        createLabelGameOver()
        getRecord()
    }
    
    func getRecord(){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Scores")
        request.returnsObjectsAsFaults = false
        do {
            let result = try managedContext.fetch(request) as! [Scores]
            let record = result.max { $0.score < $1.score }
            if(record?.score != nil){
                maxScore = (record?.score)!
            } else {
                maxScore = 0
            }
            createLabelRecord()
            //            for data in result as! [NSManagedObject] {
            //                print(String(data.value(forKey: "score") as! Int))
            //            }
            
        } catch {
            print("Failed")
        }
    }
    
    func createLabelGameOver(){
        lblGameOver = self.childNode(withName: "lblGameOver") as? SKLabelNode
        lblGameOver?.text = "Toque para iniciar!"
        lblGameOver?.zPosition = zPosTimer
        lblGameOver?.position = CGPoint(x:0, y:-300)
        lblGameOver?.alpha = 1.0
    }
    
    func restartGame(){
        let newScene = SKScene(fileNamed: "GameScene")
        newScene?.scaleMode = .aspectFill
        let animation = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(newScene!, transition: animation)
    }
    
    func startGame(){
        self.lblGameOver?.alpha = 0
        self.lblScore?.alpha = 0.7
        startedGame = true
        configMoskiPhysics()
        impulseMoski()
        resetTimer()
        initTimer()
        Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.createPipes), userInfo: nil, repeats: false)
    }
    
    func createLabelTimer(){
        (self.childNode(withName: "lblTimer") as? SKLabelNode)?.zPosition = zPosTimer
        lblTimer = self.childNode(withName: "lblTimerValue") as? SKLabelNode
        lblTimer?.zPosition = zPosTimer
        //        lblTimer?.position = CGPoint(x:self.frame.width/2 -
        //            (lblTimer?.frame.width)! * 2, y: self.frame.height/2 -
        //                (lblTimer?.frame.height)! * 2)
    }
    
    func createLabelRecord(){
        (self.childNode(withName: "lblRecord") as? SKLabelNode)?.zPosition = zPosTimer
        lblRecord = self.childNode(withName: "lblRecordValue") as? SKLabelNode
        lblRecord?.zPosition = zPosTimer
        lblRecord?.text = String(maxScore)
        //        lblRecord?.position = CGPoint(x:-self.frame.width/2 +
        //            (lblRecord?.frame.width)! + 50, y: self.frame.height/2 -
        //                (lblRecord?.frame.height)! * 2)
        
    }
    
    func createLabelScore(){
        lblScore = self.childNode(withName: "lblScore") as? SKLabelNode
        lblScore?.zPosition = zPosTimer
    }
    
    @objc func createPipes(){
        
        if(startedGame && !gameOver){
            let emptyPipeHeight = CGFloat(400)
            let rdmNum = Int.random(in: 0 ... 700)
            //        let rdmHeight = CGFloat(rdmNum) - self.size.height / 4
            
            let movePipe = SKAction.moveBy(x: -self.frame.size.width * 2, y: 0, duration: TimeInterval(self.size.width / speedPipe))
            let removePipe = SKAction.removeFromParent()
            let pipeSequence = SKAction.sequence([movePipe, removePipe])
            
            let pipeSize = CGSize(width: 100, height: 1000)
            let pipeSizePhysics = CGSize(width: 80, height: 900)
            let bottomPipe = SKShapeNode(rectOf: pipeSize)
            bottomPipe.fillColor = UIColor.black
            bottomPipe.strokeColor = UIColor.black
            bottomPipe.alpha = 0.8
            bottomPipe.zPosition = zPosPipes
            bottomPipe.physicsBody = SKPhysicsBody(rectangleOf: pipeSizePhysics)
            bottomPipe.physicsBody?.isDynamic = false
            bottomPipe.physicsBody?.categoryBitMask = pipeGroup
            //        bottomPipe.position = CGPoint(x: self.size.width, y: -self.frame.height/2 + bottomPipe.frame.height/2)
            bottomPipe.position = CGPoint(x: self.size.width, y: (-self.frame.height) + pipeSize.height/6 + 100 + CGFloat(rdmNum))
            bottomPipe.run(pipeSequence)
            
            //            print(rdmNum)
            
            let topPipe = SKShapeNode(rectOf: pipeSize)
            topPipe.strokeColor = UIColor.black
            topPipe.fillColor = UIColor.black
            topPipe.alpha = 0.8
            topPipe.position = CGPoint(x: self.size.width, y: bottomPipe.position.y + topPipe.frame.size.height + emptyPipeHeight)
            topPipe.zPosition = zPosPipes
            topPipe.physicsBody = SKPhysicsBody(rectangleOf: pipeSizePhysics)
            topPipe.physicsBody?.isDynamic = false
            topPipe.physicsBody?.categoryBitMask = pipeGroup
            topPipe.run(pipeSequence)
            
            let emptyPipe = SKShapeNode(rectOf: CGSize(width: 1, height: emptyPipeHeight))
            //            emptyPipe.fillColor = UIColor.green
            emptyPipe.alpha = 0
            emptyPipe.position = CGPoint(x: bottomPipe.position.x + bottomPipe.frame.size.width , y:bottomPipe.position.y + bottomPipe.frame.size.height/2 + emptyPipeHeight/2 )
            emptyPipe.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: emptyPipeHeight))
            emptyPipe.physicsBody?.isDynamic = false
            emptyPipe.physicsBody?.collisionBitMask = emptyPipeGroup
            emptyPipe.physicsBody?.categoryBitMask = emptyPipeGroup
            emptyPipe.physicsBody?.contactTestBitMask = moskiGroup
            emptyPipe.zPosition = zPosPipes
            emptyPipe.run(pipeSequence)
            
            
            
            sceneMoveObject.addChild(bottomPipe)
            sceneMoveObject.addChild(topPipe)
            sceneMoveObject.addChild(emptyPipe)
            
        }
        Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.createPipes), userInfo: nil, repeats: false)
        
    }
    
    
    func resetTimer(){
        self.totalSeconds = 0
    }
    
    func initTimer(){
        let wait:SKAction = SKAction.wait(forDuration: 1)
        let finishTimer:SKAction = SKAction.run {
            if(!self.gameOver){
                self.totalSeconds += 1
                self.initTimer()
                self.updateTimerLabel()
            }
        }
        
        let seq:SKAction = SKAction.sequence([wait, finishTimer])
        self.run(seq)
    }
    
    func updateTimerLabel(){
        self.lblTimer?.text = String(self.totalSeconds.toTimeString)
    }
    
    
    
    func createFloorAndTop(){
        let floor = SKNode()
        floor.position = CGPoint(x: 0, y: -self.size.height/2)
        floor.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width, height: 1))
        floor.physicsBody?.isDynamic = false
        floor.physicsBody?.affectedByGravity = false
        
        let top = SKNode()
        top.position = CGPoint(x: 0, y: self.size.height/2 + (moski?.size.height)!)
        top.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width, height: 1))
        top.physicsBody?.isDynamic = false
        top.physicsBody?.affectedByGravity = false
        
        self.addChild(top)
        self.addChild(floor)
    }
    
    
    func createMoski(){
        var arrayMoskiImages:[SKTexture] = []
        for i in 1...5 {
            arrayMoskiImages.append(SKTexture(imageNamed: "Fly Type 5 Color 1 Move \(i)"))
        }
        
        for i in (1...5).reversed() {
            arrayMoskiImages.append(SKTexture(imageNamed: "Fly Type 5 Color 1 Move \(i)"))
        }
        
        moski = SKSpriteNode(imageNamed: "Fly Type 5 Color 1 Move 1")
        moski?.run(SKAction.repeatForever(SKAction.animate(with: arrayMoskiImages, timePerFrame: 0.045)))
        moski?.position = CGPoint(x: -100, y: 0)
        moski?.setScale(0.25)
        moski?.zPosition = zPosMoski
        
        self.addChild(moski!)
    }
    
    
    func configMoskiPhysics(){
        moski?.physicsBody = SKPhysicsBody(circleOfRadius: (moski?.size.height)!/2)
        moski?.physicsBody?.isDynamic = true
        moski?.physicsBody?.allowsRotation = false
        
        moski?.physicsBody?.categoryBitMask = moskiGroup
        moski?.physicsBody?.contactTestBitMask = pipeGroup
        moski?.physicsBody?.collisionBitMask = emptyPipeGroup
        
    }
    
    func createBg(){
        let bgMoveBack = SKAction.moveBy(x: -bgTexture.size().width * bgScale, y: 0, duration: 5)
        let bgMoveFront = SKAction.moveBy(x: bgTexture.size().width * bgScale, y: 0, duration: 0)
        
        bg = SKSpriteNode(texture: bgTexture)
        bg?.position = CGPoint(x: self.size.width/2, y: 0)
        bg?.zPosition = zPosBg
        bg?.setScale(bgScale)
        
        for i in 0..<3 {
            bg = SKSpriteNode(texture: bgTexture)
            bg?.position = CGPoint(x: (bgTexture.size().width * CGFloat(i) * bgScale ), y: 0)
            bg?.alp
            
            bg?.setScale(bgScale)
            bg?.run(SKAction.repeatForever(SKAction.sequence([bgMoveBack, bgMoveFront])))
            sceneMoveObject.addChild(bg!)
        }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.green
            self.addChild(n)
        }
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.blue
            self.addChild(n)
        }
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if let n = self.spinnyNode?.copy() as! SKShapeNode? {
            n.position = pos
            n.strokeColor = SKColor.red
            self.addChild(n)
        }
    }
    
    
    func impulseMoski(){
        moski?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        moski?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 800))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if(!startedGame){
            startGame()
        } else if(!gameOver && startedGame) {
            impulseMoski()
        } else if(gameOver){
            restartGame()
        }
        
        
        
        
        
        //        if let label = self.lblScore {
        //
        //            label.physicsBody?.isDynamic = true
        //            label.run(SKAction.init(named: "Teste")!, withKey: "fadeInOut")
        //        }
        //
        //        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        //        moski?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 150))
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == emptyPipeGroup || contact.bodyB.categoryBitMask == emptyPipeGroup {
            print("hitVAO")
            score += 1
            
            if(score >= 50){
                speedPipe = CGFloat(250)
            }
            else if(score >= 40){
                speedPipe = CGFloat(200)
            }
            else if(score >= 20){
                speedPipe = CGFloat(160)
            }
            else if(score >= 10){
                speedPipe = CGFloat(130)
            } 
            
            
            self.lblScore?.text = String(score)
        } else {
            gameOver = true
            sceneMoveObject.speed = 0
            print("hitOutros")
            
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.showGameOver), userInfo: nil, repeats: false)
        }
    }
    
    
    @objc func showGameOver(){
        lblGameOver = self.childNode(withName: "lblGameOver") as? SKLabelNode
        lblGameOver?.text = "Toque para recomeçar"
        lblGameOver?.zPosition = zPosTimer
        lblGameOver?.position = CGPoint(x:0, y:0)
        lblGameOver?.alpha = 1
        
        saveScore()
        verifyNewRecord()
    }
    
    func verifyNewRecord(){
        if(score > maxScore){
            let lblNewRecord = self.childNode(withName: "lblNewRecord") as? SKLabelNode
            lblNewRecord?.zPosition = zPosTimer
            lblNewRecord?.alpha = 1
        }
    }
    
    func saveScore(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Scores", in: managedContext)!
        let score = NSManagedObject(entity: entity, insertInto: managedContext)
        
        score.setValue(self.score, forKeyPath: "score")
        score.setValue(NSDate().timeIntervalSince1970, forKeyPath: "date")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

extension Int {
    var toTimeString: String {
        let h = self / 3600
        let m = (self % 3600) / 60
        let s = (self % 3600) % 60
        return h > 0 ? String(format: "%1d:%02d:%02d", h, m, s) : String(format: "%1d:%02d", m, s)
    }
}
