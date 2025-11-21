import SwiftJsonSerializable
import Foundation
import ZippyJSON

let sampe = """
{
    "name": "John Doe",
    "year": 30,
    "isEmployed": true
}
"""

@JsonSerializable
struct Sample: Codable {
    @SwiftJsonSerializable.JsonKey(keys: "username", "name") var name: String = ""
    @JsonKey(key: "year") var age: Int    = 0
    @JsonKey var isEmployed : Bool   = false
}


let fromString = try! Sample.initialize(jsonString: sampe)

let fromData = try! Sample.initialize(jsonData: sampe.data(using: .utf8)!)

let sample = try! JSONDecoder().decode(Sample.self, from: sampe.data(using: .utf8)!)


print("Name: \(fromString.name), Age: \(fromString.age), Employed: \(fromString.isEmployed)")
print("Name: \(fromData.name), Age: \(fromData.age), Employed: \(fromData.isEmployed)")
