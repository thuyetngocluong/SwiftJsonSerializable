//
//  JsonKey.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import ZippyJSON


/// Internal marker so the wrapper can recognise (and special-case) `Optional`
/// values without statically knowing whether `T` is itself an `Optional`.
private protocol _OptionalProtocol {
    var isNil: Bool { get }
}

extension Optional: _OptionalProtocol {
    var isNil: Bool { self == nil }
}


@propertyWrapper
public struct JsonKey<T: Codable>: Codable {

    public var wrappedValue    : T
    private let customKeys     : [String]
    private let ignoringErrors : Bool
    /// The JSON key this value was actually decoded from. Re-encoding writes back the
    /// same key so a fallback-matched value is not silently migrated to a different key.
    private var decodedKey     : String?

    public init(
        wrappedValue: T,
        keys: String...,
        ignoringErrors: Bool = true)
    {
        self.init(wrappedValue: wrappedValue, keys: keys, ignoringErrors: ignoringErrors)
    }

    public init(
        wrappedValue: T,
        key: String,
        ignoringErrors: Bool = true
    ) {
        self.init(wrappedValue: wrappedValue, keys: [key], ignoringErrors: ignoringErrors)
    }

    public init(
        wrappedValue: T,
        keys: [String],
        ignoringErrors: Bool = true
    ) {
        self.wrappedValue = wrappedValue
        self.customKeys = keys
        self.ignoringErrors = ignoringErrors
        self.decodedKey = nil
    }

    // MARK: - Transparent Codable

    // When a @JsonKey property is used outside an @JsonSerializable type (e.g. inside a
    // plain Codable, an array, or a dictionary) the synthesized Codable would otherwise
    // serialize the wrapper's private storage. Encode/decode the wrapped value
    // transparently so the wrapper is invisible in that JSON.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.wrappedValue = try container.decode(T.self)
        self.customKeys = []
        self.ignoringErrors = true
        self.decodedKey = nil
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }

    // MARK: - Macro-driven keyed (de)coding

    mutating public func decode(from container: KeyedDecodingContainer<SimpleCodingKeys>, variableName: String) throws {
        let stringKeys = customKeys.isEmpty ? [variableName] : customKeys
        var firstError: Error?

        for stringKey in stringKeys {
            do {
                if let decoded = try container.decodeIfPresent(T.self, forKey: .init(stringValue: stringKey)) {
                    wrappedValue = decoded
                    decodedKey = stringKey
                    return
                }
            } catch {
                if firstError == nil { firstError = error }
            }
        }

        // Nothing was decoded. An absent or explicitly-null key always falls back to the
        // default value (in both modes). In strict mode we only surface a *genuine*
        // decode error — a value that WAS present but failed to decode (e.g. a type
        // mismatch). This keeps optional fields, missing keys, and null values working.
        if !ignoringErrors, let firstError {
            throw firstError
        }
    }

    public func encode(to container: inout KeyedEncodingContainer<SimpleCodingKeys>, variableName: String) throws {
        // Skip nil Optionals, matching Swift's `encodeIfPresent` convention and avoiding
        // a redundant `null` in the output.
        if let optional = wrappedValue as? _OptionalProtocol, optional.isNil {
            return
        }
        // Write a single key: the one the value was decoded from (key-stable round-trip),
        // otherwise the first declared key. Additional keys are decode-time fallbacks only.
        let targetKey = decodedKey ?? customKeys.first ?? variableName
        do {
            try container.encode(wrappedValue, forKey: .init(stringValue: targetKey))
        } catch {
            if !ignoringErrors { throw error }
        }
    }
}


// Equality/hashing reflect the decoded value only. The key list, error policy, and the
// incidental `decodedKey` are decode/encode configuration, not data, so they must not
// affect the value identity of an enclosing model.
extension JsonKey: Equatable where T: Equatable {
    public static func == (lhs: JsonKey<T>, rhs: JsonKey<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension JsonKey: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

// The wrapper is safe to share across concurrency domains only when its value is.
extension JsonKey: Sendable where T: Sendable {}
