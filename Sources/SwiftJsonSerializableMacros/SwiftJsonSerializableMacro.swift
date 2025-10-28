import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates Codable conformance for a struct or class.
public struct JsonSerializableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        let typeName = decl.as(StructDeclSyntax.self)?.name ?? decl.as(ClassDeclSyntax.self)?.name
        let memberBlock = decl.memberBlock
        let isClass = decl.as(ClassDeclSyntax.self) != nil
        
        guard let _ = typeName else {
            throw CustomError.onlyOnStructOrClass
        }
        
        let propertiesName = memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { v in
                return v.bindings.first?.accessorBlock == nil && v.attributes.has(attributesIn: ["JsonKey"])
            }
            .compactMap { v -> String? in
                guard let name = v.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                else {
                    return nil
                }
                
                return name
            }
        
        let decodeExprs = propertiesName.map {
            "try _\($0).decode(from: container, variableName: \"\($0)\")"
        }.joined(separator: "\t\n")
        
        let encodeExprs = propertiesName.map {
            "try _\($0).encode(to: &container, variableName: \"\($0)\")"
        }.joined(separator: "\t\n")
        
        let prop: DeclSyntax =
        """
        \(raw: isClass ? "required " : "")init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
            \(raw: decodeExprs)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: SimpleCodingKeys.self)
            \(raw: encodeExprs)
        }
        
        static func initialize(jsonData: Data) throws -> Self {
            return try JSONDecoder().decode(Self.self, from: jsonData)
        }
        
        static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
            guard let data = jsonString.data(using: encoding, allowLossyConversion: allowLossyConversion) else {
                throw NSError(domain: "JsonSerializableMacro", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON string"])
            }
            return try initialize(jsonData: data)
        }
        """
        
        return [prop]
    }
}
