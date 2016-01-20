//
//  Serialization.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/12/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

public protocol Serializable: Deserializable {
    func ss_serialize() -> Serialized
    init?(fromSerialized:Serialized)
}

/**
 When a struct that conforms to AutoSerializable is serialized, its stored properties (those with types that conform to Serializable) are automatically included in the serialization.
 
 -ss_serialize() and -init?(fromSerialized:) are implemented in an extension; only -init?(withValuesForKeys:) needs to be implemented by the conforming struct.
 */
public protocol AutoSerializable:Serializable {
    init?(withValuesForKeys:[String:Serializable])
}

public protocol SerializableObject: class, Serializable {
    init()
}

/** 
 Objects that inherit from NSObject can conform to SerializableKVCObject for easy serialization of its Serializable-conforming properties listed in -serializableKeys.
 
 -valueForKey: and -setValue:forKey: do not need to be manually implemented, as they are implemented by NSObject.
 */
public protocol SerializableKVCObject:SerializableObject, AutoSerializable {
    static var serializableKeys:[String] { get }
    
    func valueForKey(key:String) -> AnyObject
    func setValue(value: AnyObject?, forKey key: String)
}


private func log(logMessage: String, functionName: String = __FUNCTION__) {
    print("\(functionName): \(logMessage)")
}

private let _ss = SuperSerial()
public class SuperSerial {
    /// Custom types that can be deserialized must be specified here prior to deserialization.
    public class var serializableTypes:[Serializable.Type] {
        get {
            var all = _ss.customSerializableTypes
            all.appendContentsOf(_ss.internalSerializableTypes)
            return all
        }
        set {
            _ss.customSerializableTypes = newValue
        }
    }
    
    private var customSerializableTypes = [Serializable.Type]()
    private var internalSerializableTypes:[Serializable.Type] {
        return [Int.self, UInt.self, Float.self, String.self, CGPoint.self, SSColor.self]
    }
}

public enum Serialized: CustomStringConvertible {
    indirect case CustomType(typeName:String, data:Serialized)
    indirect case Dict([String:Serialized])
    indirect case Array([Serialized])
    case Str(String)
    case Integer(Int)
    case FloatingPoint(Float)
    
    public func toString() -> String {
        var string = "{\"ss_case\": \"\(self.caseAsString())\", \"ss_value\": "
        switch self {
        case .CustomType(let name, let data):
            string += "{\"ss_typeName\": \"\(name)\",\"ss_data\":"
            string += data.toString()
            string += "}"
            break
        case .Dict(let dict):
            string += "{"
            for (key, value) in dict {
                string += "\"\(key)\": \(value.toString()),"
            }
            string.removeAtIndex(string.endIndex.predecessor())
            string += "}"
            break
        case .Array(let array):
            string += array.toString()
            break
        case .Str(let str):
            string += "\"\(str)\""
            break
        case .Integer(let int):
            string += "\(int)"
            break
        case .FloatingPoint(let float):
            string += "\(float)"
            break
        }
        
        return string + "}"
    }
    
    private enum Case:String {
        case CustomType = "type"
        case Dict = "dict"
        case Array = "array"
        case Str = "string"
        case Int = "int"
        case Float = "float"
    }
    
    private func caseAsString() -> String {
        switch self {
        case .CustomType: return Case.CustomType.rawValue
        case .Dict: return Case.Dict.rawValue
        case .Array: return Case.Array.rawValue
        case .Str: return Case.Str.rawValue
        case .Integer: return Case.Int.rawValue
        case .FloatingPoint: return Case.Float.rawValue
        }
    }
    
    public var description:String {
        return self.toString()
    }
    
    public init(typeName:String, data:[String:Serialized]) {
        self = Serialized.CustomType(typeName: typeName, data: Serialized.Dict(data))
    }
    
    public init(fromArray:[Serializable]) {
        self = Serialized.Array(fromArray.map { $0.ss_serialize() })
    }
    
    public init?(serializedString:String) {
        let data = (serializedString as NSString).dataUsingEncoding(NSASCIIStringEncoding)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            self = Unwrapper.unwrap(json)
        } catch {
            return nil
        }
    }
    
    public init?(data:NSData) {
        if let string = NSString(data: data, encoding: NSASCIIStringEncoding) {
            if let new = Serialized(serializedString: string as String) {
                self = new
            }
        }
        return nil
    }
    
    func toData() -> NSData {
        return (self.toString() as NSString).dataUsingEncoding(NSASCIIStringEncoding)!
    }
}

private enum SSKeys:String {
    case Case = "ss_case"
    case Value = "ss_value"
    case TypeName = "ss_typeName"
    case Data = "ss_data"
}

private class Unwrapper {
    private class func unwrapDictionary(dictionary:NSDictionary) -> Serialized {
        
        func rawDictionary(dictionary:NSDictionary) -> [String:Serialized] {
            var dict = [String:Serialized]()
            for (key, value) in dictionary {
                dict[key as! String] = unwrap(value)
            }
            return dict
        }
        
        if let caseType = dictionary[SSKeys.Case.rawValue] {
            if let caseValue = dictionary[SSKeys.Value.rawValue] {
                return Unwrapper.unwrapCase(Serialized.Case(rawValue: caseType as! String)!, value: caseValue)
            }
        } else if let typeName = dictionary[SSKeys.TypeName.rawValue] {
            if let typeData = dictionary[SSKeys.Data.rawValue] {
                if let typeData = typeData as? NSDictionary {
                    return Serialized(typeName:typeName as! String, data:rawDictionary(typeData))
                }
            }
        }
        
        return Serialized.Dict(rawDictionary(dictionary))
    }
    
    private class func unwrapCustomType(value:NSDictionary) -> Serialized {
        if let typeName = value[SSKeys.TypeName.rawValue] as? String {
            if let data = value[SSKeys.Data.rawValue] as? NSDictionary {
                return Serialized.CustomType(typeName: typeName, data: Unwrapper.unwrapDictionary(data))
            }
        }
        return Serialized.Str("")
    }


    private class func unwrapCase(type:Serialized.Case, value:AnyObject) -> Serialized {
        switch type {
        case .CustomType:
            return Unwrapper.unwrapCustomType(value as! NSDictionary)
        default:
            return Unwrapper.unwrap(value)
        }
    }
    
    
    private class func unwrapArray(array:NSArray) -> Serialized {
        var unwrapped = [Serialized]()
        for val in array {
            unwrapped.append(unwrap(val))
        }
        return Serialized.Array(unwrapped)
    }
    
    private class func unwrap(object:AnyObject) -> Serialized {
        if object is NSDictionary {
            return Unwrapper.unwrapDictionary(object as! NSDictionary)
        } else if object is NSArray {
            return Unwrapper.unwrapArray(object as! NSArray)
        } else if object is NSString {
            return Serialized.Str(object as! String)
        } else if object is NSNumber {
            let intCodes = ["i", "s", "l", "q", "I", "S", "L", "Q"]
            
            let num = object as! NSNumber
            let type = NSString(CString: num.objCType, encoding: NSUTF8StringEncoding) as! String
            if type == "f" || type == "d" {
                return Serialized.FloatingPoint(num.floatValue)
            } else if intCodes.contains(type) {
                return Serialized.Integer(num.integerValue)
            }
        }
        
        return Serialized.Str("")
    }
}


extension Serialized {
    public func deserialize() -> Deserializable? {
        switch self {
        case .Dict(let dict):
            var newDict = [String:Serializable]()
            for (key, value) in dict {
                let x:Serializable = value.deserialize() as! Serializable
                newDict[key] = x
            }
            return newDict
        case .Array(let array):
            var newArray = [Serializable]()
            for obj in array {
                newArray.append(obj.deserialize() as! Serializable)
            }
            return newArray
        case .Str(let string):
            return string
        case .Integer(let int):
            return (int)
        case .FloatingPoint(let float):
            return float
        case .CustomType(let typeName, let data):
            let names = SuperSerial.serializableTypes.map({ $0.ss_typeName })
            if let index = names.indexOf("\(typeName).Type") {
                let type:Serializable.Type = SuperSerial.serializableTypes[index]
                let initd = type.init(fromSerialized: data)
                return initd
                
            }
            return nil
        }
    }
}

public protocol Deserializable {}

public extension AutoSerializable {
    public init?(fromSerialized: Serialized) {
        switch fromSerialized {
        case .Dict(let dict):
            var newData = [String:Serializable]()
            for (key,value) in dict {
                if let d = value.deserialize() {
                newData[key] = d as? Serializable
                }
            }
            self.init(withValuesForKeys: newData)
            break
        default: return nil
        }
    }
}

public extension SerializableKVCObject {
    public init?(withValuesForKeys: [String : Serializable]) {
        self.init()
        for (key, value) in withValuesForKeys {
            if self.dynamicType.serializableKeys.contains(key) {
                self.setValue(value as? AnyObject, forKey: key)
            }
        }
    }
}

// this extension is able to automatically serialize custom structs
public extension Serializable {
    static var ss_typeName:String {
        let ref = Mirror(reflecting: self)
        return "\(ref.subjectType)"
    }

    public func ss_serialize() -> Serialized {
        let ref = Mirror(reflecting: self)
        if let displayStyle = ref.displayStyle {
            if displayStyle == Mirror.DisplayStyle.Struct && ref.children.count > 0 {
                var dict = [String:Serialized]()
                ref.children.forEach({ (tuple) -> () in
                    if let label = tuple.label {
                        switch tuple.value {
                        case let val as Serializable:
                            dict[label] = val.ss_serialize()
                            break
                        default:
                            if let unwrapped = Mirror(reflecting: tuple.value).descendant("Some") as? Serializable {
                                dict[label] = unwrapped.ss_serialize()
                            }
                            break
                        }
                    }
                })
                return Serialized(typeName: "\(ref.subjectType)", data: dict)
            }
        }
        return Serialized.Str("")
    }
}

public extension SerializableKVCObject {
    public func ss_serialize() -> Serialized {
        var dict = [String:Serialized]()
        
        for key in self.dynamicType.serializableKeys {
            dict[key] = (self.valueForKey(key) as? Serializable)?.ss_serialize()
        }
        return Serialized.CustomType(typeName: self.dynamicType.ss_typeName, data: Serialized.Dict(dict))
    }
}
