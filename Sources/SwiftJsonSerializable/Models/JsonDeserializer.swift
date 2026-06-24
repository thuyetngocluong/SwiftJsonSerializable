//
//  JsonDeserializer.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import Foundation
import ZippyJSON


/// JSON decoding entry points used by the `@JsonSerializable`-generated `initialize`
/// helpers.
///
/// Keeping the ZippyJSON dependency behind this type means consumer code only has to
/// `import SwiftJsonSerializable` (plus `Foundation` for `Data`) — it never needs to
/// `import ZippyJSON` for the generated `initialize(...)` methods to compile.
public enum JsonDeserializer {

    public enum Failure: Error, CustomStringConvertible {
        case invalidJsonString

        public var description: String {
            switch self {
            case .invalidJsonString:
                return "The provided string could not be converted to Data with the requested encoding."
            }
        }
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try ZippyJSONDecoder().decode(type, from: data)
    }

    public static func decode<T: Decodable>(
        _ type: T.Type,
        fromJsonString jsonString: String,
        encoding: String.Encoding = .utf8,
        allowLossyConversion: Bool = false
    ) throws -> T {
        guard let data = jsonString.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
            throw Failure.invalidJsonString
        }
        return try decode(type, from: data)
    }
}
