//
//  JsonKey.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import ZippyJSON


@propertyWrapper
public struct JsonKey<T: Codable>: Codable, @unchecked Sendable {
    
    public var wrappedValue    : T
    private let customKeys     : [String]
    private let ignoringErrors : Bool
    
    public init(
        wrappedValue: T,
        keys: String...,
        ignoringErrors: Bool = true)
    {
        self.wrappedValue = wrappedValue
        self.customKeys = keys
        self.ignoringErrors = ignoringErrors
    }
    
    public init(
        wrappedValue: T,
        key: String,
        ignoringErrors: Bool = true
    ) {
        self.wrappedValue = wrappedValue
        self.customKeys = [key]
        self.ignoringErrors = ignoringErrors
    }
    
    public init(
        wrappedValue: T,
        keys: [String],
        ignoringErrors: Bool = true
    ) {
        self.wrappedValue = wrappedValue
        self.customKeys = keys
        self.ignoringErrors = ignoringErrors
    }
    
    mutating public func decode(from container: KeyedDecodingContainer<SimpleCodingKeys>, variableName: String) throws {
        let stringKeys = customKeys.isEmpty ? [variableName] : customKeys
        // Keys are tried in declared order; the first that succeeds wins. We keep the
        // error from the first (canonical) key so a strict failure points at it.
        var firstError: Error?

        for stringKey in stringKeys {
            do {
                if let decoded = try container.decodeIfPresent(T.self, forKey: .init(stringValue: stringKey)) {
                    wrappedValue = decoded
                    return;
                }
            } catch {
                if firstError == nil { firstError = error }
            }
        }

        // No key produced a value (all absent/null, or only type errors occurred).
        // In strict mode this must fail — including when the key is simply missing.
        guard ignoringErrors else {
            throw firstError ?? DecodingError.keyNotFound(
                SimpleCodingKeys(stringValue: stringKeys[0]),
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "None of the keys \(stringKeys) were present while decoding '\(variableName)'."
                )
            )
        }
    }

    public func encode(to container: inout KeyedEncodingContainer<SimpleCodingKeys>, variableName: String) throws {
        // Encode under a single canonical key (the first one) — mirroring decode's
        // first-match priority — instead of duplicating the value under every key.
        let canonicalKey = customKeys.first ?? variableName
        do {
            try container.encode(wrappedValue, forKey: .init(stringValue: canonicalKey))
        } catch {
            if !ignoringErrors { throw error }
        }
    }
}


// Equality/hashing reflect the decoded value only. The key list and error policy are
// static decode/encode configuration, not data, so they must not affect value identity
// of an enclosing @JsonSerializable model.
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
