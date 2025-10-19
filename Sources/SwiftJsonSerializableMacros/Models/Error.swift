//
//  Error.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//
import Foundation

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
