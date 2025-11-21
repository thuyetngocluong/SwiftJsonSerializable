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
        var errors = [Error]()
        
        for stringKey in stringKeys {
            do {
                if let decoded = try container.decodeIfPresent(T.self, forKey: .init(stringValue: stringKey)) {
                    wrappedValue = decoded
                    return;
                }
            } catch {
                errors.append(error)
            }
        }
        
        if !ignoringErrors, let error = errors.first {
            throw error
        }
    }
    
    public func encode(to container: inout KeyedEncodingContainer<SimpleCodingKeys>, variableName: String) throws {
        let stringKeys = customKeys.isEmpty ? [variableName] : customKeys
        var errors = [Error]()
        for stringKey in stringKeys {
            do {
                try container.encode(wrappedValue, forKey: .init(stringValue: stringKey))
            } catch {
                errors.append(error)
            }
        }
        if !ignoringErrors, let error = errors.first {
            throw error
        }
    }
}


extension JsonKey: Equatable where T: Equatable {
    public static func == (lhs: JsonKey<T>, rhs: JsonKey<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue && lhs.customKeys == rhs.customKeys && lhs.ignoringErrors == rhs.ignoringErrors
    }
}

extension JsonKey: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
        hasher.combine(customKeys)
        hasher.combine(ignoringErrors)
    }
}
    
