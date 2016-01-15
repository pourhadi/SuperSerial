//
//  Serialization.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/12/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

public enum Serialized {
    indirect case Dict([String:Serialized])
    indirect case Array([Serialized])
    case Str(String)
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