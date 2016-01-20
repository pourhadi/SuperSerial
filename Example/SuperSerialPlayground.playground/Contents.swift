//: Playground - noun: a place where people can play

import UIKit
import SuperSerial

struct Person {
    let name:String
    let age:Int
}

extension Person: AutoSerializable {
    init?(withValuesForKeys:[String:Serializable]) {
        guard let name = withValuesForKeys["name"] as? String else { return nil }
        guard let age = withValuesForKeys["age"] as? Int else { return nil }
        
        self.name = name
        self.age = age
    }
}

let person = Person(name:"Bob", age:20)
let serialized = person.ss_serialize()

print(serialized)

