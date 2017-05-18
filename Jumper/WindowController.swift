//
//  WindowController.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/6/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//
//TODO : QUE NO SALGAN 2 BARRAS EN LA MISMA POSICION
import Foundation
import Cocoa
import SpriteKit
import GameplayKit
import AVFoundation

var gravity = true //True es normal, en el suelo
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
    //Difficulty Variables
    var timer = Timer()
    var movement_speed = CGFloat(4)         //initialSpeed
    var max_movement_speed = CGFloat(10)    //max Speed
    var increaseSpeedInterval = 30          //in seconds
    var increaseSpeedFactor = CGFloat(0.5)  //se le sumara a movement_speed cada x seconds
    
    //Sizes
    let touchbarHeight = 60
    let touchbarWidth = 1024
    var barWidth : CGFloat  = 0             //Se llenan en el init de borders
    var voidWidth : CGFloat = 0             //Se llenan en el init de borders
    var voidBounding : CGSize = CGSize()    //Bounding Box para fisica

    //Views
    let platform_file_name = "barSB"
    let void_file_name = "barSB2"
        //Platforms
    var ceilBarArray = [SKSpriteNode]()
    var floorBarArray = [SKSpriteNode]()
        //Players
    var Player: SKSpriteNode!
    var PlayerFrames: [SKTexture]!
    
    //Game Flags/Logic
    var score: Int = 0
    var gameOver = false   //Juego acabo
    var coord = Coordinator.instance
    
    var barIsWhite: Bool = false
    
    func createSprite(texture: [SKTexture], height: Int, width: Int, xPos: Int, yPos: Int, node: inout SKSpriteNode!, catBitMask: UInt32, conTestBitMask: [UInt32])
    {
        node = SKSpriteNode(texture: texture[0])
        node.size.height = CGFloat(height)
        node.size.width = CGFloat(width)
        node.position.x = CGFloat(xPos)
        node.position.y = CGFloat(yPos)
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = catBitMask
        for mask in conTestBitMask { node.physicsBody?.contactTestBitMask = mask }
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        self.addChild(node)
    }
    
    func removeBars()
    {
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                node.removeFromParent()
        })
    }
    
    func GameOver()
    {
        self.view?.scene?.isPaused = true
        //sirenAudio.stop()
        //blinky.removeFromParent()
        //self.removeDots()
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
        
        Player.removeAction(forKey: "PlayerRun")
        Player.texture = SKTexture(imageNamed: "Player3")
        //updateScore(value: String(describing: score) + "\n GAME OVER")
        self.Player.removeFromParent()
        self.addChild(PlayerD)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0)
        {
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
            for i in 1...11
            {
                if i == 1
                {
                    PlayerD.position.y -= 1 //to account for differences in sprite dimensions
                }
                if i == 11
                {
                    PlayerD.position.y += 1
                }
                PlayerD.run(SKAction.animate(with: deathFrames, timePerFrame: 0.1, resize: false, restore: true), withKey: "GameOver")
            }
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.3)
                {
                    self.view?.scene?.isPaused = true
                }
        }
    }
    
    func increaseSpeed()
    {
        if !self.gameOver && self.movement_speed < max_movement_speed
        {
            self.movement_speed += increaseSpeedFactor
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact)
    {
        let firstBody: SKPhysicsBody = contact.bodyA
        let secondBody: SKPhysicsBody = contact.bodyB
        
        if (firstBody.categoryBitMask == gamePhysics.Player) && (secondBody.categoryBitMask == gamePhysics.Void)
        {
            print("Chocaron")
        }

    }
    
    func getPlayerFrames() -> [SKTexture]
    {
        let PlayerAtlas = SKTextureAtlas(named: "Player")
        var moveFrames = [SKTexture]()
        for index in 1...3
        {
            let textureName = "Player\(index)"
            moveFrames.append(PlayerAtlas.textureNamed(textureName))
        }
        return moveFrames
    }
    
    //Initialise the game
    override func didMove(to view: SKView)
    {
        super.didMove(to: view)
        self.view?.scene?.isPaused = true
        //updateScore(value: "READY!")
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
        
        initializeBorders()
        self.scaleMode = .resizeFill
        self.backgroundColor = .black
        
        PlayerFrames = getPlayerFrames()
        
        createSprite(texture: PlayerFrames, height: 13, width: 13, xPos: Int(xstart_pos), yPos: Int(player_floor_pos), node: &Player, catBitMask: gamePhysics.Player,
                     conTestBitMask:[gamePhysics.Void])
        
        Player.texture = PlayerFrames[2]
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() ) //+ 4.5 //Start game
        {
        
            self.Player.run(SKAction.repeatForever(SKAction.animate(with: self.PlayerFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "PlayerRun")
            
            self.view?.scene?.isPaused = false
        }
        scheduledTimerWithTimeInterval()
    }
    
    func scheduledTimerWithTimeInterval()
    {
        // Scheduling timer to Call the function **increaseSpeedInterval** with the interval
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(increaseSpeedInterval), target: self, selector: #selector(self.increaseSpeed), userInfo: nil, repeats: true)
    }
    
    func checkGravity()
    {
        // MARK: GRAVITY , MUST ANIMATE
        if gravity //Gravedad normal
        {
            if Player.yScale < 0 //Esta de cabeza
            {
                Player.yScale *= -1              //Poner de pie
                Player.position.y = player_floor_pos //Pegar al suelo
            }
        }
        else    //Gravedad Invertida
        {
            if Player.yScale > 0 //Esta de pie
            {
                Player.yScale *= -1 //Voltear de cabeza
                Player.position.y = player_ceil_pos //Pegar al techo
            }
        }
    }
    
    func initializeBorders() //Todo estara lleno
    {
        var offsetX = 0  //Separar barras
        
        barWidth = SKSpriteNode(imageNamed: platform_file_name ).size.width  //Guardar size de las barras
        voidBounding = SKSpriteNode(imageNamed: void_file_name ).size
        voidWidth = voidBounding.width                                       //Size de los voids
        voidBounding.width /= 4                                              //La cuarta parte del tamaño original
        
        for index in 1...touchbarWidth/Int(barWidth) //Llenar top y bottom de bars
        {
            addNewFloor(name: "BarF" + "\(index)", xPosition:CGFloat(offsetX))
            addNewCeil (name: "BarC" + "\(index)", xPosition:CGFloat(offsetX))
            offsetX += Int(barWidth)
        }
        
    }
    
    func addNewFloor(name: String,xPosition : CGFloat)
    {
        let f = SKSpriteNode(imageNamed: platform_file_name )
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
        let c = SKSpriteNode(imageNamed: platform_file_name )
        c.xScale = 1
        c.yScale = 1
        c.position.y = ytop_bars
        c.name = name
        c.position.x = xPosition
        ceilBarArray.append( c )
        self.addChild(c)
    }
    
    func addNewVoid(name: String,xPosition : CGFloat, floor :Bool)
    {
        //Crear objeto
        var _void = SKSpriteNode(imageNamed: void_file_name)
        _void.position.x = xPosition
        _void.name = name           //Maybe deberiamos identificarlo de otra forma
        
        //Agregar fisica para colisiones
        _void.physicsBody = SKPhysicsBody(rectangleOf: voidBounding)
        _void.physicsBody?.categoryBitMask = gamePhysics.Void
        _void.physicsBody?.contactTestBitMask = gamePhysics.Player
        _void.physicsBody?.isDynamic = true
        _void.physicsBody?.affectedByGravity = false
        _void.physicsBody?.collisionBitMask = 0
        
        //Agregar al arreglo y al juego
        if floor
        {
            _void.position.y = ylow_bars
            floorBarArray.append(_void)
        }
        else
        {
            _void.position.y = ytop_bars
            ceilBarArray.append(_void)
        }
        
        self.addChild(_void)
    }
    
    func recycleCeil()
    {
        //Si ya no esta visible
        if let first = ceilBarArray.first, !intersects(_:first)
        {
            let last = ceilBarArray.last!
            ceilBarArray.removeFirst()
            first.removeFromParent()
            
            if coord.nextCeilIsVoid()
            {
                addNewVoid(name: first.name!, xPosition: last.position.x + voidWidth, floor: false)
            }
            else
            {
                addNewCeil(name: first.name!,  xPosition: last.position.x + last.size.width )
            }
        }
    }
    
    func recycleFloor()
    {
        if let first = floorBarArray.first, !intersects(_:first) //Si el primer elemento del suelo NO esta en pantalla (intersects)
        {
            let last = floorBarArray.last!
            floorBarArray.removeFirst()
            first.removeFromParent()
            
            if coord.nextFloorIsVoid()
            {
                addNewVoid(name: first.name!, xPosition: last.position.x + last.size.width, floor: true)
            }
            else
            {
                addNewFloor(name: first.name!,  xPosition: last.position.x + last.size.width )
            }
        }
    }
    
    func moveScene()
    {
        //Mover todas las barras segun la velocidad
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                    node.position.x -= self.movement_speed
            })
        //TODO CAMBIAR EL ORDEN AL AZAR
        recycleCeil()
        recycleFloor()
    }
    
    //Update everything (calls other functions)
    override func update(_ currentTime: TimeInterval)
    {
        moveScene()
        checkGravity()
        
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
                    self.removeBars()
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1)
                    {
                        self.addChild(self.Player)
                        
                        
                        self.Player.position.x = xstart_pos
                        self.Player.position.y = player_floor_pos
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) //Start Game
                        {

                            self.view?.scene?.isPaused = false
                            do
                            {
                                //self.sirenAudio = try AVAudioPlayer(contentsOf: self.sirenS as URL)
                            } catch
                            {
                                print("Could not update audio - sirenS")
                            }
                        }
                    }
                }
            }
        }
    }
}

//extension GameScene
//{
//    var canAddFloorVoid = true  //Las cambia el techo
//    var  canAddCeilVoid = true  //La cambia el suelo
//    // MARK: Board Logic, MUST IMPROVE
//    func shouldAddCeilVoid() -> Bool
//    {
//        var result : Bool = canAddCeilVoid //Checar si podemos poner
//        //TODO ESE RANDOM ALV ALGO BIEN
//        result = result && (arc4random_uniform(20)==0) //Si podemos a ver si la probabilidad nos deja
//        
//        if result
//        {
//            canAddFloorVoid = false //Asegurarnos que si le diremos que si, que el otro no lo ponga
//        }
//        else
//        {
//            canAddFloorVoid = true  //Si no ponemos decirle al otro que si puede
//        }
//        
//        return result
//    }
//    func shouldAddFloorVoid() -> Bool
//    {
//        var result : Bool = canAddFloorVoid //Checar si podemos poner
//        //TODO ESE RANDOM ALV ALGO BIEN
//        result = result && (arc4random_uniform(20)==0) //Si podemos a ver si la probabilidad nos deja
//        
//        if result
//        {
//            canAddCeilVoid = false //Asegurarnos que si le diremos que si, que el otro no lo ponga
//        }
//        else
//        {
//            canAddCeilVoid = true  //Si no ponemos decirle al otro que si puede
//        }
//        
//        return result
//    }
//}

