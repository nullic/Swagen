//
//  String+Generator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

let reserverWords = ["Type", "Self", "self", "Codable"]
let indent = "    "
var genAccessLevel = "public"


extension String {
    var escaped: String {
        return reserverWords.contains(self) ? "`\(self)`" : self
    }

    var capitalizedFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).uppercased() + self.dropFirst()
    }

    var loweredFirstLetter: String {
        guard self.isEmpty == false else { return self }
        return self.prefix(1).lowercased() + self.dropFirst()
    }
}

let genFilePrefix =
"""
// Generated file

import Foundation
"""


let utilsFile =
"""
\(genFilePrefix)
import Moya

extension Dictionary where Key == String, Value == Any? {
    func unopt() -> [String: Any] {
        return reduce(into: [String: Any]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = value
            }
        }
    }
}

\(genAccessLevel) enum ResponseDecodeError {
    case unknowCode
}

\(genAccessLevel) protocol TargetTypeResponse: TargetType {
    func decodeResponse(_ response: Moya.Response) throws -> Any
}


extension Optional {
    fileprivate func or(_ other: Optional) -> Optional {
        switch self {
        case .none: return other
        case .some: return self
        }
    }
}

\(genAccessLevel) enum AnyObjectValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: AnyObjectValue])
    case array([AnyObjectValue])

    \(genAccessLevel) init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: AnyObjectValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([AnyObjectValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.typeMismatch(AnyObjectValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Not a JSON object"))
        }
    }

    \(genAccessLevel) func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

"""
