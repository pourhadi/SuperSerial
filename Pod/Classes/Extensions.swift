//
//  Extensions.swift
//  SuperSerial
//
//  Created by Daniel Pourhadi on 1/15/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

extension String: Serializable {
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

public protocol SerializableInt:IntegerType, Serializable, Deserializable {}
extension SerializableInt {
    public func ss_serialize() -> Serialized {
        return Serialized.Integer(self as! Int)
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
        return Serialized.FloatingPoint(self as! Float)
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


///Serializable UIColor subclass
public final class SSColor : UIColor, SerializableObject {
    public func ss_serialize() -> Serialized {
        return Serialized.CustomType(typeName: "SSColor", data: Serialized.Str(self.hexString()))
    }
    
    public convenience init?(fromSerialized:Serialized) {
        switch fromSerialized {
        case .Str(let string):
            self.init(rgba: string)
            break
        default: return nil
        }
    }
    
    public override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required convenience public init(colorLiteralRed red: Float, green: Float, blue: Float, alpha: Float) {
        fatalError("init(colorLiteralRed:green:blue:alpha:) has not been implemented")
    }
    
    init?(rgba:String) {
        guard let hexString: String = rgba.substringFromIndex(rgba.startIndex.advancedBy(1)),
            var   hexValue:  UInt32 = 0
            where NSScanner(string: hexString).scanHexInt(&hexValue) else {
                super.init()
                return
        }
        let hex8 = hexValue
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        super.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
