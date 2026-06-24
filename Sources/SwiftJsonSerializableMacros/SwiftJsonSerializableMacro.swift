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

        // Propagate the type's access level to the generated members, otherwise a
        // `public` model's Decodable/Encodable conformance and `initialize(...)`
        // helpers would be internal and unusable from another module.
        let typeModifiers = decl.as(StructDeclSyntax.self)?.modifiers ?? decl.as(ClassDeclSyntax.self)?.modifiers
        let isPublic = typeModifiers?.contains { ["public", "open"].contains($0.name.text) } ?? false
        let access = isPublic ? "public " : ""
        
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
        \(raw: access)\(raw: isClass ? "required " : "")init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: SimpleCodingKeys.self)
            \(raw: decodeExprs)
        }

        \(raw: access)func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: SimpleCodingKeys.self)
            \(raw: encodeExprs)
        }

        \(raw: access)static func initialize(jsonData: Data) throws -> Self {
            return try JsonDeserializer.decode(Self.self, from: jsonData)
        }

        \(raw: access)static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
            return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
        }
        """
        
        return [prop]
    }
}
