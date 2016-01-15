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
    public static func fromSerialized(serialized: Serialized) -> String? {
        switch serialized {
        case .Str(let string): return string
        default: return nil
        }
    }
    
    public func serialize() -> Serialized {
        return Serialized.Str(self)
    }
}

extension Array where Element: Serializable {
    /**
     Adds serialization to Swift arrays of elements that conform to Serializable.
     
     ```
     var strings = ["one", "two", "three"]
     var serialized = strings.serialize()
     ```
     
     */
    public func serialize() -> Serialized {
        return Serialized.Array(self.map { $0.serialize() } )
    }
    
    /**
     Deserializes a Serialized.Array to its Serializable Element.
     */
    public static func fromSerialized(serialized:Serialized) -> [Element]? {
        switch serialized {
        case .Array(let array):
            return array.map({ (e) -> Element in
                return Element.fromSerialized(e)!
            })
        default: return nil
        }
    }
}

extension CollectionType where Generator.Element == Serialized {
    public static func fromSerialized(serialized:Serialized) -> [Serialized]? {
        switch serialized {
        case .Array(let array):
            return array
        default: return nil
        }
    }
    
    public func serialize() -> Serialized {
        return Serialized.Array(self as! [Serialized])
    }
}

extension CGPoint:Serializable {
    public static func fromSerialized(serialized: Serialized) -> CGPoint? {
        switch serialized {
        case .Str(let string): return CGPointFromString(string)
        default: return nil
        }
    }
    
    public func serialize() -> Serialized {
        return Serialized.Str(NSStringFromCGPoint(self) as String)
    }
}