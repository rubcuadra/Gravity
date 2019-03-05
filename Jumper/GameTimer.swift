//
//  GameTimer.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/21/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation

protocol GameTimerProtocol : class
{
    func currentTime(_ timer: GameTimer, cTime: TimeInterval)
}

class GameTimer
{
    //Singleton
    static let instance = GameTimer()
    
    private init(){}

    private var subscribers = [GameTimerProtocol]() //Delegates
    
    var timer: Timer? = nil
    var startTime: Date?
    var elapsedTime: TimeInterval = 0
    
    var isStopped: Bool
    {
        return timer == nil && elapsedTime == 0
    }
    var isPaused: Bool
    {
        return timer == nil && elapsedTime > 0
    }
    
    func startTimer()
    {
        startTime = Date()
        elapsedTime = 0
        
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerAction),
                                     userInfo: nil,
                                     repeats: true)
        timerAction()
    }
    
    // 2
    func resumeTimer()
    {
        startTime = Date(timeIntervalSinceNow: -elapsedTime)
        
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(timerAction),
                                     userInfo: nil,
                                     repeats: true)
        timerAction()
    }
    
    // 3
    func stopTimer()
    {
        // really just pauses the timer
        timer?.invalidate()
        timer = nil
        
        timerAction()
    }
    
    // 4
    func resetTimer()
    {
        // stop the timer & reset back to start
        timer?.invalidate()
        timer = nil
        
        startTime = nil
        elapsedTime = 0
        
        timerAction()
    }
    
    func unsuscribe(delegate: GameTimerProtocol)
    {
        subscribers = subscribers.filter() { $0 !== delegate }
    }
    
    func subscribe(delegate: GameTimerProtocol )
    {
        subscribers.append(delegate)
    }
    
    @objc dynamic func timerAction()
    {
        //startTime Optional Date, if nil, the timer cannot be running
        guard let startTime = startTime else
        {
            return
        }
        
        //startTime is earlier than now, so timeIntervalSinceNow produces a negative value.
        elapsedTime = -startTime.timeIntervalSinceNow
        
        for s in subscribers //Avisarle a los que suscribieron
        {
            s.currentTime(self, cTime: elapsedTime)
        }
    }
}


