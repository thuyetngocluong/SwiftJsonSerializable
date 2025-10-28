import SwiftJsonSerializable
import Foundation

let sampe = """
{
    "name": "John Doe",
    "year": 30,
    "isEmployed": true
}
"""

@JsonSerializable
struct Sample: Codable {
    @JsonKey(keys: "username", "name") var name: String = ""
    @JsonKey(key: "year") var age        : Int    = 0
    @JsonKey var isEmployed : Bool   = false
}


let sample = try! JSONDecoder().decode(Sample.self, from: sampe.data(using: .utf8)!)
print("Name: \(sample.name), Age: \(sample.age), Employed: \(sample.isEmployed)")
