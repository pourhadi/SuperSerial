//
//  Serialization.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/12/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

public enum Serialized: CustomStringConvertible {
    indirect case Dict([String:Serialized])
    indirect case Array([Serialized])
    case Str(String)
    
    public func toString() -> String {
        switch self {
        case .Dict(let dict):
            var string = "{"
            for (key, value) in dict {
                string += "\(key): \(value.toString()),"
            }
            string.removeAtIndex(string.endIndex.predecessor())
            string += "}"
            return string
        case .Array(let array):
            let arrayString = array.reduce("[", combine: { (last, obj) -> String in
                if (last as NSString).length == 1 {
                    return "\(last)\(obj.toString())"
                } else {
                    return "\(last), \(obj.toString())"
                }
            })
            return "\(arrayString)]"
        case .Str(let string):
            return string
        }
    }
    
    public var description:String {
        return self.toString()
    }
}

public protocol Serializable {
    func serialize() -> Serialized
    static func fromSerialized(serialized:Serialized) -> Self?
}

// this extension is able to automatically serialize custom structs
extension Serializable {
    static func fromSerialized(serialized:Serialized) -> Self? {
        return nil
    }
    
    func serialize() -> Serialized {
        let ref = Mirror(reflecting: self)
        if let displayStyle = ref.displayStyle {
            if displayStyle == Mirror.DisplayStyle.Struct && ref.children.count > 0 {
                var dict = [String:Serialized]()
                ref.children.forEach({ (tuple) -> () in
                    if let label = tuple.label {
                        switch tuple.value {
                        case let val as Serializable:
                            dict[label] = val.serialize()
                            break
                        default:
                            if let unwrapped = Mirror(reflecting: tuple.value).descendant("Some") as? Serializable {
                                dict[label] = unwrapped.serialize()
                            }
                            break
                        }
                    }
                })
                return Serialized.Dict(dict)
            }
        }
        return Serialized.Str("")
    }
}