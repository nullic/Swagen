//
//  SwaggerPrimitives+Swift.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

extension ParameterType {
    var swiftString: String {
        switch self {
        case .none: return "Void"
        case .integer: return "Int"
        case .string: return "String"
        case .boolean: return "Bool"
        case .object: return "AnyObject"
        case .array: return "[AnyObject]"
        case .number: return "Double"
        }
    }
}

extension ParameterFormat {
    var swiftString: String {
        switch self {
        case .uuid: return "UUID"
        case .double: return "Double"
        case .int32: return "Int32"
        case .int64: return "Int64"
        }
    }
}

extension PrimitiveObject {
    var typeSwiftString: String {
        switch type {
        case .none: return type.swiftString
        case .integer: return format?.swiftString ?? type.swiftString
        case .string: return type.swiftString
        case .boolean: return type.swiftString
        case .object: return processor.schemes[schema!]?.title ?? type.swiftString
        case .array: return "[\(items!.typeSwiftString)]"
        case .number: return format?.swiftString ?? type.swiftString
        }
    }
}

extension PropertyObject {
    var swiftEnum: String? {
        guard let values = self.enum else { return nil }

        var strings: [String] = []
        strings.append("\(indent)public enum \(name.capitalizedFirstLetter.escaped): String, Codable {")
        strings.append(contentsOf: values.sorted().map({ "\(indent)\(indent)case \($0.lowercased()) = \"\($0)\"" }))
        strings.append("\(indent)}\n")
        return strings.joined(separator: "\n")
    }

    var propertyTypeSwiftString: String {
        switch type {
        case .string: return self.enum != nil ? name.capitalizedFirstLetter.escaped : type.swiftString
        default: return super.typeSwiftString
        }
    }

    var nameTypeSwiftString: String {
        return "\(name): \(propertyTypeSwiftString)\(required ? "" : "?")"
    }

    var swiftString: String {
        return "\(indent)public let \(nameTypeSwiftString)"
    }
}

extension ObjectScheme {
    var swiftString: String {
        let sorted = properties.sorted {  $0.name < $1.name }

        var strings: [String] = []
        strings.append("public struct \(title.escaped): Codable {")
        strings.append(contentsOf: sorted.compactMap({ $0.swiftEnum }))
        strings.append(contentsOf: sorted.map({ $0.swiftString }))
        strings.append("")

        let params = sorted.map({ $0.nameTypeSwiftString }).joined(separator: ", ")
        strings.append("\(indent)public init(\(params)) {")
        strings.append(contentsOf: sorted.map({ "\(indent)\(indent)self.\($0.name) = \($0.name)" }))
        strings.append("\(indent)}")

        strings.append("}")

        return strings.joined(separator: "\n")
    }
}
