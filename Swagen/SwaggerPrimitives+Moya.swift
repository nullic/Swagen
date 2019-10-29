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

extension PropertyObject {
    var moyaFormDataString: String {
        let dataString: String
        switch type {
        case .file:
            dataString = "\(nameSwiftString).moyaFormData(name: \"\(nameSwiftString)\")"
        default:
            dataString = "MultipartFormData(provider: .data(String(describing: \(nameSwiftString)).data(using: .utf8)!), name: \"\(nameSwiftString)\")"
        }

        return required ? dataString : "\(nameSwiftString) == nil ? nil : \(dataString)"
    }
}

extension Operation {
    var caseName: String {
        return id.loweredFirstLetter.escaped
    }

    var caseDocumetation: String {
        let keys = responses.keys.sorted()
        var strings: [String] = []
        strings.append("\(indent)/// \(descriptionText ?? "")")
        strings.append("\(indent)/// - respones:")
        strings.append(contentsOf: keys.map { "\(indent)/// \(indent)- \($0): \(responses[$0]!.primitive.typeSwiftString)" })
        return strings.joined(separator: "\n")
    }

    var swiftEnum: String? {
        let enums = parameters.compactMap({ $0.swiftEnum })
        return enums.isEmpty ? nil : enums.joined(separator: "\n")
    }
    
    var sortedParameters: [OperationParameter] {
        return parameters.sorted {
            if $0.in == $1.in { return $0.nameSwiftString < $1.nameSwiftString}
            else { return $0.in.rawValue == $1.in.rawValue }
        }
    }
    
    var caseDeclaration: String {
        return parameters.isEmpty ? caseName : "\(caseName)(\(sortedParameters.map({ $0.nameTypeSwiftString }).joined(separator: ", ")))"
    }
    
    func caseWithParams(position: [ParameterPosition]) -> String {
        let needParams = parameters.contains(where: { position.contains($0.in) })
        return needParams == false ? caseName : "\(caseName)(\(sortedParameters.map({ position.contains($0.in) ? "let \($0.nameSwiftString)" : "_" }).joined(separator: ", ")))"
    }
    
    var moyaTask: String {
        let body = parameters.filter { $0.in == .body }
        let query = parameters.filter { $0.in == .query }
        let form = parameters.filter { $0.in == .formData }

        let queryHasOpt = query.contains(where: { $0.required == false })
        let bodyHasOpt = body.contains(where: { $0.required == false })

        let urlParams = query.isEmpty ? "[:]" : "[\(query.map({ "\"\($0.nameSwiftString)\": \($0.nameSwiftString)" }).joined(separator: ", "))]\(queryHasOpt ? ".unopt()" : "")"
        let bodyParams = body.isEmpty ? "[:]" : "[\(body.map({ "\"\($0.name)\": \($0.name)" }).joined(separator: ", "))]\(bodyHasOpt ? ".unopt()" : "")"
        let formParams = form.isEmpty ? "[]" : "[\(form.map({ $0.moyaFormDataString }).joined(separator: ", "))].compactMap({ $0 })"

        if form.isEmpty == false {
            return ".uploadCompositeMultipart(\(formParams), urlParameters: \(urlParams))"
        } else if body.isEmpty && query.isEmpty {
            return ".requestPlain"
        } else if body.count == 1, query.isEmpty {
            return ".requestJSONEncodable(\(body[0].name))"
        } else {
            return ".requestCompositeParameters(bodyParameters: \(bodyParams), bodyEncoding: JSONEncoding(), urlParameters: \(urlParams))"
        }
    }

    var moyaTaskHeaders: String {
        let header = parameters.filter { $0.in == .header }
        var headerStrings = header.map({ "(\"\($0.name)\", \($0.nameSwiftString))" })
        if let type = consumes.first {
            headerStrings.append("(\"Content-Type\", \"\(type)\")")
        }
        return headerStrings.isEmpty ? "nil" : "Dictionary<String, Any?>(dictionaryLiteral: \(headerStrings.joined(separator: ", "))).unoptString()"
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
