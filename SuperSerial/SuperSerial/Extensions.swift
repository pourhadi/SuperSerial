//
//  Extensions.swift
//  SuperSerial
//
//  Created by Daniel Pourhadi on 1/15/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

/**
 Adds basic serialization to String
 */
extension String:Serializable {
    public init?(fromSerialized: Serialized) {
        switch fromSerialized {
        case .Str(let string):
            self = string
        default: return nil
        }
    }

    public func ss_serialize() -> Serialized {
        return Serialized.Str(self)
    }
}

extension CollectionType where Generator.Element == Serialized {
    public func toString() -> String {
        let string = self.reduce("[", combine: { (last, obj) -> String in
            if (last as NSString).length == 1 {
                return "\(last)\n\(obj.toString())"
            } else {
                return "\(last),\n\(obj.toString())"
            }
        })
        return "\(string)\n]"
    }
}

extension Dictionary:Deserializable {}
extension Array:Deserializable {}

extension CGPoint:AutoSerializable {
    public init!(withValuesForKeys: [String : Serializable]) {
        //log("init cgpoint: \(withValuesForKeys)")
        var x:Float = 0.0
        var y:Float = 0.0
        if let xVal = withValuesForKeys["x"] as? Float {
            //log("found x: \(xVal)")
            x = xVal
        }
        if let yVal = withValuesForKeys["y"] as? Float {
            //log("found y: \(yVal)")

            y = yVal
        }
        
        let val = CGPoint(x:CGFloat(x), y:CGFloat(y))
        //log("\(val)")
        self.x = CGFloat(x)
        self.y = CGFloat(y)
        //log("printing self: \(self.dynamicType)")
    }
//    public func ss_serialize() -> Serialized {
//        return Serialized.Str(NSStringFromCGPoint(self) as String)
//    }
}

public protocol SerializableInt:IntegerType, Serializable, Deserializable {}
extension SerializableInt {
    public func ss_serialize() -> Serialized {
        return Serialized.Integer(self)
    }
    
    public init?(fromSerialized:Serialized) {
        switch fromSerialized {
        case .Integer(let int):
            self = int as! Self
        default: return nil
        }
    }
}

public protocol SerializableFloat:FloatingPointType, Serializable, Deserializable {}
extension SerializableFloat {
    public func ss_serialize() -> Serialized {
        return Serialized.FloatingPoint(self)
    }
    
    public init?(fromSerialized:Serialized) {
        switch fromSerialized {
        case .FloatingPoint(let float):
            self = float as! Self
        default: return nil
        }
    }
}

extension Int: SerializableInt {}
extension UInt:SerializableInt {}

extension Float:SerializableFloat {}
extension Double:SerializableFloat {}
extension CGFloat:SerializableFloat {}
