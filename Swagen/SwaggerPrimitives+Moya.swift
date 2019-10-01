//
//  SwaggerPrimitives+Moya.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/29/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

extension AuthorizationType {
    var moyaString: String {
        switch self {
        case .none: return ".none"
        case .basic: return ".basic"
        case .bearer: return ".bearer"
        case .custom: return ".custom(\"\")"
        }
    }
}

extension Operation {
    var caseName: String {
        return id.loweredFirstLetter.escaped
    }

    var caseDocumetation: String {
        var strings: [String] = []
        strings.append("\(indent)/// \(descriptionText ?? "")")
        strings.append("\(indent)/// - respones:")
        strings.append(contentsOf: responses.map { "\(indent)/// \(indent)- \($0): \($1.primitive.typeSwiftString)" })
        return strings.joined(separator: "\n")
    }

    var swiftEnum: String? {
        let enums = parameters.compactMap({ $0.swiftEnum })
        return enums.isEmpty ? nil : enums.joined(separator: "\n")
    }
    
    var sortedParameters: [OperationParameter] {
        return parameters.sorted {
            if $0.in == $1.in { return $0.name < $1.name}
            else { return $0.in.rawValue == $1.in.rawValue }
        }
    }
    
    var caseDeclaration: String {
        return parameters.isEmpty ? caseName : "\(caseName)(\(sortedParameters.map({ $0.nameTypeSwiftString }).joined(separator: ", ")))"
    }
    
    var caseWithParams: String {
        return parameters.isEmpty ? caseName : "\(caseName)(\(sortedParameters.map({ "let \($0.name)" }).joined(separator: ", ")))"
    }
    
    var moyaTask: String {
        let body = parameters.filter { $0.in == .body }
        let query = parameters.filter { $0.in == .query }
        let urlParams = query.isEmpty ? "[:]" : "[\(query.map({ "\"\($0.name)\": \($0.name)" }).joined(separator: ", "))].unopt()"
        let bodyParams = body.isEmpty ? "[:]" : "[\(body.map({ "\"\($0.name)\": \($0.name)" }).joined(separator: ", "))].unopt()"
        
        if body.isEmpty && query.isEmpty {
            return ".requestPlain"
        } else if body.count == 1, query.isEmpty {
            return ".requestJSONEncodable(\(body[0].name))"
        } else {
            return ".requestCompositeParameters(bodyParameters: \(bodyParams), bodyEncoding: JSONEncoding(), urlParameters: \(urlParams))"
        }
    }

    var moyaTaskAuth: String {
        return (hasAuthorization ? AuthorizationType.custom : AuthorizationType.none).moyaString
    }

    var moyaResponseMap: String {
        let types = responses.reduce(into: [String: String]()) { (result, kv) in
            if kv.value.primitive.type != .none {
                result[kv.key] = kv.value.primitive.typeSwiftString
            }
        }

        let keys = types.keys.sorted()
        return types.isEmpty ? "[:]" : "[\(keys.map({ "\($0): \(types[$0]!).self" }).joined(separator: ", "))]"
    }
}
