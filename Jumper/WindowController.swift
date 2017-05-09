//
//  WindowController.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/6/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation
import Cocoa
import SpriteKit
import GameplayKit
import AVFoundation


var direction: Bool = true //true=right, false=left
var up: Bool = false //trigger to wait until corner reached
var down: Bool = false //ditto
var horizontalWait: Bool = false
var horizontalMove = true
var gravity = true //True es normal, en el suelo
var counter: Int = 15 //To acount for awkwardness in controls

let xstart_pos = CGFloat(50)

let player_floor_pos = CGFloat(10)
let player_ceil_pos = CGFloat(20)

let ytop_bars = CGFloat(28)
let ylow_bars = CGFloat(2)

struct gamePhysics
{
    static let Player: UInt32 = 1
    static let Void: UInt32 = 2
    //static let Blinky: UInt32 = 3
}

protocol DetailsDelegate: class {
    func updateLabel(Score: Int)
}

fileprivate extension NSTouchBarCustomizationIdentifier
{
    static let customTouchBar = NSTouchBarCustomizationIdentifier("com.RubCuadra.touchbar.customTouchBar")
}

fileprivate extension NSTouchBarItemIdentifier
{
    static let customView = NSTouchBarItemIdentifier("com.RubCuadra.touchbar.items.customView")
}

class WindowController: NSWindowController
{
    
    override func windowDidLoad() { super.windowDidLoad() }
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar?
    {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .customTouchBar
        touchBar.defaultItemIdentifiers = [.customView]
        touchBar.customizationAllowedItemIdentifiers = [.customView]
        return touchBar
    }
    
    @IBOutlet public weak var mainView: NSWindow!
    
    override func keyDown(with event: NSEvent)
    {
        //print(event.keyCode)
        switch event.keyCode
        {
        //Control Pac-Man movement
        case 123: //left
            if horizontalMove
            {
                up = false
                down = false
            }
            direction = false
            horizontalWait = true
            counter = 15
        case 124: //right
            if horizontalMove
            {
                up = false
                down = false
            }
            direction = true
            horizontalWait = true
            counter = 15
        case 125: //down
            down = true
            up = false
            counter = 15
        case 126:
            //up
            up = true
            down = false
            counter = 15
        case 49:    //spaceBar
            gravity = !gravity
            break
            
        default:
            break
        }
    }
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate
{
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem? {
        
        switch identifier
        {
            case NSTouchBarItemIdentifier.customView:
                let gameView = SKView()
                let scene = GameScene()
                let item = NSCustomTouchBarItem(identifier: identifier)
                
                item.view = gameView
                item.view.allowedTouchTypes = NSTouchTypeMask.direct //.insert(NSTouchTypeMask.direct)
                //item.view.gestureRecognizers.append(NSGestureRecognizer.init())
                //item.view.acceptsTouchEvents = true
                gameView.presentScene(scene)
                
                
                
                return item
                
            default:
                return nil
        }
    }
    
}

class GameScene: SKScene, SKPhysicsContactDelegate
{
    override func touchesBegan(with event: NSEvent)
    {
        print("TOUCH")
    }
    
    //Variables
    let touchbarHeight = 60
    let touchbarWidth = 1024
    let bar_width = 16
    
    var score: Int = 0
    
    var ceilBarArray = [SKSpriteNode]()
    var floorBarArray = [SKSpriteNode]()
    var movement_speed = CGFloat(3)
    
    var numDots = 85
    var Player: SKSpriteNode!
    var PacFrames: [SKTexture]!
    var barIsWhite: Bool = false
    var level: Int = 0
    var tHold1: Bool = false
    var tHold2: Bool = false //These keep Blinky's speed from being increased more than once
    var dotNumber: Bool = true //true = 1, false = 2
    
    func createBorders()
    {
        var barArray = [SKSpriteNode]()
        barArray.append(SKSpriteNode(imageNamed: "barR"))
        barArray.append(SKSpriteNode(imageNamed: "bbarR"))
        barArray.append(SKSpriteNode(imageNamed: "barL"))
        barArray.append(SKSpriteNode(imageNamed: "bbarL"))
        barArray.append(SKSpriteNode(imageNamed: "barR"))
        barArray.append(SKSpriteNode(imageNamed: "bbarR"))
        for b in barArray
        {
            b.xScale = 1
            b.yScale = 1
        }
        var sArray = [SKSpriteNode]()
        sArray.append(SKSpriteNode(imageNamed: "barLs"))
        sArray.append(SKSpriteNode(imageNamed: "bbarLs"))
        var offsetX = 107
        var inc: Bool = false
        for (index, item) in barArray.enumerated()
        {
            item.name = "Bar" + "\(index)"
            item.position.x = CGFloat(offsetX)
            if inc                      //Es del techo
            {
                item.position.y = 2
            } else                      //Suelo
            {
                item.position.y = 28
            }
            self.addChild(item)
            
            if inc
            {
                offsetX += 214  //Lo que mide cada uno de ancho, se manda a llamar 1 vez cada 2 iters
            }
            inc = !inc          //En el array estan uno de techo, uno de suelo
        }
        for (index, item) in sArray.enumerated()
        {
            item.name = "Bar" + "\(index + barArray.count)" //
            item.position.x = 671  //Son las mas pegadas a la derecha, pixeles que faltaron al parecer
            if index == 0
            {
                item.position.y = 28
            } else {
                item.position.y = 2
            }
            self.addChild(item)
        }
    }
    
    func createSprite(texture: [SKTexture], height: Int, width: Int, xPos: Int, yPos: Int, node: inout SKSpriteNode!, catBitMask: UInt32, conTestBitMask: [UInt32])
    {
        node = SKSpriteNode(texture: texture[0])
        node.size.height = CGFloat(height)
        node.size.width = CGFloat(width)
        node.position.x = CGFloat(xPos)
        node.position.y = CGFloat(yPos)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = catBitMask
        for mask in conTestBitMask {
            node.physicsBody?.contactTestBitMask = mask
        }
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        self.addChild(node)
    }
    
    //Removing stuff
    func removeDot(dot: SKSpriteNode)
    {
        score += 10
        dot.removeFromParent()
        numDots -= 1
        updateScore(value: String(describing: score))
        if dotNumber
        {
            do
            {
                //try eatAudio = AVAudioPlayer(contentsOf: eat1 as URL)
            } catch
            {
                print("Could not update audio - eat1")
            }
        } else
        {
            do
            {
                //try eatAudio = AVAudioPlayer(contentsOf: eat2 as URL)
            } catch{
                print("Could not update audio - eat2")
            }
        }
        //eatAudio.prepareToPlay()
        //eatAudio.play()
        dotNumber = !dotNumber
    }
    
    func removeDots()
    {
        self.enumerateChildNodes(withName: "Dot" + "*", using:
            {
                (node, stop) -> Void in
                node.removeFromParent()
        })
    }
    
    func hideBars()
    {
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                node.removeFromParent()
        })
    }
    
    //Miscellaneous
    func GameOver()//(blinky: SKSpriteNode)
    {
        self.view?.scene?.isPaused = true
        //sirenAudio.stop()
        //blinky.removeFromParent()
        self.removeDots()
        DeathFrames()
    }
    
    func flashBars()
    {
        func isWhite() -> String
        {
            if barIsWhite
            {
                return ""
            }
            return "w"
        }
        
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                let n = node as? SKSpriteNode
                switch n?.name {
                case "Bar0"?:
                    n?.texture = SKTexture(imageNamed: "barR" + isWhite())
                case "Bar1"?:
                    n?.texture = SKTexture(imageNamed: "bbarR" + isWhite())
                case "Bar2"?:
                    n?.texture = SKTexture(imageNamed: "barL" + isWhite())
                case "Bar3"?:
                    n?.texture = SKTexture(imageNamed: "bbarL" + isWhite())
                case "Bar4"?:
                    n?.texture = SKTexture(imageNamed: "barR" + isWhite())
                case "Bar5"?:
                    n?.texture = SKTexture(imageNamed: "bbarR" + isWhite())
                case "Bar6"?:
                    n?.texture = SKTexture(imageNamed: "barLs" + isWhite())
                case "Bar7"?:
                    n?.texture = SKTexture(imageNamed: "bbarLs" + isWhite())
                default:
                    break
                }
        })
        barIsWhite = !barIsWhite
    }
    
    func flashAfterDelay(delay: Double)
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay)
        {
            self.flashBars()
        }
    }
    
    //    func findDiv(number: Double, divLength: Double) -> Double
    //    {
    //        //find where 'number' lies in 'total' divided into divisions of 'divlength' width (separation into squares)
    //        return ((number / divLength)).rounded(.towardZero)
    //    }
    //
    //    func findShortestPath(array: [Double]) -> Int
    //    {
    //        var i: Double = array[0]
    //        var output: Int = 0
    //        for (index, item) in array.enumerated()
    //        {
    //            if item < i && item > 0
    //            {
    //                i = item
    //                output = index
    //            }
    //        }
    //        return output
    //    }
    
    func updateScore(value: String)
    {
        //textField?.stringValue = value
    }
    
    //    func bSpeedInc()
    //    {
    //        blinkySpeed = blinkySpeed * 1.05
    //    }
    
    func DeathFrames()
    {
        var PlayerD: SKSpriteNode!
        let DeathAtlas = SKTextureAtlas(named: "PlayerD")
        var deathFrames = [SKTexture]()
        for index in 1...11
        {
            let textureName = "PlayerD\(index)"
            deathFrames.append(DeathAtlas.textureNamed(textureName))
        }
        PlayerD = SKSpriteNode(texture: deathFrames[0])
        PlayerD.position.x = self.Player.position.x
        PlayerD.position.y = self.Player.position.y - 2
        //Blinky.removeFromParent()
        Player.removeAction(forKey: "PlayerEat")
        Player.texture = SKTexture(imageNamed: "Player3")
        updateScore(value: String(describing: score) + "\n GAME OVER")
        self.Player.removeFromParent()
        self.addChild(PlayerD)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.view?.scene?.isPaused = false
            do
            {
                //try self.miscAudio = AVAudioPlayer(contentsOf: self.death as URL)
            } catch
            {
                print("Could not update audio - death")
            }
            //self.miscAudio.prepareToPlay()
            //self.miscAudio.play()
            for i in 1...11 {
                if i == 1 {
                    PlayerD.position.y -= 1 //to account for differences in sprite dimensions
                }
                if i == 11 {
                    PlayerD.position.y += 1
                }
                PlayerD.run(SKAction.animate(with: deathFrames, timePerFrame: 0.1, resize: false, restore: true), withKey: "GameOver")
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.3) {
                self.view?.scene?.isPaused = true
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact)
    {
        let firstBody: SKPhysicsBody = contact.bodyA
        let secondBody: SKPhysicsBody = contact.bodyB
        
        if (firstBody.categoryBitMask == gamePhysics.Player) && (secondBody.categoryBitMask == gamePhysics.Void)
        {
            print("Chocaron")
            //removeDot(dot: secondBody.node as! SKSpriteNode)
        }
        //        else if (firstBody.categoryBitMask == gamePhysics.Blinky) && (secondBody.categoryBitMask == gamePhysics.Player)
        //        {
        //            GameOver(blinky: firstBody.node as! SKSpriteNode)
        //        }
    }
    
    func playSiren()
    {
        //        sirenAudio.numberOfLoops = -1
        //        sirenAudio.prepareToPlay()
        //        sirenAudio.play()
    }
    
    //Movement
    func checkVertical()
    {
        if Player.position.x < 214.5 && Player.position.x > 213.5
        { //to account for decimals
            if up
            {
                Player.position.x = 214
                Player.xScale = 1
                Player.zRotation = CGFloat(0.5 * M_PI)
                horizontalMove = false
                Player.position.y += 1
            } else if down
            {
                Player.xScale = 1
                Player.position.x = 214
                Player.zRotation = CGFloat(1.5 * M_PI)
                horizontalMove = false
                Player.position.y -= 1
            }
        } else if Player.position.x < 642.5 && Player.position.x > 641.5
        {
            if up
            {
                Player.xScale = 1
                Player.position.x = 642
                Player.zRotation = CGFloat(0.5 * M_PI)
                horizontalMove = false
                Player.position.y += 1
            } else if down {
                Player.xScale = 1
                Player.position.x = 642
                Player.zRotation = CGFloat(1.5 * M_PI)
                horizontalMove = false
                Player.position.y -= 1
            }
        }
    }
    
    func checkHorizontal()
    {
        if !horizontalMove
        {
            if Player.position.y < 16 && Player.position.y > 14
            {
                if horizontalWait
                {
                    horizontalMove = true
                    Player.position.y = player_floor_pos
                    Player.zRotation = 0
                    horizontalWait = false
                    up = false
                    down = false
                }
            }
        }
    }
    
    //    func findNearestPath() -> [Double]?
    //    {
    //        let bXPos = Double(Blinky.position.x)
    //        let bYPos = Double(Blinky.position.y)
    //        let pXPos = Double(Player.position.x)
    //        let pYPos = Double(Player.position.y)
    //        var out = [Double]()
    //        if (bYPos > 14.5 && bYPos < 15.5) && (bXPos < 214.5 && bXPos > 213.5 || bXPos < 642.5 && bXPos > 641.5 ) {
    //            let pXDiv = findDiv(number: pXPos, divLength: 14)
    //            let pYDiv = findDiv(number: pYPos, divLength: 14)
    //            let bXDiv = findDiv(number: bXPos, divLength: 14)
    //            let bYDiv = findDiv(number: bYPos, divLength: 14)
    //            let fBXDiv = (findDiv(number: bXPos, divLength: 14) + 1)
    //            let bBXDiv = (findDiv(number: bXPos, divLength: 14) - 1)
    //            let uBYDiv = (findDiv(number: bYPos, divLength: 14) + 1)
    //            let dBYDiv = (findDiv(number: bYPos, divLength: 14) - 1)
    //            let currentXDiff: Double = abs(pXDiv - bXDiv) * abs(pXDiv - bXDiv)
    //            let currentYDiff: Double = abs(pYDiv - bYDiv) * abs(pYDiv - bYDiv)
    //            let forwardsDiff: Double = abs(pXDiv - fBXDiv) * abs(pXDiv - fBXDiv)
    //            let backwardsDiff: Double = abs(pXDiv - bBXDiv) * abs(pXDiv - bBXDiv)
    //            let upDiff: Double = abs(pYDiv - uBYDiv) * abs(pYDiv - uBYDiv)
    //            let downDiff: Double = abs(pYDiv - dBYDiv) * abs(pYDiv - dBYDiv)
    //            if bHorizontalMove {
    //                if Blinky.xScale > 0 {
    //                    out = [currentXDiff + upDiff, -1.0, currentXDiff + downDiff, forwardsDiff + currentYDiff]
    //                } else {
    //                    out = [currentXDiff + upDiff, backwardsDiff + currentYDiff, currentXDiff + downDiff, -1.0]
    //                }
    //            } else {
    //                if bVerticalMove {
    //                    out = [currentXDiff + upDiff, backwardsDiff + currentYDiff, -1.0, forwardsDiff + currentYDiff]
    //                } else {
    //                    out = [-1.0, backwardsDiff + currentYDiff, currentXDiff + downDiff, forwardsDiff + currentYDiff]
    //                }
    //            }
    //            for (index, item) in out.enumerated() {
    //                //Broken down to allow it to be solved in reasonable time
    //                out[index] = sqrt(item)
    //                out[index] = Double(item)
    //            }
    //            return out
    //        }
    //        return nil
    //    }
    
    //    func bSpeed(xPos: CGFloat, yPos: CGFloat) -> CGFloat
    //    {
    //        if xPos < 50 || xPos > 650 || yPos > 16 || yPos < 14 {
    //            return (blinkySpeed - 0.1)
    //        }
    //        return blinkySpeed
    //    }
    
    func checkOverflow( sprite: SKSpriteNode)
    {
        if sprite.position.x < 0
        {
            sprite.position.x = 700 //End
        }
        else if sprite.position.x > 700
        {
            sprite.position.x = 0 //Start
        }
        if sprite.position.y < 0
        {
            if sprite.position.x > 213.5 && sprite.position.x < 214.5
            {
                sprite.position.x = 642
            } else {
                sprite.position.x = 214
            }
            sprite.position.y = 30
        } else if sprite.position.y > 30
        {
            if sprite.position.x > 213.5 && sprite.position.x < 214.5
            {
                sprite.position.x = 642
            } else {
                sprite.position.x = 214
            }
            sprite.position.y = 0
        }
    }
    
    //Initialise the game
    override func didMove(to view: SKView)
    {
        super.didMove(to: view)
        self.view?.scene?.isPaused = true
        updateScore(value: "READY!")
        physicsWorld.contactDelegate = self
        do
        {
            //            eatAudio = try AVAudioPlayer(contentsOf: eat1 as URL)
            //            sirenAudio = try AVAudioPlayer(contentsOf: sirenS as URL)
            //            miscAudio = try AVAudioPlayer(contentsOf: intro as URL)
        } catch
        {
            print("Could not update audio - eat1, sirenS, intro")
        }
        //createBorders()
        initializeBorders()
        self.scaleMode = .resizeFill
        self.backgroundColor = .black
        let PlayerAtlas = SKTextureAtlas(named: "Player")
        var eatFrames = [SKTexture]()
        for index in 1...3
        {
            let textureName = "Player\(index)"
            eatFrames.append(PlayerAtlas.textureNamed(textureName))
        }
        //let	BlinkyAtlas = SKTextureAtlas(named: "Blinky")
        //var ghostFrames = [SKTexture]()
        //        for index in 1...2
        //        {
        //            let textureName = "Blinky\(index)"
        //            ghostFrames.append(BlinkyAtlas.textureNamed(textureName))
        //        }
        //        let	BlinkyUpAtlas = SKTextureAtlas(named: "BlinkyUp")
        //        var ghostUpFrames = [SKTexture]()
        //        for index in 1...2 {
        //            let textureName = "BlinkyUp\(index)"
        //            ghostUpFrames.append(BlinkyUpAtlas.textureNamed(textureName))
        //        }
        //        let	BlinkyDownAtlas = SKTextureAtlas(named: "BlinkyDown")
        //        var ghostDownFrames = [SKTexture]()
        //        for index in 1...2 {
        //            let textureName = "BlinkyDown\(index)"
        //            ghostDownFrames.append(BlinkyDownAtlas.textureNamed(textureName))
        //        }
        //        BlinkyFrames = ghostFrames
        //        BlinkyUpFrames = ghostUpFrames
        //        BlinkyDownFrames = ghostDownFrames
        //        miscAudio.prepareToPlay()
        //        miscAudio.play()
        //createSprite(texture: BlinkyFrames, height: 14, width: 14, xPos: 50, yPos: 15, node: &Blinky, catBitMask: gamePhysics.Blinky, conTestBitMask: [gamePhysics.Player, gamePhysics.Dot])
        PacFrames = eatFrames
        createSprite(texture: PacFrames, height: 13, width: 13, xPos: Int(xstart_pos), yPos: Int(player_floor_pos), node: &Player, catBitMask: gamePhysics.Player,
                     conTestBitMask:[])//[gamePhysics.Dot, gamePhysics.Blinky])
        Player.texture = PacFrames[2]
        //Blinky.physicsBody?.collisionBitMask = 0
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 4.5)
        {
            //self.createDots()
            //self.Blinky.zPosition = 5
            self.Player.run(SKAction.repeatForever(SKAction.animate(with: self.PacFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "PlayerEat")
            //self.Blinky.run(SKAction.repeatForever(SKAction.animate(with: self.BlinkyFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "BlinkyMove")
            self.view?.scene?.isPaused = false
            self.playSiren()
        }
    }
    
    func checkGravity() //TODO : Animate jump
    {
        if gravity //Gravedad normal
        {
            if Player.yScale < 0
            {
                Player.yScale *= -1              //Cambiar gravedad
                Player.position.y = player_floor_pos //Invertir al suelo
                //Player.position.x += 5           //Avanzar 1
            }
            else
            {
                
            }
        }
        else    //Gravedad Invertida
        {
            if Player.yScale < 0
            {
                
            }
            else
            {
                Player.yScale *= -1             //Cambiar gravedad
                Player.position.y = player_ceil_pos //Invertir al techo
                //Player.position.x += 5          //Avanzar 1
            }
        }
        //print (Player.position)
    }
    
    func initializeBorders() //Todo estara lleno
    {
        var offsetX = 0  //Separar barras
        for index in 1...touchbarWidth/bar_width //Llenar top y bottom de bars
        {
            addNewFloor(name: "BarF" + "\(index)", xPosition:CGFloat(offsetX))
            addNewCeil (name: "BarC" + "\(index)", xPosition:CGFloat(offsetX))
            offsetX += bar_width
        }
        
    }
    
    func addNewFloor(name: String,xPosition : CGFloat)
    {
        let f = SKSpriteNode(imageNamed: "barSB" )
        f.xScale = 1
        f.yScale = 1
        f.position.y = ylow_bars
        f.name = name
        f.position.x = xPosition
        floorBarArray.append( f )
        self.addChild(f)
    }
    
    func addNewCeil(name: String,xPosition : CGFloat)
    {
        let c = SKSpriteNode(imageNamed: "barSB" )
        c.xScale = 1
        c.yScale = 1
        c.position.y = ytop_bars
        c.name = name
        c.position.x = xPosition
        ceilBarArray.append( c )
        self.addChild(c)
    }
    
    //Creating stuff
    func addNewFloorVoid(name: String,xPosition : CGFloat)
    {
        //Crear objeto
        var _void = SKSpriteNode(imageNamed: "barSB2")
        _void.position.x = xPosition
        _void.position.y = ylow_bars
        _void.name = name           //Maybe deberiamos identificarlo de otra forma
        //Agregar fisica para colisiones
        var s = _void.size
        s.width -= 1            //Para que no este tan cabron, offset de 1
        _void.physicsBody = SKPhysicsBody(rectangleOf: s)
        _void.physicsBody?.categoryBitMask = gamePhysics.Void
        _void.physicsBody?.contactTestBitMask = gamePhysics.Player
        _void.physicsBody?.isDynamic = true
        _void.physicsBody?.affectedByGravity = false
        _void.physicsBody?.collisionBitMask = 0
        //Agregar al arreglo y al juego
        floorBarArray.append(_void)
        self.addChild(_void)
    }
    
    
    func moveScene()
    {
        //Mover todas las barras segun la velocidad
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                    node.position.x -= self.movement_speed
            })
        
        //Si el primer elemento del suelo NO esta en pantalla (intersects)
        if let first = floorBarArray.first, !intersects(_:first)
        {
            let last = floorBarArray.last!
            floorBarArray.removeFirst()
            
            //Arroja 2 numeros, 0 y 1  -- arc4random_uniform(2)
            if true
            {
                first.position.x = (last.position.x) + CGFloat(bar_width)
                floorBarArray.append(first)
            }
            else
            {
                //first.removeFromParent()
                //addNewFloorVoid( name:first.name!, xPosition: (last.position.x) + CGFloat(bar_width))
            }
        }
        
        //Si el primer elemento del techo NO esta en pantalla (intersects)
        if let first = ceilBarArray.first, !intersects(_:first)
        {
            let last = ceilBarArray.last!
            ceilBarArray.removeFirst()
            
            if true //Si volveremos a pintar este tile, solo cambiar posicion
            {
                first.position.x = (last.position.x) + CGFloat(bar_width)
                ceilBarArray.append(first)
            }
            else
            {
                //first.removeFromParent()
                //addNewCeilVoid(name: first.name, xPosition: (last.position.x) + CGFloat(bar_width))
            }
        }
    }
    
    //Update everything (calls other functions)
    override func update(_ currentTime: TimeInterval)
    {
        //let bXPos = Blinky.position.x
        //let bYPos = Blinky.position.y
        _ = Player.position.x
        
        moveScene()
        
        //checkOverflow(sprite: Player)
        //checkOverflow(sprite: Blinky)
//        if numDots == 10
//        {
//            if !tHold2
//            {
//                //bSpeedInc()
//                do
//                {
//                    //sirenAudio = try AVAudioPlayer(contentsOf: sirenF as URL)
//                } catch
//                {
//                    print("Could not update audio - sirenF")
//                }
//                playSiren()
//            }
//            tHold2 = true
//        } else if numDots == 30
//        {
//            if !tHold1
//            {
//                //bSpeedInc()
//                do
//                {
//                    //sirenAudio = try AVAudioPlayer(contentsOf: sirenM as URL)
//                } catch {
//                    print("Could not update audio - sirenM")
//                }
//                playSiren()
//            }
//            tHold1 = true
//        }
        //        if let array = findNearestPath()
        //        {
        //            if findShortestPath(array: array) == 1 || findShortestPath(array: array) == 3
        //            {
        //                bHorizontalMove = true
        //                if Blinky.action(forKey: "BlinkyMoveUp") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMoveUp")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveDown") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMoveDown")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveDown") == nil {
        //                    Blinky.run(SKAction.repeatForever(SKAction.animate(with: BlinkyFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "BlinkyMove")
        //                }
        //                Blinky.position.y = 15
        //            }
        //            switch findShortestPath(array: array) {
        //            case 0:
        //                if Blinky.action(forKey: "BlinkyMove") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMove")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveDown") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMoveDown")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveUp") == nil {
        //                    Blinky.run(SKAction.repeatForever(SKAction.animate(with: BlinkyUpFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "BlinkyMoveUp")
        //                }
        //                if Blinky.position.x < 214.5 && Blinky.position.x > 213.5 {
        //                    Blinky.position.x = 214
        //                } else {
        //                    Blinky.position.x = 642
        //                }
        //                bHorizontalMove = false
        //                bVerticalMove = true
        //                Blinky.position.y += bSpeed(xPos: bXPos, yPos: bYPos)
        //            case 1:
        //                bHorizontalMove = true
        //                Blinky.position.y = 15
        //                Blinky.position.x -= bSpeed(xPos: bXPos, yPos: bYPos)
        //                Blinky.xScale = -1
        //            case 2:
        //                if Blinky.action(forKey: "BlinkyMove") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMove")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveUp") != nil {
        //                    Blinky.removeAction(forKey: "BlinkyMoveUp")
        //                }
        //                if Blinky.action(forKey: "BlinkyMoveDown") == nil {
        //                    Blinky.run(SKAction.repeatForever(SKAction.animate(with: BlinkyDownFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "BlinkyMoveDown")
        //                }
        //                if Blinky.position.x < 214.5 && Blinky.position.x > 213.5 {
        //                    Blinky.position.x = 214
        //                } else {
        //                    Blinky.position.x = 642
        //                }
        //                bHorizontalMove = false
        //                bVerticalMove = false
        //                Blinky.position.y -= bSpeed(xPos: bXPos, yPos: bYPos)
        //            case 3:
        //                bHorizontalMove = true
        //                Blinky.position.y = 15
        //                Blinky.position.x += bSpeed(xPos: bXPos, yPos: bYPos)
        //                Blinky.xScale = 1
        //            default:
        //                break
        //            }
        //        } else {
        //            if bHorizontalMove {
        //                if Blinky.xScale > 0 {
        //                    Blinky.position.x += bSpeed(xPos: bXPos, yPos: bYPos)
        //                    Blinky.xScale = 1
        //                } else {
        //                    Blinky.position.x -= bSpeed(xPos: bXPos, yPos: bYPos)
        //                    Blinky.xScale = -1
        //                }
        //            } else {
        //                if bVerticalMove {
        //                    Blinky.position.y += bSpeed(xPos: bXPos, yPos: bYPos)
        //                } else {
        //                    Blinky.position.y -= bSpeed(xPos: bXPos, yPos: bYPos)
        //                }
        //            }
        //        }
        
        checkGravity()
        
        if horizontalMove
        {
            horizontalWait = false
            
            if direction
            {
                if Player.xScale < 0
                {
                    Player.xScale = Player.xScale * -1;
                }
                //Player.position.x += 1
            } else
            {
                if Player.xScale > 0
                {
                    Player.xScale = Player.xScale * -1;
                }
                //Player.position.x -= 1
            }
        }
        
        checkVertical()
        checkHorizontal()
        if counter > 0
        {
            counter -= 1
        } else
        {
            horizontalWait = false
            if !(Player.position.x < 214.5 && Player.position.x > 213.5) && !(Player.position.x < 642.5 && Player.position.x > 641.5)
            {
                up = false
                down = false
            }
        }
        //checkOverflow(sprite: Blinky)
        if false  //GANAMOS
        {
            self.view?.scene?.isPaused = true
            //sirenAudio.stop()
            Player.texture = SKTexture(imageNamed: "Player3")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3)
            {
                //self.Blinky.removeFromParent()
                for i in 1...8
                {
                    self.flashAfterDelay(delay: Double(i) * 0.2)
                }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0)
                {
                    self.Player.removeFromParent()
                    self.hideBars()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1)
                    {
                        self.addChild(self.Player)
                        //self.createBorders()
                        //self.addChild(self.Blinky)
                        //self.Blinky.position.x = 50
                        //self.Blinky.position.y = 15
                        
                        self.Player.position.x = xstart_pos
                        self.Player.position.y = player_floor_pos
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) //Start Game
                        {
                            direction = true
                            //self.Blinky.xScale = 1
                            self.numDots = 85
                            //self.createDots()
                            self.tHold1 = false
                            self.tHold2 = false
                            self.view?.scene?.isPaused = false
                            do
                            {
                                //self.sirenAudio = try AVAudioPlayer(contentsOf: self.sirenS as URL)
                            } catch
                            {
                                print("Could not update audio - sirenS")
                            }
                            self.playSiren()
                        }
                    }
                }
            }
        }
    }
}
