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

        // Single pass over the members: collect the properties to (de)code and emit
        // diagnostics. Done together so the "is this a serializable stored property?"
        // rule cannot drift between the two (the source of earlier static/observer bugs).
        var propertiesName = [String]()
        for member in memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }
            // Only instance stored properties can be (de)coded. Skip static/class, lazy,
            // and computed properties entirely (observed didSet/willSet stays "stored").
            guard !variable.isStatic, !variable.isLazy, variable.isStoredProperty else { continue }

            if variable.hasJsonKey {
                // @JsonKey decode is mutating, so it cannot drive a `let`. Diagnose instead
                // of emitting code that fails to compile inside the expansion.
                if variable.isLet {
                    for name in variable.boundNames {
                        context.diagnose(Diagnostic(
                            node: Syntax(variable),
                            message: JsonSerializableDiagnostic.jsonKeyRequiresVar(property: name)
                        ))
                    }
                } else {
                    propertiesName.append(contentsOf: variable.boundNames)
                }
            } else if !variable.isLet {
                // A mutable stored property with no @JsonKey is silently dropped — warn.
                // `let` is left alone: it cannot take @JsonKey, so the warning isn't actionable.
                for name in variable.boundNames {
                    context.diagnose(Diagnostic(
                        node: Syntax(variable),
                        message: JsonSerializableDiagnostic.missingJsonKey(property: name)
                    ))
                }
            }
        }

        let decodeExprs = propertiesName.map {
            "try _\($0).decode(from: container, variableName: \"\($0)\")"
        }.joined(separator: "\n")

        let encodeExprs = propertiesName.map {
            "try _\($0).encode(to: &container, variableName: \"\($0)\")"
        }.joined(separator: "\n")

        // When there is nothing to (de)code, emit empty bodies: declaring an unused
        // `container` would warn inside the expansion with no way for the user to silence it.
        let prop: DeclSyntax = propertiesName.isEmpty
        ?
        """
        \(raw: access)\(raw: isClass ? "required " : "")init(from decoder: any Decoder) throws {
        }

        \(raw: access)func encode(to encoder: any Encoder) throws {
        }

        \(raw: access)static func initialize(jsonData: Data) throws -> Self {
            return try JsonDeserializer.decode(Self.self, from: jsonData)
        }

        \(raw: access)static func initialize(jsonString: String, encoding: String.Encoding = .utf8, allowLossyConversion: Bool = false) throws -> Self {
            return try JsonDeserializer.decode(Self.self, fromJsonString: jsonString, encoding: encoding, allowLossyConversion: allowLossyConversion)
        }
        """
        :
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
