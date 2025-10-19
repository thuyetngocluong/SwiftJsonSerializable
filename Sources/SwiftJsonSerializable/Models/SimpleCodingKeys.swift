//
//  SimpleCodingKeys.swift
//  SwiftJsonSerializable
//
//  Created by Zoro4rk on 19/10/25.
//

import Foundation


public struct SimpleCodingKeys: CodingKey {
    public var intValue: Int?
    public var stringValue: String
    
    public init(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
    
    public init(stringValue: String) {
        self.stringValue = stringValue
    }
}
