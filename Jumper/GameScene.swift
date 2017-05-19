//
//  GameScene.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/19/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation
import SpriteKit
import Cocoa

struct gamePhysics
{
    static let Player: UInt32 = 1
    static let Void: UInt32 = 2
    //static let Blinky: UInt32 = 3
}

//TODO : ANIMAR EL SALTO
//TODO : DEFINIR CADA CUANTO CAMBIARA LA DIFICULTAD Y COMO SE HARA
//TODO : SUELO QUE SE DESTRUYE

class GameScene: SKScene, SKPhysicsContactDelegate
{
    //Hilo de funciones cada x segundos
    var timer = Timer()
    //Sizes - Coords
    let touchbarHeight = 60
    let touchbarWidth = 1024
    var barWidth : CGFloat  = 0             //Se llenan en el init de borders
    var voidWidth : CGFloat = 0             //Se llenan en el init de borders
    var voidBounding : CGSize = CGSize()    //Bounding Box para fisica
    
    let xstart_pos = CGFloat(50)       //Distancia en X donde esta el player
    let player_floor_pos = CGFloat(10) //Posicion 'Suelo' del Player
    let player_ceil_pos = CGFloat(20)  //Posicion 'Techo' del Player
    let ytop_bars = CGFloat(28)        //Posicion donde se coloca la platform CEIL
    let ylow_bars = CGFloat(2)         //Posicion donde se coloca la platform FLOOR
    
    //Views
    let platform_file_name = "barSB"
    let void_file_name = "barSB2"
    //Platforms Arrays
    var ceilBarArray = [SKSpriteNode]()
    var floorBarArray = [SKSpriteNode]()
    //Players Sprites
    var Player: SKSpriteNode!
    var PlayerFrames: [SKTexture]!
    
    //Game Flags/Logic
    var gravity = true
    var coord = Coordinator.instance
    var gameOver = false         //Juego acabo
    
    var barIsWhite: Bool = false //Flash
    
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
        gameOver = true
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
    func increaseDifficulty()
    {
        //SI no se ha pausado el juego o no ha terminado
        if (!self.gameOver ||  !self.view!.scene!.isPaused )
        {
            coord.levelUp()
        }
        else
        {
            print("GAME OVER o PAUSED")
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
        
        NotificationCenter.default.addObserver(self, selector: #selector( switchGravity ),
                                                 name: jumpNotification,
                                                 object: nil) //Name viene del windowController
        
        self.view?.scene?.isPaused = true
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
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(coord.increaseDifficultyInterval), target: self, selector: #selector(self.increaseDifficulty), userInfo: nil, repeats: true)
    }
    
    private func checkGravity()
    {
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
    
    private func initializeBorders() //Todo estara lleno
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
    
    private func addNewFloor(name: String,xPosition : CGFloat)
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
    
    private func addNewCeil(name: String,xPosition : CGFloat)
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
    
    private func addNewVoid(name: String,xPosition : CGFloat, floor :Bool)
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
    
    private func recycleCeil()
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
    
    private func recycleFloor()
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
    
    public func switchGravity()
    {
        gravity = !gravity
    }
    
    private func moveScene()
    {
        //Mover todas las barras segun la velocidad
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                node.position.x -= self.coord.movement_speed
            })
        
        recycleCeil()   //Pone Void o Piso segun coord
        recycleFloor()  //Pone Void o Piso segun coord
        coord.refill()  //Ya que nos dijo que poner, decirle que siga creando
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
                        
                        
                        self.Player.position.x = self.xstart_pos
                        self.Player.position.y = self.player_floor_pos
                        
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
