//
//  Serialization.swift
//  DynUISwift
//
//  Created by Daniel Pourhadi on 1/12/16.
//  Copyright © 2016 Daniel Pourhadi. All rights reserved.
//

import Foundation

private func log(logMessage: String, functionName: String = __FUNCTION__) {
    print("\(functionName): \(logMessage)")
}

private let _ss = SuperSerial()
public class SuperSerial {
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
        return [Int.self, UInt.self, Float.self, String.self, CGPoint.self]
    }
}

public enum Serialized: CustomStringConvertible {
    indirect case Struct(typeName:String, data:Serialized)
    indirect case Dict([String:Serialized])
    indirect case Array([Serialized])
    case Str(String)
    case Integer(IntegerType)
    case FloatingPoint(FloatingPointType)
    
    public func toString() -> String {
        var string = "{\"ss_case\": \"\(self.caseAsString())\", \"ss_value\": "
        switch self {
        case .Struct(let name, let data):
            string += "{\n\"ss_typeName\": \"\(name)\",\n\"ss_data\":\n"
            string += data.toString()
            string += "\n}"
            break
        case .Dict(let dict):
            string += "{"
            for (key, value) in dict {
                string += "\n\"\(key)\": \(value.toString()),"
            }
            string.removeAtIndex(string.endIndex.predecessor())
            string += "\n}"
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
        
        return string + "\n}"
    }
    
    private enum Case:String {
        case Struct = "struct"
        case Dict = "dict"
        case Array = "array"
        case Str = "string"
        case Int = "int"
        case Float = "float"
    }
    
    private func caseAsString() -> String {
        switch self {
        case .Struct: return Case.Struct.rawValue
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
        self = Serialized.Struct(typeName: typeName, data: Serialized.Dict(data))
    }
    
    public init(fromArray:[Serializable]) {
        self = Serialized.Array(fromArray.map { $0.ss_serialize() })
    }
    
    public init?(serializedString:String) {
        let data = (serializedString as NSString).dataUsingEncoding(NSASCIIStringEncoding)!
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            //log("\n\n\n\n\n\n=====-=-=-=-=-=-=\n\n\n\n")
            //log("\(json)")
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
    
    private class func unwrapStruct(value:NSDictionary) -> Serialized {
        if let typeName = value[SSKeys.TypeName.rawValue] as? String {
            if let data = value[SSKeys.Data.rawValue] as? NSDictionary {
                return Serialized.Struct(typeName: typeName, data: Unwrapper.unwrapDictionary(data))
            }
        }
        return Serialized.Str("")
    }


    private class func unwrapCase(type:Serialized.Case, value:AnyObject) -> Serialized {
        switch type {
        case .Struct:
            return Unwrapper.unwrapStruct(value as! NSDictionary)
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
    public func deserialize() -> (value:Deserializable, type:Deserializable.Type)? {
        switch self {
        case .Dict(let dict):
            var newDict = [String:Serializable]()
            for (key, value) in dict {
                let x:Serializable = value.deserialize()!.0 as! Serializable
                newDict[key] = x
            }
            return (newDict, newDict.dynamicType)
        case .Array(let array):
            var newArray = [Serializable]()
            for obj in array {
                newArray.append(obj.deserialize()!.0 as! Serializable)
            }
            return (newArray, newArray.dynamicType)
        case .Str(let string):
            return (string, String.self)
        case .Integer(let int):
            return ((int as! Int), Int.self)
        case .FloatingPoint(let float):
            return (float as! Float, Float.self)
        case .Struct(let typeName, let data):
            //log("desrialize struct")
            let names = SuperSerial.serializableTypes.map({ $0.ss_typeName })
            if let index = names.indexOf("\(typeName).Type") {
                //log("found name")
                let type:Serializable.Type = SuperSerial.serializableTypes[index]
//                var newData = [String:Serializable]()
                //log("initing with data:\(data) --- : \(type.init(fromSerialized: data))")
                //log("=================")
                let initd = type.init(fromSerialized: data)
                //log("=================")

                //log("initd: \(initd)")
                return (initd!, type)
            }
            return nil
        default: return nil
        }
    }
}

public protocol Deserializable {}

public protocol Serializable: Deserializable {
    func ss_serialize() -> Serialized
    init?(fromSerialized:Serialized)
}

public protocol AutoSerializable:Serializable {
    init?(withValuesForKeys:[String:Serializable])
}

public extension AutoSerializable {
    public init?(fromSerialized: Serialized) {
        //log("init auto fromSerialized")
//        let de = fromSerialized.deserialize()
//
        switch fromSerialized {
        case .Dict(let dict):
            //log("\(dict)")
            var newData = [String:Serializable]()
            for (key,value) in dict {
                if let d = value.deserialize() {
                newData[key] = d.0 as? Serializable
                }
            }
            //log("inside fromSerialized: \(newData)")
            self.init(withValuesForKeys: newData)
            break
        default: return nil
        }
        //log("after swift in fromSerialized: \(self)")
    }
}

// this extension is able to automatically serialize custom structs
public extension Serializable {
    static var ss_typeName:String {
        let ref = Mirror(reflecting: self)
        //log("ss_typeName: \(ref.subjectType)")
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