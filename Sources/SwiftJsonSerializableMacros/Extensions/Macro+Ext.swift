//
//  Macro+Ext.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import SwiftSyntax
import Foundation

extension AttributeListSyntax  {
    func has(attributesIn collection: Set<String>) -> Bool {
        return first(attributesIn: collection) != nil
    }
    
    func first(attributesIn collection: Set<String>) -> AttributeSyntax? {
        for attribute in self {
            let syntax = attribute.as(AttributeSyntax.self)
            if let attributeName = syntax?.attributeName.trimmedWhitespacesAndNewlinesDescription.replacingOccurrences(of: "SwiftJsonSerializable.", with: ""),
               collection.contains(attributeName) {
                return syntax
            }
        }
        return nil
    }
}

extension AttributeSyntax.Arguments {
    func value(forKey key: String) -> String? {
        let args = self.as(LabeledExprListSyntax.self) ?? []
        for arg in args {
            if let label = arg.label?.text, label == key {
                return arg.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return nil
    }
    
    func valueDictionary(forKey key: String) -> [String: String] {
        var result: [String: String] = [:]
        let args = self.as(LabeledExprListSyntax.self) ?? []
        for arg in args {
            guard arg.label?.text == key, let dictExpr = arg.expression.as(DictionaryExprSyntax.self) else {
                continue
            }
            
            let elements = dictExpr.content.as(DictionaryElementListSyntax.self)?.lazy.elements ?? []
            for element in elements {
                let key = element.key.description.trimmingCharacters(in: .init(charactersIn: "\""))
                let value = element.value.description
                result[key] = value
            }
        }
        
        return result
    }
}

extension SyntaxProtocol {
    var trimmedWhitespacesAndNewlinesDescription: String {
        trimmedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension VariableDeclSyntax {
    /// A property is *stored* when it has no accessor block, or only observers
    /// (`didSet`/`willSet`). A getter / `get`+`set` block makes it computed.
    var isStoredProperty: Bool {
        guard let accessorBlock = bindings.first?.accessorBlock else { return true }
        switch accessorBlock.accessors {
        case .accessors(let accessors):
            return accessors.allSatisfy { ["didSet", "willSet"].contains($0.accessorSpecifier.text) }
        case .getter:
            return false
        }
    }

    var isStatic: Bool {
        modifiers.contains { ["static", "class"].contains($0.name.text) }
    }

    var isLazy: Bool {
        modifiers.contains { $0.name.text == "lazy" }
    }

    var isLet: Bool {
        bindingSpecifier.text == "let"
    }

    /// Every identifier bound by this declaration (handles `var a, b: Int` and the
    /// tuple binding `var (a, b) = ...`).
    var boundNames: [String] {
        bindings.flatMap { binding -> [String] in
            if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
                return [identifier.identifier.text]
            }
            if let tuple = binding.pattern.as(TuplePatternSyntax.self) {
                return tuple.elements.compactMap { $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text }
            }
            return []
        }
    }

    var hasJsonKey: Bool {
        attributes.has(attributesIn: ["JsonKey"])
    }
}

extension String {
    func isValidURLRegex() -> Bool {
        let pattern = #"^(https?|ftp)://[^\s/$.?#].[^\s]*$"#
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}
