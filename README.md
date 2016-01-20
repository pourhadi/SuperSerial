# SuperSerial

[![CI Status](http://img.shields.io/travis/Daniel Pourhadi/SuperSerial.svg?style=flat)](https://travis-ci.org/Daniel Pourhadi/SuperSerial)
[![Version](https://img.shields.io/cocoapods/v/SuperSerial.svg?style=flat)](http://cocoapods.org/pods/SuperSerial)
[![License](https://img.shields.io/cocoapods/l/SuperSerial.svg?style=flat)](http://cocoapods.org/pods/SuperSerial)
[![Platform](https://img.shields.io/cocoapods/p/SuperSerial.svg?style=flat)](http://cocoapods.org/pods/SuperSerial)

## Usage

SuperSerial uses Mirroring in Swift to automatically infer a Struct's stored variables, allowing for easy serialization by conforming to the Serializable protocol. Conforming that Struct to AutoSerializable allows for easy deserialization as well.

Also supports custom serialization.



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

## Requirements

## Installation

SuperSerial is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SuperSerial"
```

## Author

Daniel Pourhadi, dan@pourhadi.com

## License

SuperSerial is available under the MIT license. See the LICENSE file for more info.
