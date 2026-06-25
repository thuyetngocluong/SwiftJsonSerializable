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
    case jsonKeyRequiresVar(property: String)

    var message: String {
        switch self {
        case .missingJsonKey(let property):
            return "Property '\(property)' has no @JsonKey and will not be encoded or decoded by @JsonSerializable."
        case .jsonKeyRequiresVar(let property):
            return "@JsonKey on 'let \(property)' has no effect — it is not encoded or decoded. Change it to 'var' to serialize it."
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .missingJsonKey:
            return MessageID(domain: "SwiftJsonSerializable", id: "missingJsonKey")
        case .jsonKeyRequiresVar:
            return MessageID(domain: "SwiftJsonSerializable", id: "jsonKeyRequiresVar")
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
