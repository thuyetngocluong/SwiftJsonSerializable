import XCTest
import SwiftDiagnostics
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

    func testOpenClassMapsToPublicMembers() {
        // @JsonSerializable does not support inheritance, so `open` is intentionally
        // narrowed to `public` rather than emitting overridable members.
        assertMacroExpansion(
            """
            @JsonSerializable
            open class Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
            }
            """,
            expandedSource: """
            open class Model: Codable {
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

    func testPackageStructGeneratesPackageMembers() {
        assertMacroExpansion(
            """
            @JsonSerializable
            package struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
            }
            """,
            expandedSource: """
            package struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0

                package init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.decode(from: container, variableName: "a")
                }

                package func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: SimpleCodingKeys.self)
                    try _a.encode(to: &container, variableName: "a")
                }

                package static func initialize(jsonData: Data) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, from: jsonData)
                }

                package static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
                    return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
                }
            }
            """,
            macros: macros
        )
    }

    func testStaticJsonKeyIsExcludedFromCoding() {
        // A `static @JsonKey` must not be referenced on the instance (would not compile).
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                @JsonKey(key: "b") var b: Int = 0
                @JsonKey static var a: Int = 0
            }
            """,
            expandedSource: """
            struct Model: Codable {
                @JsonKey(key: "b") var b: Int = 0
                @JsonKey static var a: Int = 0

                init(from decoder: any Decoder) throws {
                    let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
                    try _b.decode(from: container, variableName: "b")
                }

                func encode(to encoder: any Encoder) throws {
                    var container = encoder.container(keyedBy: SimpleCodingKeys.self)
                    try _b.encode(to: &container, variableName: "b")
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

    func testJsonKeyOnLetEmitsWarningAndIsExcluded() {
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                @JsonKey let c: Int = 0
            }
            """,
            expandedSource: """
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                @JsonKey let c: Int = 0

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
            diagnostics: [
                DiagnosticSpec(
                    message: "@JsonKey on 'let c' has no effect — it is not encoded or decoded. Change it to 'var' to serialize it.",
                    line: 4,
                    column: 5,
                    severity: .warning
                )
            ],
            macros: macros
        )
    }

    func testMultiBindingWithoutJsonKeyWarnsEachName() {
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                var p = 1, q = 2
            }
            """,
            expandedSource: """
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                var p = 1, q = 2

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
            diagnostics: [
                DiagnosticSpec(message: "Property 'p' has no @JsonKey and will not be encoded or decoded by @JsonSerializable.", line: 4, column: 5, severity: .warning),
                DiagnosticSpec(message: "Property 'q' has no @JsonKey and will not be encoded or decoded by @JsonSerializable.", line: 4, column: 5, severity: .warning)
            ],
            macros: macros
        )
    }

    func testTypeWithNoCodablePropertiesGeneratesEmptyBodies() {
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                var computed: Int { 5 }
            }
            """,
            expandedSource: """
            struct Model: Codable {
                var computed: Int { 5 }

                init(from decoder: any Decoder) throws {
                }

                func encode(to encoder: any Encoder) throws {
                    _ = encoder.container(keyedBy: SimpleCodingKeys.self)
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

    func testMissingJsonKeyEmitsWarning() {
        assertMacroExpansion(
            """
            @JsonSerializable
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                var plain: String = ""
            }
            """,
            expandedSource: """
            struct Model: Codable {
                @JsonKey(key: "a") var a: Int = 0
                var plain: String = ""

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
            diagnostics: [
                DiagnosticSpec(
                    message: "Property 'plain' has no @JsonKey and will not be encoded or decoded by @JsonSerializable.",
                    line: 4,
                    column: 5,
                    severity: .warning
                )
            ],
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
