//
//  Extensions.swift
//  SuperSerial
//
//  Created by Daniel Pourhadi on 1/15/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

extension String: Serializable {
    public static func ss_fromSerialized(serialized:Serialized) -> String? {
        switch serialized {
        case .Str(let string):
            return string
        default: return nil
        }
    }
    
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
                return "\(last)\(obj.toString())"
            } else {
                return "\(last),\(obj.toString())"
            }
        })
        return "\(string)]"
    }
}

extension Dictionary:Deserializable {}
extension Array:Deserializable {}

extension CGPoint: AutoSerializable {

    
    public init!(withValuesForKeys: [String : Serializable]) {
        var x:Float = 0.0
        var y:Float = 0.0
        if let xVal = withValuesForKeys["x"] as? Float {
            x = xVal
        }
        if let yVal = withValuesForKeys["y"] as? Float {
            y = yVal
        }
        self.x = CGFloat(x)
        self.y = CGFloat(y)
    }
}

extension CGSize: AutoSerializable {
    public init!(withValuesForKeys:[String: Serializable]) {
        self.width = withValuesForKeys["width"] as! CGFloat
        self.height = withValuesForKeys["height"] as! CGFloat
    }
}

public protocol SerializableRawRepresentable: RawRepresentable, Serializable, Deserializable {}
extension SerializableRawRepresentable where RawValue:Serializable  {
    public func ss_serialize() -> Serialized {
        return self.rawValue.ss_serialize()
    }
    
    public static func ss_fromSerialized(serialized:Serialized) -> Self? {
        return self.init(rawValue:serialized.deserialize() as! RawValue)
    }

    public init?(fromSerialized: Serialized) {
        self.init(rawValue:fromSerialized.deserialize() as! RawValue)
    }
}

extension UIRectCorner:SerializableRawRepresentable {}

public protocol SerializableInt:IntegerType, Serializable, Deserializable {}
extension SerializableInt {
    public func ss_serialize() -> Serialized {
        return Serialized.Integer(self as! Int)
    }
    
    public static func ss_fromSerialized(serialized:Serialized) -> Self? {
        switch serialized {
        case .Integer(let int):
            return int as! Self
        default: return nil
        }
    }
    
    public init?(fromSerialized:Serialized) {
        switch fromSerialized {
        case .Integer(let int):
            self = int as! Self
        default: return nil
        }
    }
}

extension Int: SerializableInt {}
extension UInt:SerializableInt {}

public protocol SerializableFloat:FloatingPointType, Serializable, Deserializable {}
extension SerializableFloat {
    public func ss_serialize() -> Serialized {
        switch self {
        case let x as Float:
            return Serialized.FloatingPoint(x)
        case let x as Double:
            return Serialized.FloatingPoint(Float(x))
        case let x as Float32:
            return Serialized.FloatingPoint(Float(x))
        case let x as Float64:
            return Serialized.FloatingPoint(Float(x))
        case let x as CGFloat:
            return Serialized.FloatingPoint(Float(x))
        default: return Serialized.FloatingPoint(0.0)
        }
    }
    
    public static func ss_fromSerialized(serialized:Serialized) -> Self? {
        switch serialized {
        case .FloatingPoint(let float):
            return float as! Self
        default: return nil
        }
    }
    
    public init?(fromSerialized:Serialized) {
        switch fromSerialized {
        case .FloatingPoint(let float):
            self = float as! Self
        default: return nil
        }
    }
}

extension Float:SerializableFloat {}
extension Double:SerializableFloat {}
extension CGFloat:SerializableFloat {}

extension UIColor: Serializable {
    public static func ss_fromSerialized(serialized: Serialized) -> Self? {
        switch serialized {
        case .Str(let string):
            return self.fromRGBA(string)
        default : return nil
        }
    }
    
    internal static func fromRGBA(rgba:String) -> Self? {
        guard let hexString: String = rgba.substringFromIndex(rgba.startIndex.advancedBy(1)),
            var   hexValue:  UInt32 = 0
            where NSScanner(string: hexString).scanHexInt(&hexValue) else {
                return nil
        }
        let hex8 = hexValue
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        return self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public func ss_serialize() -> Serialized {
        return Serialized.CustomType(typeName: "UIColor", data: Serialized.Str(self.hexString()))
    }
}