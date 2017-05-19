//
//  WindowController.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/6/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//
//TODO : QUE NO SALGAN 2 BARRAS EN LA MISMA POSICION
import Foundation
import GameplayKit
import AVFoundation

protocol DetailsDelegate : class
{
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
    let scene = GameScene() //Aqui esta el juego
    let gameView = SKView()
    
    override func windowDidLoad()
    {
        super.windowDidLoad()
    }
    
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
                scene.switchGravity()
                break
            default:
                break
        }
    }
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate
{
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItemIdentifier) -> NSTouchBarItem?
    {
        
        switch identifier
        {
            case NSTouchBarItemIdentifier.customView:
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.view = gameView
                item.view.allowedTouchTypes = NSTouchTypeMask.direct
                item.view.acceptsTouchEvents = true
                //item.view.gestureRecognizers.append(NSGestureRecognizer.init())
                gameView.presentScene(scene)

                return item
                
            default:
                return nil
        }
    }
    
}
