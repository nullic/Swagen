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
        var result = self.filter { $0.isLetter || $0.isNumber }
        result = reserverWords.contains(result) ? "`\(result)`" : result
        return result
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

extension Dictionary where Value == Any? {
    func unopt() -> [Key: Any] {
        return reduce(into: [Key: Any]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = value
            }
        }
    }

    func unoptString() -> [Key: String] {
        return reduce(into: [Key: String]()) { (result, kv) in
            if let value = kv.value {
                result[kv.key] = String(describing: value)
            }
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

\(genAccessLevel) enum FileValue {
    case data(value: Foundation.Data, fileName: String, mimeType: String)
    case url(value: Foundation.URL)

    func moyaFormData(name: String) -> MultipartFormData {
        switch self {
        case .data(let value, let fileName, let mimeType):
            return MultipartFormData(provider: .data(value), name: name, fileName: fileName, mimeType: mimeType)
        case .url(let value):
            return MultipartFormData(provider: .file(value), name: name)
        }
    }
}

"""


let targetTypeResponseCode =
"""
\(genAccessLevel) enum ResponseDecodeError {
    case unknowCode
}

\(genAccessLevel) protocol TargetTypeResponse: TargetType {
    func decodeResponse(_ response: Moya.Response) throws -> Any
}

"""
