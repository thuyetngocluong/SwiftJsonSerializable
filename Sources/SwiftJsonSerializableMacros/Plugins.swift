//
//  Plugins.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct Plugins: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JsonSerializableMacro.self,
    ]
}
