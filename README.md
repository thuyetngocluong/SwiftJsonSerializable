# SwiftJsonSerializable

A Swift macro library that simplifies JSON serialization by automatically generating `Codable` implementations with flexible key mapping and error handling.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Overview

SwiftJsonSerializable is a lightweight macro-based library that eliminates boilerplate code when working with JSON in Swift. Using the `@JsonSerializable` macro and `@JsonKey` property wrapper, you can:

- 🔑 Map multiple JSON key names to a single property (e.g., `"id"`, `"ID"`, `"Id"`)
- 🛡️ Handle decoding/encoding errors gracefully with configurable error handling
- ⚡ Reduce boilerplate with automatic `Codable` conformance generation
- 🎯 Work with both structs and classes seamlessly

## Features

- **`@JsonSerializable` macro**: Automatically generates `init(from:)` and `encode(to:)` implementations
- **`@JsonKey` property wrapper**: Flexible JSON key mapping with multiple fallback options
- **Error handling**: Choose between strict or lenient error handling per property
- **ZippyJSON support**: Optional high-performance JSON parsing with ZippyJSON
- **Type-safe**: Full compile-time type checking with Swift macros

## Requirements

- Swift 5.9+
- Xcode 15.0+
- Platforms: iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+

## Installation

### Swift Package Manager

Add SwiftJsonSerializable to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/thuyetngocluong/SwiftJsonSerializable.git", from: "1.0.2")
]
```

Then add it to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "SwiftJsonSerializable", package: "SwiftJsonSerializable")
    ]
)
```

### Xcode

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL: `https://github.com/thuyetngocluong/SwiftJsonSerializable.git`
3. Select the version you want to use
4. Add the package to your target

## Quick Start

Here's a simple example to get you started:

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
struct Person: Codable {
    @JsonKey var name: String = ""
    @JsonKey var age: Int = 0
    @JsonKey var isEmployed: Bool = false
}

let person = try JSONDecoder().decode(Person.self, from: jsonString.data(using: .utf8)!)
print("Name: \(person.name), Age: \(person.age), Employed: \(person.isEmployed)")
// Output: Name: John Doe, Age: 30, Employed: true
```

## Usage

### Basic Property Mapping

Use `@JsonKey` without parameters to map using the property name:

```swift
@JsonSerializable
struct User: Codable {
    @JsonKey var username: String = ""
    @JsonKey var email: String = ""
}
```

### Multiple Key Names

Handle APIs that might return different key names:

```swift
@JsonSerializable
struct User: Codable {
    @JsonKey(keys: "user_name", "username", "name") var name: String = ""
    @JsonKey(keys: "user_id", "id", "ID") var identifier: Int = 0
}
```

The decoder tries each key in order and uses the first one that succeeds.

### Custom Single Key

Map a property to a specific JSON key:

```swift
@JsonSerializable
struct Product: Codable {
    @JsonKey(key: "product_name") var name: String = ""
    @JsonKey(key: "unit_price") var price: Double = 0.0
}
```

### Error Handling

By default, `ignoringErrors` is `true`, meaning decoding continues even if a property fails:

```swift
@JsonSerializable
struct Settings: Codable {
    @JsonKey var theme: String = "light"
    @JsonKey(ignoringErrors: false) var apiKey: String = ""  // Strict: will throw if missing
}
```

### Using Convenience Initializers

SwiftJsonSerializable provides helper methods for JSON deserialization:

```swift
// From JSON string
let user = try User.initialize(jsonString: jsonString)

// From JSON data
let userData = jsonString.data(using: .utf8)!
let user = try User.initialize(jsonData: userData)
```

## Advanced Examples

### Nested Objects

```swift
@JsonSerializable
struct Address: Codable {
    @JsonKey var street: String = ""
    @JsonKey var city: String = ""
    @JsonKey var zipCode: String = ""
}

@JsonSerializable
struct User: Codable {
    @JsonKey var name: String = ""
    @JsonKey var address: Address = Address()
}
```

### Arrays and Optionals

```swift
@JsonSerializable
struct Team: Codable {
    @JsonKey var name: String = ""
    @JsonKey var members: [String] = []
    @JsonKey var manager: String? = nil
}
```

### Working with Classes

The macro works with classes too:

```swift
@JsonSerializable
class Vehicle: Codable {
    @JsonKey var make: String = ""
    @JsonKey var model: String = ""
    @JsonKey(key: "year") var yearManufactured: Int = 0
}
```

## How It Works

The `@JsonSerializable` macro analyzes your type at compile time and generates:

1. A `init(from decoder: any Decoder) throws` initializer
2. A `encode(to encoder: any Encoder) throws` method

For each `@JsonKey` property, the macro:
- Creates a `KeyedDecodingContainer<SimpleCodingKeys>`
- Calls the property wrapper's `decode(from:variableName:)` method
- The `JsonKey` wrapper handles key fallback logic and error handling

This approach keeps your code clean while providing powerful customization options.

## API Reference

### `@JsonSerializable`

A macro that generates `Codable` conformance for structs and classes.

**Usage:**
```swift
@JsonSerializable
struct MyType: Codable {
    // properties with @JsonKey
}
```

### `@JsonKey<T: Codable>`

A property wrapper for JSON key mapping and error handling.

**Initializers:**
- `init(wrappedValue: T, keys: String..., ignoringErrors: Bool = true)`
- `init(wrappedValue: T, key: String, ignoringErrors: Bool = true)`
- `init(wrappedValue: T, keys: [String], ignoringErrors: Bool = true)`

**Parameters:**
- `wrappedValue`: The default value for the property
- `keys`/`key`: JSON key name(s) to try during decoding
- `ignoringErrors`: Whether to ignore decoding errors (default: `true`)

**Conformances:**
- `Codable`
- `Equatable` (when `T: Equatable`)
- `Hashable` (when `T: Hashable`)

### `SimpleCodingKeys`

A minimal `CodingKey` implementation used internally by the generated code.

## Examples in Repository

The repository includes a working example in `Sources/SwiftJsonSerializableClient/main.swift`.

To run it:

```bash
swift build
swift run SwiftJsonSerializableClient
```

## FAQ

**Q: Why isn't code generated for one of my properties?**

A: The macro only processes stored properties with `@JsonKey` that don't have custom getters/setters. Computed properties and properties with accessor blocks are not supported.

**Q: Can I use this with Codable types that already have custom implementations?**

A: The macro generates `init(from:)` and `encode(to:)`, which may conflict with existing implementations. Use it on types where you want automatic generation.

**Q: Does this work with nested types?**

A: Yes! Nested types work as long as they conform to `Codable`.

**Q: What about performance?**

A: The library uses ZippyJSON for improved parsing performance. The macro-generated code is efficient and produces minimal overhead compared to hand-written implementations.

**Q: Can I mix `@JsonKey` with regular properties?**

A: Yes, but only `@JsonKey` properties will be handled by the generated code. Regular properties won't be automatically encoded/decoded.

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report bugs**: Open an issue with details about the problem
2. **Suggest features**: Share your ideas for improvements
3. **Submit PRs**: Fork the repository and submit a pull request

Please ensure your code follows existing patterns and includes appropriate tests.

## Development

To work on SwiftJsonSerializable:

```bash
# Clone the repository
git clone https://github.com/thuyetngocluong/SwiftJsonSerializable.git
cd SwiftJsonSerializable

# Build the package
swift build

# Run tests (if available)
swift test

# Run the example
swift run SwiftJsonSerializableClient
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

Created by [Zoro4rk](https://github.com/thuyetngocluong)

## Support

If you find this library helpful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting issues
- 📖 Improving documentation
- 🔧 Contributing code

For questions and support, please open an issue on GitHub.
