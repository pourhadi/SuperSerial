# SuperSerial
Serialization for Swift &amp; value types

SuperSerial uses Mirroring in Swift to automatically infer a Struct's stored variables, allowing for easy serialization by conforming to the Serializable protocol. Conforming that Struct to AutoSerializable allows for easy deserialization as well.

Also supports custom serialization.

Example usage:


    struct Person {
        let name:String
        let age:Int
    }
    
    extension Person:AutoSerializable {
        init?(withValuesForKeys: [String : Serializable]) {
            self.name = withValuesForKeys["name"] as! String
            self.age = withValuesForKeys["age"] as! Int
        }
    }
    
    let people:[Serializable] = [Person(name: "Bob", age: 30), Person(name: "Lisa", age: 32), Person(name: "Mark", age: 29)]

Specify the types that can be serialized and deserialized:

    SuperSerial.serializableTypes = [Person.self]
    
Serialize and deserialize:

    let serialized = Serialized(fromArray: people)
    let jsonString = serialized.toString()
    let fromString = Serialized(serializedString: jsonString)
    let deserialized = fromString?.deserialize()
