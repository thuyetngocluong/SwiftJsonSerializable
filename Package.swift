// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let swiftSyntaxVersion: Version

#if compiler(>=6.0)
swiftSyntaxVersion = "600.0.0"
#elseif compiler(>=5.10)
swiftSyntaxVersion = "510.0.0"
#else
swiftSyntaxVersion = "509.0.0"
#endif

let package = Package(
    name: "SwiftJsonSerializable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftJsonSerializable",
            targets: ["SwiftJsonSerializable"]
        ),
        .executable(
            name: "SwiftJsonSerializableClient",
            targets: ["SwiftJsonSerializableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: swiftSyntaxVersion),
        .package(url: "https://github.com/michaeleisel/zippyjson.git", from: "1.2.15"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "SwiftJsonSerializableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "SwiftJsonSerializable", dependencies: [
            "SwiftJsonSerializableMacros",
            .product(name: "ZippyJSON", package: "zippyjson")
        ]),
        // A client of the library, which is able to use the macro in its own code.
        .executableTarget(name: "SwiftJsonSerializableClient", dependencies: ["SwiftJsonSerializable"]),
    ]
)
