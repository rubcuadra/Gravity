//
//  WindowController.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/6/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation
import GameplayKit
import AVFoundation

fileprivate extension NSTouchBar.CustomizationIdentifier
{
    static let customTouchBar = "com.RubCuadra.touchbar.customTouchBar"
}

fileprivate extension NSTouchBarItem.Identifier
{
    static let customView = NSTouchBarItem.Identifier("com.RubCuadra.touchbar.items.customView")
}

class WindowController: NSWindowController
{
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
                gameScene.switchGravity()
                break
            default:
                break
        }
    }
}

@available(OSX 10.12.2, *)
extension WindowController: NSTouchBarDelegate
{
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem?
    {
        
        switch identifier
        {
            case NSTouchBarItem.Identifier.customView:
                let gameView = SKView()
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.view = gameView
                item.view.allowedTouchTypes = NSTouch.TouchTypeMask.direct
                item.view.acceptsTouchEvents = true
                //item.view.gestureRecognizers.append(NSGestureRecognizer.init())
                gameView.presentScene(gameScene)

                return item
                
            default:
                return nil
        }
    }
    
}
