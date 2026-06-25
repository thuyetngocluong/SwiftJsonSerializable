import SwiftCompilerPlugin
import SwiftDiagnostics
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

        // Propagate the type's access level to the generated members, otherwise the
        // Decodable/Encodable witnesses and `initialize(...)` helpers would be less
        // accessible than the type and either fail the conformance (`public`/`package`
        // types) or be unusable from another module.
        //
        // `open` is mapped to `public`: @JsonSerializable does not support class
        // inheritance — the generated init(from:)/encode(to:) handle only the current
        // type's @JsonKey fields and do not chain to `super` — so emitting overridable
        // (`open`) members would invite silently-broken subclasses.
        let modifierNames = Set(decl.modifiers.map(\.name.text))
        let access: String
        if modifierNames.contains("public") || modifierNames.contains("open") {
            access = "public "
        } else if modifierNames.contains("package") {
            access = "package "
        } else {
            access = ""
        }

        // Surface silent data loss: a stored property without @JsonKey is neither decoded
        // nor encoded by the generated code, and would otherwise vanish with no signal.
        for member in memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            let isStored = variable.bindings.first?.accessorBlock == nil
            let isStatic = variable.modifiers.contains { ["static", "class"].contains($0.name.text) }
            let hasJsonKey = variable.attributes.has(attributesIn: ["JsonKey"])
            guard isStored, !isStatic, !hasJsonKey else { continue }
            let name = variable.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text ?? "property"
            context.diagnose(
                Diagnostic(
                    node: Syntax(variable),
                    message: JsonSerializableDiagnostic.missingJsonKey(property: name)
                )
            )
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
