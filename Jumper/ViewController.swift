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

    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        let font: NSFont = .systemFont(ofSize: 30)
        // Do any additional setup after loading the view.
    }
    
    public func updateLabel(Score: Int)
    {
        //label.stringValue = String(describing: Score)
    }
    
    override var representedObject: Any?
    {
            didSet
            {
                // Update the view, if already loaded.
            }
    }


}

