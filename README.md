SwiftJsonSerializable
=====================

Purpose
-------
SwiftJsonSerializable is a small macro-based library that automatically generates Codable encode/decode implementations for structs and classes that use the `@JsonKey` property wrapper. It reduces boilerplate when working with JSON and provides:

- Support for multiple JSON key names for a single property (e.g. `id`, `ID`, `Id`).
- Optional ignoring of encode/decode errors via the `ignoringErrors` flag.
- Generated `init(from:)` and `encode(to:)` using `SimpleCodingKeys` (a simple CodingKey implementation).

Key features
------------
- `@JsonSerializable` (macro): generates `init(from:)` and `encode(to:)` for types that use `@JsonKey`.
- `@JsonKey`: a property wrapper that allows declaring custom JSON key names and error handling behavior.
- `SimpleCodingKeys`: a minimal `CodingKey` implementation using `stringValue` directly.

Compatibility
-------------
- The package declares `swift-tools-version: 6.2`. The macro plugin requires a Swift toolchain that supports compiler plugins/macros (for example: Xcode 15 / Swift 5.9+ or later toolchains).
- Platforms in `Package.swift`: macOS, iOS, tvOS, watchOS, macCatalyst (per package manifest).

Installation
------------
Add the package to your project's `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/SwiftJsonSerializable.git", from: "0.1.0"),
],

// then add the product to your target
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SwiftJsonSerializable", package: "SwiftJsonSerializable")
    ]
),
```

Or build/run locally in this repository with `swift build` / `swift run`.

Quickstart
----------
A minimal example (see `Sources/SwiftJsonSerializableClient/main.swift` in this repo):

```swift
import SwiftJsonSerializable
import Foundation

let jsonString = """
{
    "name": "John Doe",
    "age": 30,
    "isEmployed": true
}
"""

@JsonSerializable
struct Sample: Codable {
    @JsonKey var name: String = ""
    @JsonKey var age: Int = 0
    @JsonKey var isEmployed: Bool = false
}

let sample = try JSONDecoder().decode(Sample.self, from: jsonString.data(using: .utf8)!)
print("Name: \(sample.name), Age: \(sample.age), Employed: \(sample.isEmployed)")
```

Note about `@JsonKey`
---------------------
The `JsonKey` property wrapper supports a variadic initializer for alternate key names and an `ignoringErrors` option:

- Default (no custom keys):
  `@JsonKey var name: String = ""`
  -> The wrapper will attempt to decode/encode using the variable name as the JSON key.

- Provide one or more alternate keys:
  `@JsonKey("full_name") var name: String = ""`
  `@JsonKey("id", "ID", "Id") var identifier: Int = 0`
  -> The wrapper will try the provided keys in order. The first successful decode value wins.

- `ignoringErrors` (default: `true`):
  `@JsonKey(ignoringErrors: false) var value: Int = 0`
  -> When `ignoringErrors` is `true`, decoding/encoding errors for a particular key are collected and ignored until all key options are tried; if `false`, the first decode/encode error encountered will be thrown.

How the macro works (technical summary)
--------------------------------------
When `@JsonSerializable` is attached to a struct or class, the macro:
- Locates stored properties that use the `@JsonKey` wrapper and do not have an accessor block (no custom getter/setter).
- Generates a `init(from decoder: any Decoder) throws` that:
  - Obtains a `KeyedDecodingContainer<SimpleCodingKeys>` from the decoder.
  - Calls `_property.decode(from: container, variableName: "propertyName")` for each `@JsonKey` property.
- Generates a `func encode(to encoder: any Encoder) throws` that similarly calls `_property.encode(to:&container, variableName: "propertyName")`.

This means the `JsonKey` wrapper itself implements the actual decode/encode logic per property; the macro only aggregates those calls into the generated `init`/`encode`.

API reference (summary)
-----------------------
- macro `JsonSerializable`
  - Usage: attach to a `struct` or `class`.
  - Effect: generates `init(from:)` and `encode(to:)` for properties that use `@JsonKey`.

- property wrapper `JsonKey<T: Codable>`
  - Initializers:
    - `init(wrappedValue: T, keys: String..., ignoringErrors: Bool = true)`
    - `init(wrappedValue: T, keys: [String], ignoringErrors: Bool = true)`
  - Methods:
    - `mutating func decode(from container: KeyedDecodingContainer<SimpleCodingKeys>, variableName: String) throws`
    - `func encode(to container: inout KeyedEncodingContainer<SimpleCodingKeys>, variableName: String) throws`
  - Behavior:
    - Supports multiple JSON key names and configurable error handling.
    - Conforms to `Codable`. Also `Equatable` when `T: Equatable` and `Hashable` when `T: Hashable`.

- `struct SimpleCodingKeys: CodingKey`
  - A minimal `CodingKey` implementation that uses `stringValue`.

Advanced example
----------------
Handle multiple possible JSON keys returned by a server (e.g. `user_name` or `username`):

```swift
@JsonSerializable
struct User: Codable {
    @JsonKey(key: "user_name", "username") var name: String = "defaultName"
    @JsonKey var age: Int = 18
}
```

Explanation: during decoding `JsonKey` will try `user_name` first, then `username`. If neither exists and `ignoringErrors == true`, the wrapped value remains the default.

Run the example in this repository
---------------------------------
From the repository root you can build and run the example client target:

```bash
swift build
swift run SwiftJsonSerializableClient
```

If you encounter issues related to macros or compiler plugins, ensure you are using a Swift toolchain that supports compiler plugins/macros (Xcode 15 / Swift 5.9+ or a compatible toolchain).

Contributing
------------
- Open an issue to request features or report bugs.
- Send a pull request with a clear description and tests/examples where appropriate.

Development / Quick checks
--------------------------
- Build: `swift build`
- Run example client: `swift run SwiftJsonSerializableClient`

FAQ
---
Q: Why didn't the macro generate code for one of my properties?
A: The macro only finds stored properties that use `@JsonKey` and that do not contain an accessor block (custom getter/setter). Check your property declaration for compatibility.

Q: How do I use a different JSON key than the variable name?
A: Use `@JsonKey(key: "json_name") var myVar: Type = default`.

License
-------
This repository does not include a license file by default. Add a `LICENSE` (e.g. MIT/Apache/BSD) if you intend to publish the project publicly.

Contact
-------
Original author indicated in file headers: Zoro4rk. Issues, suggestions, and contributions are welcome on the project's GitHub.
