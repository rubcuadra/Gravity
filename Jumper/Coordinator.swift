//
//  coordinator.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/15/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation
import SpriteKit

//TODO : Mejorar Random
//TODO : IR DESTRUYENDO EL PISO ??

class Coordinator
{
    //Singleton
    static let instance = Coordinator()
    
    //Arrays Size
    private static let size = 10         //Static necesario para los inits
    
    //Arreglos de booleanos, cuando es TRUE significa que habra una plataforma, un false
    //nos da un void
    var  ceil_production = [Bool](repeating: true, count: size)
    var floor_production = [Bool](repeating: true, count: size)
    
    //Game Logic Flags
    let maxVoidsTogether = 3
    var currentTopVoidsTogether = 0  //Control flag
    var currentLowVoidsTogether = 0  //Control flag
    var temp = true          //Variable temp que usaran las funciones next, mas eficiente que estar creando y borrando variables
    
    let cooldown = 2 //Poder checar arra[size-1] y array[size-2]
    var lastTopDummies  = 0 //Esto se debe sumar 1 cada vez que insertamos un TRUE al final
    var lastLowDummies  = 0 //Esto se debe sumar 1 cada vez que insertamos un TRUE al final
    
    public func nextCeilIsVoid() -> Bool
    {
        temp = ceil_production.removeFirst()
        ceil_production.append(true) ; lastTopDummies += 1
        return !temp
    }
    
    public func nextFloorIsVoid() -> Bool
    {
        temp = floor_production.removeFirst()
        floor_production.append(true) ; lastLowDummies += 1
        return !temp
    }
    
    //La idea es que esta funcion sea invocada despues de haber popeado ambos arrays
    //(Haber llamado tanto nextCeil como nextFloor)
    public func refill()
    {
        if (lastLowDummies >= cooldown) && (lastTopDummies >= cooldown)
        {
            if arc4random_uniform(2)==0 //50%
            {
                addLow(i: Coordinator.size-1, leader: true) //Empieza llenando desde arriba
            }
            else
            {
                addTop(i: Coordinator.size-1, leader: true) //Empieza llenando desde abajo
            }
            lastTopDummies = 0
            lastLowDummies = 0
        }
    }
    
    private func addTop(i: Int, leader: Bool)
    {
        if !(i < Coordinator.size) { return }
        
        //SI del otro lado, en este mismo indice y -1 NO hay voids, podemos poner
        //SI no hemos puesto el limite de seguidos
        //SI la funcion random nos dice que debemos poner
        if (floor_production[i-1] && floor_production[i]) && currentTopVoidsTogether<maxVoidsTogether && randVoid()
        {
            ceil_production[i] = false    //El actual sera un void
            currentTopVoidsTogether += 1
        }
        else
        {
            ceil_production[i] = true     //Poner platform
            currentTopVoidsTogether = 0
        }
        
        addLow(i: i + (leader ? 0 : 1), leader: !leader ) //Si es lider que le sume 1 el otro
    }
    
    private func addLow(i:Int, leader:Bool)
    {
        if !(i < Coordinator.size) { return }
        
        //SI del otro lado, en este mismo indice y -1 NO hay voids, podemos poner
        //SI no hemos puesto el limite de seguidos
        //SI la funcion random nos dice que debemos poner
        if (ceil_production[i-1] && ceil_production[i]) && currentLowVoidsTogether<maxVoidsTogether && randVoid()
        {
            floor_production[i] = false     //El actual sera un void
            currentLowVoidsTogether += 1
        }
        else                                //Poner platform
        {
            floor_production[i] = true
            currentLowVoidsTogether = 0
        }
        addTop(i: i + (leader ? 0 : 1), leader: !leader ) //Si es lider que le sume 1 el otro
    }
    private func printProds()
    {
        for i in 0..<Coordinator.size
        {
            print("\(i) \(floor_production[i]) \(ceil_production[i])")
        }
    }
    
    private init() //Singleton
    {
        addTop(i: 1, leader : true) //Empieza llenando desde arribaa
        //addLow(i: 1, leader: true) //Empieza llenando desde arribaa
        printProds()
    }
    
    //MARK : RANDOM LOGIC
    //Nos dira si deberiamos poner un void con base en la probabilidad
    private func randVoid() -> Bool
    {
        return arc4random_uniform(8)==0
    }
}
