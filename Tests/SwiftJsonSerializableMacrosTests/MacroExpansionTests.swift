import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import SwiftJsonSerializableMacros

private let macros: [String: Macro.Type] = [
    "JsonSerializable": JsonSerializableMacro.self
]

final class MacroExpansionTests: XCTestCase {

    func testPublicStructGeneratesPublicMembers() {
        assertMacroExpansion(
            """
            @JsonSerializable
            public struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
            }
            """,
            expandedSource: """
            public struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0

                public init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.decode(from: container, variableName: "a")
                }

                public func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.encode(to: &container, variableName: "a")
                }

                public static func initialize(jsonData: Data) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, from: jsonData)
                }

                public static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
                }
            }
            """,
            macros: macros
        )
    }

    func testInternalStructGeneratesInternalMembers() {
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
            }
            """,
            expandedSource: """
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.decode(from: container, variableName: "a")
                }

                func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.encode(to: &container, variableName: "a")
                }

                static func initialize(jsonData: Data) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, from: jsonData)
                }

                static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
                }
            }
            """,
            macros: macros
        )
    }

    func testPublicClassGeneratesRequiredInit() {
        assertMacroExpansion(
            """
            @JsonSerializable
            public class Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
            }
            """,
            expandedSource: """
            public class Model: Codable {
                @JsonKey(key: "a") var a: Int = 0

                public required init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.decode(from: container, variableName: "a")
                }

                public func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.encode(to: &container, variableName: "a")
                }

                public static func initialize(jsonData: Data) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, from: jsonData)
                }

                public static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
                }
            }
            """,
            macros: macros
        )
    }
}
