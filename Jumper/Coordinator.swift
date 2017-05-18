//
//  coordinator.swift
//  Jumper
//
//  Created by Ruben Cuadra on 5/15/17.
//  Copyright © 2017 Ruben Cuadra. All rights reserved.
//

import Foundation
import SpriteKit

//TODO : (RE)LLENAR COORDINATOR

//TODO : Mejorar Random
//TODO : Decidir cual AddLow OR AddTop debera tener el +1(?)
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
    let maxVoidsTogether = 5
    var currentVoidsTogether = 0  //Control flag
    //AddTop y AddLow, cuando NO caen en void invocan a su contraparte
    //La idea es que con esto sepamos si la invoca con su mismo indice o
    //con su indice + 1
    var ceil_offset = 0
    var floor_offset = 0
    
    public func nextCeilIsVoid() -> Bool
    {
        ceil_production.append(ceil_production.removeFirst())
        return !ceil_production.last!
    }
    
    public func nextFloorIsVoid() -> Bool
    {
        floor_production.append(floor_production.removeFirst())
        return !floor_production.last!
    }
    
    private func addTop(i: Int)
    {
        if !(i < (Coordinator.size-1))  //Siempre dejamos las ultimas posiciones libres
        { return }
        
        //SI la funcion random nos dice que debemos agregar Y 
        //no se  ha puesto un void en la diagonal principal
        if floor_production[i-1] && randVoid() && currentVoidsTogether<maxVoidsTogether
        {
            ceil_production[i] = false    //El actual sera un void
            floor_production[i] = true    //Asegurar el otro no sera void
            floor_production[i+1] = true  //Asegurar que el siguiente tampoco es void
            currentVoidsTogether += 1
            addTop(i: i + 1)
        }
        else                        //Poner platform
        {
            ceil_production[i] = true
            currentVoidsTogether = 0
            addLow(i: i + ceil_offset)
        }
    }
    
    private func addLow(i:Int)
    {
        if !(i < (Coordinator.size-1))  //Siempre dejamos las ultimas posiciones libres
        { return }
        
        //SI la funcion random nos dice que debemos agregar Y
        //no se  ha puesto un void en la diagonal principal
        if ceil_production[i-1] && randVoid() && currentVoidsTogether<maxVoidsTogether
        {
            floor_production[i] = false     //El actual sera un void
            ceil_production[i] = true       //Asegurar el otro no sera void
            ceil_production[i+1] = true     //Asegurar que el siguiente tampoco es void
            currentVoidsTogether += 1
            addLow(i: i + 1)
        }
        else                                //Poner platform
        {
            ceil_production[i] = true
            currentVoidsTogether = 0
            addTop(i: i + floor_offset) //Con esto decimos que low sera el que aumenta, CAMBIAR ESTO
        }
    }
    private func printProds()
    {
        for i in 0..<Coordinator.size
        {
            print("\(i) \(floor_production[i]) \(ceil_production[i])")
        }
    }
    
    func fillFromTop(ix: Int)
    {
        ceil_offset = 0
        floor_offset = 1
        addTop(i: ix) //Empieza llenando desde arribaa
    }
    
    private init() //Singleton
    {
        fillFromTop(ix: 1)
        printProds()
    }
    
    //MARK : RANDOM LOGIC
    //Nos dira si deberiamos poner un void con base en la probabilidad
    private func randVoid() -> Bool
    {
        return arc4random_uniform(8)==0
    }
}
