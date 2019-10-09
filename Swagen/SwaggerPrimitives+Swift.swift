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
        case .object: return "AnyObjectValue"
        case .array: return "[AnyObjectValue]"
        case .number: return "Double"
        case .file: return "URL"
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
        case .object: return (schema != nil ? processor.schemes[schema!]?.title : nil) ?? type.swiftString
        case .array: return "[\(items!.typeSwiftString)]"
        case .number: return format?.swiftString ?? type.swiftString
        case .file: return type.swiftString
        }
    }
}

extension PropertyObject {
    var swiftEnum: String? {
        guard let values = self.enum else { return nil }

        var strings: [String] = []
        strings.append("\(indent)\(genAccessLevel) enum \(nameSwiftString.capitalizedFirstLetter.escaped): String, CaseIterable, Codable {")
        strings.append(contentsOf: values.sorted().map({ "\(indent)\(indent)case \($0.lowercased()) = \"\($0)\"" }))
        strings.append("\(indent)}\n")
        return strings.joined(separator: "\n")
    }

    var propertyTypeSwiftString: String {
        switch type {
        case .string: return self.enum != nil ? nameSwiftString.capitalizedFirstLetter.escaped : type.swiftString
        default: return super.typeSwiftString
        }
    }

    var nameSwiftString: String {
        return name.loweredFirstLetter.escaped
    }

    var nameTypeSwiftString: String {
        return "\(nameSwiftString): \(propertyTypeSwiftString)\(required ? "" : "?")"
    }

    var swiftString: String {
        return "\(indent)\(genAccessLevel) let \(nameTypeSwiftString)"
    }
}

extension ObjectScheme {
    var swiftString: String {
        let sorted = properties.sorted {  $0.name < $1.name }

        var strings: [String] = []
        strings.append("\(genAccessLevel) struct \(title.escaped): Codable {")
        strings.append(contentsOf: sorted.compactMap({ $0.swiftEnum }))
        strings.append(contentsOf: sorted.map({ $0.swiftString }))
        strings.append("")

        let params = sorted.map({ $0.nameTypeSwiftString }).joined(separator: ", ")
        strings.append("\(indent)\(genAccessLevel) init(\(params)) {")
        strings.append(contentsOf: sorted.map({ "\(indent)\(indent)self.\($0.nameSwiftString) = \($0.nameSwiftString)" }))
        strings.append("\(indent)}")

        strings.append("}")

        return strings.joined(separator: "\n")
    }
}
