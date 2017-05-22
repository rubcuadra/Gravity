//
//  ViewController.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/6/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Cocoa

class ViewController: NSViewController
{
    var restart = false
    
    @IBOutlet weak var togglePlayButton: NSButton!
    
    @IBAction func startClick(_ sender: NSButton)
    {
        if restart
        {
            gameScene.resetGame()
            gameScene.togglePause()
            restart = false
            togglePlayButton.title = "PAUSE"
        }
        else
        {
            gameScene.togglePause()
            togglePlayButton.title = gameScene.isPaused ? "CONTINUE" : "PAUSE"
        }
    }
    func gameOver()
    {
        togglePlayButton.title = "RESTART"
        restart = true
    }
    //TODO : DEFINIR PREFERENCES Y STUFF
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        GameTimer.instance.subscribe(delegate: self)
        
        NotificationCenter.default.addObserver(self, selector:
            #selector( gameOver ),name: gameOverNotification,object: nil)
        //self.view.wantsLayer = true
        //self.view.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        //let font: NSFont = .systemFont(ofSize: 30)
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any?
    {
        didSet
        {
            // Update the view, if already loaded.
        }
    }
}

extension ViewController: GameTimerProtocol
{
    //MARK: GAME TIME PROTOCOL
    func currentTime(_ timer: GameTimer, cTime: TimeInterval)
    {
        
    }
}

