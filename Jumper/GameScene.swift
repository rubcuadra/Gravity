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
    static let Platform: UInt32 = 3
}

//TODO : ANIMAR EL SALTO
//TODO : DEFINIR SPRITES
//TODO : MUSICA

class GameScene: SKScene, SKPhysicsContactDelegate
{
    //Hilo de funciones cada x segundos
    var gameTimer = GameTimer.instance
    //Sizes - Coords
    let touchbarHeight = 60
    let touchbarWidth = 720
    var barWidth : CGFloat  = 0             //Se llenan en el init de borders
    var voidWidth : CGFloat = 0             //Se llenan en el init de borders
    var voidBounding : CGSize = CGSize()    //Bounding Box para fisica
    var platformBounding : CGSize = CGSize()    //Bounding Box para fisica
    
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
    var coord = Coordinator.instance
    let removedPerCrash = 4 //Se suma al top/low removal para quitar X celdas cada choque
    var topRemoval = 0      //Cuantas celdas se deben remover arriba
    var lowRemoval = 0      //Cuantas celdas se deben remover abajo
    var gravity = true
    
    var barIsWhite: Bool = false //Flash
    
    private func createPlayer(texture: [SKTexture], height: Int, width: Int, xPos: Int, yPos: Int, node: inout SKSpriteNode!, catBitMask: UInt32, conTestBitMask: [UInt32])
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
        node.physicsBody?.allowsRotation = false
        self.addChild(node)
    }
    
    private func removeBars()
    {
        self.enumerateChildNodes(withName: "Bar" + "*", using:
            {
                (node, stop) -> Void in
                node.removeFromParent()
            })
        ceilBarArray.removeAll()
        floorBarArray.removeAll()
    }
    
    private func GameOver()
    {
        self.view?.scene?.isPaused = true
        removeBars()                //Remover las barras que queden
        gameTimer.resetTimer()
        NotificationCenter.default.post(name: gameOverNotification, object: nil)
        //sirenAudio.stop()
        DeathFrames()
    }
    
    private  func flashBars()
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
    
    private func flashAfterDelay(delay: Double)
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay)
        {
            self.flashBars()
        }
    }
    
    private func DeathFrames()
    {
        var PlayerD: SKSpriteNode!
        let DeathAtlas = SKTextureAtlas(named: "PlayerD")
        var deathFrames = [SKTexture]()
        let totalFrames = 20
        for index in 1...totalFrames
        {
            let textureName = "PlayerD\(index)"
            deathFrames.append(DeathAtlas.textureNamed(textureName))
        }
        
        PlayerD = SKSpriteNode(texture: deathFrames[0])
        
        PlayerD.position.x = self.Player.position.x
        PlayerD.position.y = 15 //Prueba, que muera en el centro?
        
        Player.removeAction(forKey: "PlayerRun")
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
            for i in 1...totalFrames
            {
                PlayerD.run(SKAction.animate(with: deathFrames, timePerFrame: 0.05, resize: false, restore: true), withKey: "GameOver")
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.3)
            {
                self.view?.scene?.isPaused = true
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact)
    {
        let firstBody: SKPhysicsBody = contact.bodyA
        let secondBody: SKPhysicsBody = contact.bodyB
        if firstBody.categoryBitMask == gamePhysics.Platform || secondBody.categoryBitMask == gamePhysics.Platform {return}

        if (firstBody.categoryBitMask  == gamePhysics.Player) && (secondBody.categoryBitMask == gamePhysics.Void) ||
           (secondBody.categoryBitMask == gamePhysics.Player) && (firstBody.categoryBitMask == gamePhysics.Void)
        {
            print("CHOCARON")
            
            topRemoval += removedPerCrash //11 choques empiezan a reducir la barra
            lowRemoval += removedPerCrash
            
            if(ceilBarArray.count < 7)
            {
                GameOver()
            }
        }
        
    }
    
    private func getPlayerFrames() -> [SKTexture]
    {
        let PlayerAtlas = SKTextureAtlas(named: "Player")
        var moveFrames = [SKTexture]()
        for index in 1...12 //Player Sprites
        {
            let textureName = "Player\(index)"
            moveFrames.append(PlayerAtlas.textureNamed(textureName))
        }
        return moveFrames
    }
    
    func togglePause()
    {
        if self.view!.scene!.isPaused //Si esta en pausa, la reanudaremos
        {
            if gameTimer.isPaused //Si esta pausado RESUME
            {
                gameTimer.resumeTimer()
            }
            else                  //De otra forma iniciar en 0
            {
                gameTimer.startTimer()
            }
        }
        else  //Si no estamos en pause es que lo estaremos, pausar timer
        {
            gameTimer.stopTimer()
        }
        
        
        
        self.view?.scene?.isPaused = !self.view!.scene!.isPaused
    }
    
    func resetGame()
    {
        initializeBorders()
        coord.start()
        PlayerFrames = getPlayerFrames()
        createPlayer(texture: PlayerFrames, height: 13, width: 13, xPos: Int(xstart_pos), yPos: Int(player_floor_pos), node: &Player,    catBitMask: gamePhysics.Player, conTestBitMask:[gamePhysics.Void])
        Player.texture = PlayerFrames[2]
        self.Player.run(SKAction.repeatForever(SKAction.animate(with: self.PlayerFrames, timePerFrame: 0.05, resize: false, restore: true)), withKey: "PlayerRun")
    }
    
    //Initialise the game
    override func didMove(to view: SKView)
    {
        super.didMove(to: view)
        self.view?.scene?.isPaused = true //Se inicializa pero en Pausa
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx:0.0,dy:-0.98) //Cambiar esto
        gameTimer.subscribe(delegate: self)
        self.scaleMode = .resizeFill
        self.backgroundColor = .black
        resetGame()
    }
    
    private func initializeBorders() //Todo estara lleno
    {
        var offsetX = 0  //Separar barras
        
        platformBounding = SKSpriteNode(imageNamed: platform_file_name ).size
        barWidth = platformBounding.width  //Guardar size de las barras
        
        voidBounding = SKSpriteNode(imageNamed: void_file_name ).size
        voidWidth = voidBounding.width                                       //Size de los voids
        voidBounding.width /= 4                                              //La cuarta parte del tamaño original
        
        for index in 1...touchbarWidth/Int(barWidth) //Llenar top y bottom de bars
        {
            addNewPlatform( name: "BarF" + "\(index)", xPosition:CGFloat(offsetX), floor: true)
            addNewPlatform( name: "BarC" + "\(index)", xPosition:CGFloat(offsetX), floor: false)
            offsetX += Int(barWidth)
        }
    }
    
    private func addNewPlatform(name:String ,xPosition: CGFloat, floor: Bool)
    {
        let f = SKSpriteNode(imageNamed: platform_file_name )
        f.xScale = 1
        f.yScale = 1
        f.position.x = xPosition
        f.name = name
        
        
        //Agregar fisica para colisiones
        f.physicsBody = SKPhysicsBody(rectangleOf: platformBounding)
        f.physicsBody?.categoryBitMask = gamePhysics.Platform
        f.physicsBody?.contactTestBitMask = gamePhysics.Player
        f.physicsBody?.isDynamic = true
        f.physicsBody?.affectedByGravity = false
        f.physicsBody?.collisionBitMask = 0
        
        if floor
        {
            f.position.y = ylow_bars
            floorBarArray.append( f )
        }
        else
        {
            f.position.y = ytop_bars
            ceilBarArray.append( f )
        }
        self.addChild(f)
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
            
            if topRemoval == 0 //NO debemos remover ninguno
            {
                if coord.nextCeilIsVoid()
                {
                    addNewVoid(name: first.name!, xPosition: last.position.x + voidWidth, floor: false)
                }
                else
                {
                    addNewPlatform( name: first.name!, xPosition:last.position.x+last.size.width, floor: false)
                }
            }
            else
            {
                topRemoval -= 1 //Ya se quito 1 elemento del array
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
            
            if lowRemoval == 0 //NO debemos remover ninguno
            {
                if coord.nextFloorIsVoid()
                {
                    addNewVoid(name: first.name!, xPosition: last.position.x + last.size.width, floor: true)
                }
                else
                {
                    addNewPlatform( name: first.name!, xPosition:last.position.x+last.size.width, floor: true)
                }
            }
            else
            {
                lowRemoval -= 1 //Ya se quito 1 elemento del array
            }
            
        }
    }
    
    public func switchGravity()
    {
        //SOLO SI NO ESTA PAUSADA LA SCENE
        if (self.view?.scene?.isPaused)!{return}
        
        gravity = !gravity
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

extension GameScene: GameTimerProtocol
{
    //MARK: GAME TIME PROTOCOL
    func currentTime(_ timer: GameTimer, cTime: TimeInterval)
    {
        //cTime son todos los segundos que han pasado
        if Int(cTime) % coord.increaseDifficultyInterval == 0
        {
            coord.levelUp()
            print("Level UP \( Int(cTime) )s")
        }
    }
}
