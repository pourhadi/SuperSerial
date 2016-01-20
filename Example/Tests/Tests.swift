import UIKit
import XCTest
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

extension Person: Equatable {}
func == (lhs:Person, rhs:Person) -> Bool {
    return lhs.name == rhs.name && lhs.age == rhs.age
}

class Tests: XCTestCase {
    
    let person = Person(name: "Bob", age: 20)
    let serializedString = "{\"ss_case\": \"type\", \"ss_value\": {\"ss_typeName\": \"Person\",\"ss_data\":{\"ss_case\": \"dict\", \"ss_value\": {\"age\": {\"ss_case\": \"int\", \"ss_value\": 20},\"name\": {\"ss_case\": \"string\", \"ss_value\": \"Bob\"}}}}}"
    
    override func setUp() {
        super.setUp()
        SuperSerial.serializableTypes = [Person.self]
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testStructSerializesToCustomType() {
        // This is an example of a functional test case.
        
        let serialized = person.ss_serialize()
        switch serialized {
        case .CustomType(let name, let data):
            XCTAssertNotNil(name)
            XCTAssertNotNil(data)
            break
        default:
            XCTFail()
        }
    }
    
    func testIfStructSerializedCorrectly() {
        let serialized = person.ss_serialize()
        let string = serialized.toString()
        
        XCTAssertEqual(string, self.serializedString)
    }
    
    func testIfStructDeserializesCorrectly() {
        let deserialize = Serialized(serializedString: self.serializedString)
        let val = deserialize?.deserialize()
        XCTAssertEqual(val as? Person, person)
    }
    
}
