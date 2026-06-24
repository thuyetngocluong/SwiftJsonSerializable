// A PUBLIC model living in its own module that only imports SwiftJsonSerializable.
// Used by the test target (a different module) to verify that:
//   * the generated Decodable/Encodable members and `initialize(...)` are `public`
//     (otherwise cross-module decode/encode/initialize would not compile), and
//   * the generated `initialize(...)` does not require the consumer to import ZippyJSON.
import Foundation
import SwiftJsonSerializable

@JsonSerializable
public struct CrossModuleDTO: Codable {
    @JsonKey(key: "id") public var id: Int = 0
    @JsonKey(keys: "full_name", "name") public var name: String = ""
    @JsonKey(key: "nickname", ignoringErrors: false) public var nickname: String? = nil
}
