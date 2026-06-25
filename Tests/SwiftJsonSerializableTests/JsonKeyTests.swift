import XCTest
// NOTE: deliberately NO `import ZippyJSON` here — this proves a consumer that only
// imports SwiftJsonSerializable can still use @JsonSerializable / initialize(...).
import SwiftJsonSerializable
import SwiftJsonSerializableTestFixtures

// MARK: - Fixtures

@JsonSerializable
struct MultiKey: Codable {
    @JsonKey(keys: "first_name", "firstName") var name: String = ""
}

@JsonSerializable
struct Strict: Codable {
    @JsonKey(key: "id", ignoringErrors: false) var id: Int = -1
}

@JsonSerializable
struct OptionalModel: Codable {
    @JsonKey(key: "middle", ignoringErrors: false) var middle: String? = nil
}

@JsonSerializable
struct Lenient: Codable {
    @JsonKey var value: Int = 7
    @JsonKey(keys: "user_name", "name") var name: String = "?"
}

@JsonSerializable
public struct PublicDTO: Codable {
    @JsonKey(key: "id") public var id: Int = 0
}

// A @JsonKey used OUTSIDE a @JsonSerializable type — exercises the transparent Codable.
struct PlainContainer: Codable {
    @JsonKey(keys: "a", "b") var x: Int = 0
    var note: String = ""
}

// A value whose own encode(to:) always fails, to prove encode errors are not swallowed.
struct ThrowsOnEncode: Codable, Equatable {
    enum Boom: Error { case boom }
    init() {}
    init(from decoder: any Decoder) throws {}        // decodes from anything
    func encode(to encoder: any Encoder) throws { throw Boom.boom }
}

@JsonSerializable
struct HasThrowingField: Codable {
    @JsonKey var t: ThrowsOnEncode = ThrowsOnEncode()   // default ignoringErrors: true
}

// An observed (didSet) stored property must still be (de)coded.
@JsonSerializable
struct Observed: Codable {
    @JsonKey(key: "n") var n: Int = 0 {
        didSet { Observed.lastObserved = n }
    }
    static var lastObserved = -1
}

// A type with no codable stored properties must still encode to `{}` (not throw).
@JsonSerializable
struct EmptyModel: Codable {
    var computed: Int { 5 }
}

final class JsonKeyTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private func json(_ string: String) -> Data { Data(string.utf8) }
    private func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    // MARK: #1 single canonical / round-trip-stable encode

    func testEncodeWritesSingleKey() throws {
        let m = try decoder.decode(MultiKey.self, from: json(#"{"first_name":"Ann"}"#))
        let obj = try object(try encoder.encode(m))
        XCTAssertEqual(obj.count, 1)
        XCTAssertEqual(obj["first_name"] as? String, "Ann")
        XCTAssertNil(obj["firstName"])
    }

    func testDecodeFallsBackToSecondKey() throws {
        let m = try decoder.decode(MultiKey.self, from: json(#"{"firstName":"Bob"}"#))
        XCTAssertEqual(m.name, "Bob")
    }

    // #4 — a value decoded from a fallback key re-encodes under THAT key, not the first.
    func testRoundTripIsKeyStableForFallbackMatch() throws {
        let m = try decoder.decode(MultiKey.self, from: json(#"{"firstName":"Bob"}"#))
        let obj = try object(try encoder.encode(m))
        XCTAssertEqual(obj["firstName"] as? String, "Bob")
        XCTAssertNil(obj["first_name"], "must not migrate the value to the first key")
    }

    // MARK: #1/#2 strict mode no longer over-throws

    func testStrictMissingKeyDoesNotThrow() throws {
        // Regression guard: a missing key must NOT fail decoding; it keeps the default.
        let s = try decoder.decode(Strict.self, from: json(#"{"other":1}"#))
        XCTAssertEqual(s.id, -1)
    }

    func testStrictOptionalMissingDoesNotThrow() throws {
        let m = try decoder.decode(OptionalModel.self, from: json(#"{}"#))
        XCTAssertNil(m.middle)
    }

    func testStrictNullDoesNotThrow() throws {
        let m = try decoder.decode(OptionalModel.self, from: json(#"{"middle":null}"#))
        XCTAssertNil(m.middle)
        let s = try decoder.decode(Strict.self, from: json(#"{"id":null}"#))
        XCTAssertEqual(s.id, -1)
    }

    func testStrictTypeMismatchStillThrows() {
        // The remaining purpose of ignoringErrors:false: surface a present-but-invalid value.
        XCTAssertThrowsError(try decoder.decode(Strict.self, from: json(#"{"id":"NaN"}"#)))
    }

    func testStrictPresentValueDecodes() throws {
        let s = try decoder.decode(Strict.self, from: json(#"{"id":42}"#))
        XCTAssertEqual(s.id, 42)
    }

    // MARK: #3 one strict field does not abort sibling fields

    func testLenientSiblingsDecodeIndependently() throws {
        let l = try decoder.decode(Lenient.self, from: json(#"{"name":"X"}"#))
        XCTAssertEqual(l.value, 7)   // missing -> default, no throw
        XCTAssertEqual(l.name, "X")  // fallback key honored
    }

    // MARK: #5 nil optional is not encoded as null

    func testEncodeSkipsNilOptional() throws {
        let m = try decoder.decode(OptionalModel.self, from: json(#"{}"#))
        let obj = try object(try encoder.encode(m))
        XCTAssertNil(obj["middle"])
        XCTAssertTrue(obj.isEmpty)
    }

    func testEncodeWritesPresentOptional() throws {
        let m = try decoder.decode(OptionalModel.self, from: json(#"{"middle":"Q"}"#))
        let obj = try object(try encoder.encode(m))
        XCTAssertEqual(obj["middle"] as? String, "Q")
    }

    // MARK: #10 transparent Codable outside the macro

    func testWrapperIsTransparentInPlainCodable() throws {
        let c = try decoder.decode(PlainContainer.self, from: json(#"{"x":5,"note":"hi"}"#))
        XCTAssertEqual(c.x, 5)
        let obj = try object(try encoder.encode(c))
        // x is written as a bare value, NOT as {"wrappedValue":...}
        XCTAssertEqual(obj["x"] as? Int, 5)
        XCTAssertNil(obj["x"] as? [String: Any])
    }

    func testWrapperTransparentInArray() throws {
        let arr = try decoder.decode([JsonKey<Int>].self, from: json("[1,2,3]"))
        XCTAssertEqual(arr.map(\.wrappedValue), [1, 2, 3])
        let obj = try JSONSerialization.jsonObject(with: try encoder.encode(arr)) as? [Int]
        XCTAssertEqual(obj, [1, 2, 3])
    }

    // MARK: #14 value-only equality

    func testEqualityIgnoresConfig() {
        let a = JsonKey(wrappedValue: 5, keys: "id", "user_id")
        let b = JsonKey(wrappedValue: 5, key: "id")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.hashValue, b.hashValue)
        XCTAssertNotEqual(a, JsonKey(wrappedValue: 6, key: "id"))
    }

    // MARK: #6 ZippyJSON-backed initialize works without importing ZippyJSON

    func testInitializeFromString() throws {
        let l = try Lenient.initialize(jsonString: #"{"value":99,"user_name":"Z"}"#)
        XCTAssertEqual(l.value, 99)
        XCTAssertEqual(l.name, "Z")
    }

    func testInitializeFromData() throws {
        let s = try Strict.initialize(jsonData: json(#"{"id":7}"#))
        XCTAssertEqual(s.id, 7)
    }

    func testInitializeInvalidStringThrows() {
        // An undecodable-encoding string surfaces JsonDeserializer.Failure.
        XCTAssertThrowsError(
            try Lenient.initialize(jsonString: "\u{1F600}", encoding: .ascii)
        )
    }

    // MARK: #7 public type usable from another module (generated members are public)

    func testSameModulePublicTypeRoundTrips() throws {
        let dto = try decoder.decode(PublicDTO.self, from: json(#"{"id":11}"#))
        XCTAssertEqual(dto.id, 11)
        let obj = try object(try encoder.encode(dto))
        XCTAssertEqual(obj["id"] as? Int, 11)
    }

    // CrossModuleDTO lives in SwiftJsonSerializableTestFixtures; decoding/encoding it
    // here only compiles if the generated members are `public`.
    func testCrossModulePublicTypeRoundTrips() throws {
        let dto = try decoder.decode(CrossModuleDTO.self, from: json(#"{"name":"Jo","id":3}"#))
        XCTAssertEqual(dto.id, 3)
        XCTAssertEqual(dto.name, "Jo")        // matched via fallback key "name"
        XCTAssertNil(dto.nickname)
        let obj = try object(try encoder.encode(dto))
        XCTAssertEqual(obj["name"] as? String, "Jo")   // re-encoded under the matched key
        XCTAssertNil(obj["full_name"])
    }

    func testCrossModuleInitializeUsesZippyJSON() throws {
        let dto = try CrossModuleDTO.initialize(jsonString: #"{"full_name":"Max","id":9}"#)
        XCTAssertEqual(dto.id, 9)
        XCTAssertEqual(dto.name, "Max")       // matched via first key "full_name"
    }

    // package-level type usable cross-module (generated members are `package`).
    func testCrossModulePackageTypeRoundTrips() throws {
        let dto = try decoder.decode(PackageDTO.self, from: json(#"{"id":5}"#))
        XCTAssertEqual(dto.id, 5)
        let obj = try object(try encoder.encode(dto))
        XCTAssertEqual(obj["id"] as? Int, 5)
    }

    // MARK: encode errors are not swallowed (ignoringErrors governs decoding only)

    func testEncodeErrorIsPropagated() throws {
        let m = try decoder.decode(HasThrowingField.self, from: json(#"{"t":{}}"#))
        XCTAssertThrowsError(try encoder.encode(m)) { error in
            XCTAssertTrue(error is ThrowsOnEncode.Boom)
        }
    }

    // MARK: documented limitation — outside @JsonSerializable, an absent key throws

    func testPlainCodableAbsentKeyThrows() {
        // The enclosing synthesized Decodable calls container.decode(...) and throws before
        // the wrapper can apply its default — this asserts the documented behavior.
        XCTAssertThrowsError(try decoder.decode(PlainContainer.self, from: json(#"{"note":"hi"}"#)))
    }

    // MARK: observed (didSet/willSet) properties are still coded

    func testObservedPropertyIsCoded() throws {
        let o = try decoder.decode(Observed.self, from: json(#"{"n":42}"#))
        XCTAssertEqual(o.n, 42)
        let obj = try object(try encoder.encode(o))
        XCTAssertEqual(obj["n"] as? Int, 42)
    }

    // MARK: strict OPTIONAL field still throws on a present-but-malformed value

    func testStrictOptionalTypeMismatchThrows() {
        XCTAssertThrowsError(try decoder.decode(OptionalModel.self, from: json(#"{"middle":123}"#)))
    }

    // MARK: ZippyJSON (the production initialize path) matches Foundation on edge cases

    func testZippyJSONStrictNullDoesNotThrow() throws {
        let s = try Strict.initialize(jsonString: #"{"id":null}"#)
        XCTAssertEqual(s.id, -1)
    }

    func testZippyJSONStrictTypeMismatchThrows() {
        XCTAssertThrowsError(try Strict.initialize(jsonString: #"{"id":"NaN"}"#))
    }

    func testZippyJSONMultiKeyFallback() throws {
        let m = try MultiKey.initialize(jsonString: #"{"firstName":"Bob"}"#)
        XCTAssertEqual(m.name, "Bob")
    }

    // MARK: a type with no codable properties encodes to {} instead of throwing

    func testZeroPropertyTypeRoundTrips() throws {
        let m = try decoder.decode(EmptyModel.self, from: json("{}"))
        XCTAssertEqual(m.computed, 5)
        let data = try encoder.encode(m)
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "{}")
    }
}
