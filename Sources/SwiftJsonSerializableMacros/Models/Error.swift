//
//  Error.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//
import Foundation
import SwiftDiagnostics

/// Compile-time diagnostics emitted by `@JsonSerializable`.
enum JsonSerializableDiagnostic: DiagnosticMessage {
    case missingJsonKey(property: String)

    var message: String {
        switch self {
        case .missingJsonKey(let property):
            return "Property '\(property)' has no @JsonKey and will not be encoded or decoded by @JsonSerializable. Add @JsonKey, or make it a computed/static property to silence this warning."
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .missingJsonKey:
            return MessageID(domain: "SwiftJsonSerializable", id: "missingJsonKey")
        }
    }

    var severity: DiagnosticSeverity { .warning }
}

enum CustomError: Error, CustomStringConvertible {
    
    case onlyOnStructOrClass
    case onlyOnProtocol
    case onlyOnClass
    case onlyOnFunction
    
    var description: String {
        switch self {
        case .onlyOnStructOrClass:
            return "Only supports struct or class"
        case .onlyOnProtocol:
            return "Only supports protocols"
        case .onlyOnClass:
            return "Only supports classes"
        case .onlyOnFunction:
            return "Only supports functions"
        }
    }
}
