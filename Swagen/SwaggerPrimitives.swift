//
//  SwaggerPrimitives.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

enum ParameterPosition: String {
    case body
    case query
    case header
    case formData
    case path
}

enum ParameterType: String {
    case none
    case integer
    case string
    case boolean
    case object
    case array
    case number
    case file
}

enum ParameterFormat: String {
    case uuid
    case double
    case int32
    case int64
}

enum AuthorizationType {
    case none
    case basic
    case bearer
    case custom(value: String)
    
    var notNone: Bool {
        switch self {
        case .none: return false
        default: return true
        }
    }
}

class Operation: CustomStringConvertible {
    var description: String {
        return "\(method): \(path) - \(id)"
    }

    let id: String
    let path: String
    let method: String

    let descriptionText: String?
    let tags: [String]

    let parameters: [OperationParameter]
    let responses: [String: OperationResult]
    let hasAuthorization: Bool

    let consumes: [String]
    let produces: [String]

    init(path: String, method: String, info: [String: Any], processor: SwaggerProcessor) {
        self.path = path
        self.method = method
        self.id = info["operationId"] as! String
        self.descriptionText = info["description"] as? String
        self.tags = info["tags"] as! [String]
        self.parameters = (info["parameters"] as? [[String: Any]] ?? []).map { OperationParameter(info: $0, processor: processor) }

        self.consumes = info["consumes"] as? [String] ?? []
        self.produces = info["produces"] as? [String] ?? []

        self.hasAuthorization = info["security"] != nil

        var responses: [String: OperationResult] = [:]
        for (key, value) in (info["responses"] as! [String: [String: Any]]) {
            responses[key] = OperationResult(info: value, processor: processor)
        }
        self.responses = responses
    }
}

class OperationParameter: PropertyObject {
    let descriptionText: String?
    let `in`: ParameterPosition

    init(info: [String: Any], processor: SwaggerProcessor) {
        self.descriptionText = info["description"] as? String
        self.in = ParameterPosition(rawValue: info["in"] as! String)!
        
        let name = info["name"] as! String
        let required = info["required"] as! Bool
        
        if let info = info["schema"] as? [String: Any] {
           super.init(name: name, required: required, info: info, processor: processor)
        } else {
           super.init(name: name, required: required, info: info, processor: processor)
        }
    }
}


class OperationResult: CustomStringConvertible {
    var description: String {
        return primitive.schema ?? primitive.type.rawValue
    }

    let descriptionText: String
    let primitive: PrimitiveObject

    init(info: [String: Any], processor: SwaggerProcessor) {
        self.descriptionText = info["description"] as! String

        if let info = info["schema"] as? [String: Any] {
            self.primitive = PrimitiveObject(info: info, processor: processor)
        } else {
            self.primitive = PrimitiveObject(info: info, processor: processor)
        }
    }
}

class PrimitiveObject: CustomStringConvertible {
    var description: String {
        return type == .array ? "[\(items?.description ?? "")]" : schema ?? type.rawValue
    }

    let format: ParameterFormat?
    let type: ParameterType
    let items: PrimitiveObject?
    let schema: String?

    let processor: SwaggerProcessor

    init(info: [String: Any], processor: SwaggerProcessor) {
        self.processor = processor
        self.type = ParameterType(rawValue: info["type"] as? String ?? (info["$ref"] != nil ? "object" : "none"))!

        if let format = info["format"] as? String {
            self.format = ParameterFormat(rawValue: format)!
        } else {
            self.format = nil
        }

        if let items = info["items"] as? [String: Any] {
            self.items = PrimitiveObject(info: items, processor: processor)
        } else {
            self.items = nil
        }

        self.schema = info["$ref"] as? String
        processor.parseObject(at: self.schema)
    }
}

class PropertyObject: PrimitiveObject {
    let name: String
    let required: Bool
    let `enum`: [String]?
    let additionalProperties: PrimitiveObject?

    init(name: String, required: Bool, info: [String: Any], processor: SwaggerProcessor) {
        self.name = name
        self.required = required
        self.enum = info["enum"] as? [String]
        
        if let additionalProperties = info["additionalProperties"] as? [String: Any], additionalProperties.isEmpty == false {
            self.additionalProperties = PrimitiveObject(info: additionalProperties, processor: processor)
        } else {
            self.additionalProperties = nil
        }
        
        super.init(info: info, processor: processor)
    }
}

class ObjectScheme {
    let type: ParameterType
    let title: String
    let properties: [PropertyObject]

    static let placeholder = ObjectScheme(type: "", title: "", properties: [])

    fileprivate init(type: String, title: String, properties: [PropertyObject]) {
        self.type = .object
        self.title = title
        self.properties = properties
    }

    init(info: [String: Any], processor: SwaggerProcessor) {
        let requiredInfo = info["required"] as? [String] ?? []
        let propertiesInfo = info["properties"] as? [String: [String: Any]] ?? [:]
        var properties: [PropertyObject] = []
        for (key, value) in propertiesInfo {
            let required = requiredInfo.contains(key)
            properties.append(PropertyObject(name: key, required: required, info: value, processor: processor))
        }

        self.type = ParameterType(rawValue: info["type"] as! String)!
        self.title = info["title"] as! String
        self.properties = properties
    }
}
