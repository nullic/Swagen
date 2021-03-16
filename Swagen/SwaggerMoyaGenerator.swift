//
//  SwaggerMoyaGenerator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

class SwaggerMoyaGenerator {
    let processor: SwaggerProcessor
    let outputFolder: URL
    let modelsFolder: URL
    let apisFolder: URL
    
    var accessModifier: String = "public"
    private var nonClassAccessModifier: String {
        if accessModifier == "open" {
           return "public"
        } else {
            return accessModifier
        }
    }
    
    var authorizationType: AuthorizationType = .none
    var decodeResponse: Bool = false
    var generateServer: Bool = false
    var initDefault: Bool = false
    var varStruct: Bool = false

    init(outputFolder: URL, processor: SwaggerProcessor) {
        self.outputFolder = outputFolder
        self.modelsFolder = outputFolder.appendingPathComponent("Models")
        self.apisFolder = outputFolder.appendingPathComponent("APIs")
        self.processor = processor
    }

    func run() {
        genAccessLevel = accessModifier
        genNonClassAccessLevel = nonClassAccessModifier
        generateModels()
        generateAPI()
    }

    private func generateModels() {
        do {
            try? FileManager.default.removeItem(at: modelsFolder)
            try FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true, attributes: nil)

            for (_, scheme) in processor.schemes {
                let fileURL = modelsFolder.appendingPathComponent("\(scheme.title.escaped).swift")
                let text = "\(genFilePrefix)\n\n\(scheme.swiftString(optinalInit: initDefault, useVar: varStruct))\n"
                try text.data(using: .utf8)?.write(to: fileURL)
            }
        } catch {
            print(error)
        }
    }

    private func generateAPI() {
        do {
            try? FileManager.default.removeItem(at: apisFolder)
            try FileManager.default.createDirectory(at: apisFolder, withIntermediateDirectories: true, attributes: nil)

            let utilsURL = outputFolder.appendingPathComponent("Utils.swift")
            try? FileManager.default.removeItem(at: utilsURL)

            if generateServer {
                let fileURL = outputFolder.appendingPathComponent("Server.swift")
                try? FileManager.default.removeItem(at: fileURL)
                try server14File.data(using: .utf8)?.write(to: fileURL)
            }

            var utilsStings = utilsFile
            if decodeResponse {
                utilsStings.append(contentsOf: targetTypeResponseCode)
            }

            try utilsStings.data(using: .utf8)?.write(to: utilsURL)
        
            for (tag, ops) in processor.operationsByTag {
                let name = tag.capitalized.replacingOccurrences(of: "-", with: "") + "API"
                let fileURL = apisFolder.appendingPathComponent("\(name).swift")

                let sorted = ops.sorted(by: { $0.id < $1.id })
                let defenition = apiDefenition(name: name, operations: sorted)

                let text = "\(genFilePrefix)\nimport Moya\n\n\(defenition)\n"
                try text.data(using: .utf8)?.write(to: fileURL)
            }
        } catch {
            print(error)
        }
    }

    private func apiDefenition(name: String, operations: [Operation]) -> String {
        var strings: [String] = []
        
//        let caseReturn = "\n\(indent)\(indent)\(indent)return"
        let caseReturn = " return"
        
        // Defenition
        strings.append("\(genNonClassAccessLevel) enum \(name) {")
        strings.append(operations.map({ "\($0.caseDocumetation)\n\(indent)case \($0.caseDeclaration)" }).joined(separator: "\n\n"))
        strings.append("}")
        strings.append("")
        
        // Paths
        strings.append("extension \(name): TargetType {")
        strings.append("\(indent)\(genNonClassAccessLevel) var baseURL: URL { return URL(string: \"\(processor.baseURL.absoluteString)\")! }")
        strings.append("")
        strings.append("\(indent)\(genNonClassAccessLevel) var path: String {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return \"\($0.path)\"" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        // RequestsneedParams
        strings.append("\(indent)\(genNonClassAccessLevel) var headers: [String: String]? {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseWithParams(position: [.header])):\(caseReturn) \($0.moyaTaskHeaders)" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genNonClassAccessLevel) var method: Moya.Method {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return .\($0.method.lowercased())" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genNonClassAccessLevel) var task: Moya.Task {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseWithParams(position: [.body, .query, .formData])):\(caseReturn) \($0.moyaTask)" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genNonClassAccessLevel) var sampleData: Data { return Data() }")
        strings.append("}")

        // Authorization
        if authorizationType.notNone {
            strings.append("")
            strings.append("// MARK: - Authorization")
            strings.append("")
            strings.append("extension \(name): AccessTokenAuthorizable {")
            strings.append("\(indent)\(genNonClassAccessLevel) var authorizationType: Moya.AuthorizationType? {")
            strings.append("\(indent)\(indent)switch self {")
            strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return \($0.moyaTaskAuth(type: authorizationType))" }))
            strings.append("\(indent)\(indent)}")
            strings.append("\(indent)}")
            strings.append("}")
        }

        // Responses
        if decodeResponse {
            strings.append("")
            strings.append("// MARK: - Response Parsing")
            strings.append("")
            strings.append("extension \(name): TargetTypeResponse {")
            strings.append("\(indent)\(genNonClassAccessLevel) func decodeResponse(_ response: Moya.Response) throws -> Any {")
            strings.append("\(indent)\(indent)switch self {")
            strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName):\n\($0.moyaResponseDecoder(responseName: "response", indentLevel: 3))" }))
            strings.append("\(indent)\(indent)}")
            strings.append("\(indent)}")
            strings.append("}")
        }

        // Responses
        if generateServer {
            strings.append("")
            strings.append("// MARK: - Sync Requests")
            strings.append("")
            strings.append("extension Server where Target == \(name) {")
            let ops: [String] = operations.map { op -> String in
                var subs: [String] = []
                subs.append("\(indent)\(genNonClassAccessLevel) func \(op.funcDeclaration) throws -> \(op.firstSuccessResponseType) {")
                subs.append("\(indent)\(indent)return try self.response(.\(op.caseUsage))")
                subs.append("\(indent)}")
                return subs.joined(separator: "\n")
            }
            strings.append(ops.joined(separator: "\n\n"))
            strings.append("}")
        }

        // Responses
        if generateServer {
            strings.append("")
            strings.append("// MARK: - Async Requests")
            strings.append("")
            strings.append("extension Server where Target == \(name) {")
            let ops: [String] = operations.map { op -> String in
                let declaration: String
                if op.parameters.isEmpty {
                    declaration = String(op.funcDeclaration.dropLast()) + "completion: @escaping (Result<\(op.firstSuccessResponseType), ServerError>) -> Void)"
                } else {
                    declaration = String(op.funcDeclaration.dropLast()) + ", completion: @escaping (Result<\(op.firstSuccessResponseType), ServerError>) -> Void)"
                }
                var subs: [String] = []
                subs.append("\(indent)@discardableResult")
                subs.append("\(indent)\(genNonClassAccessLevel) func \(declaration) -> Moya.Cancellable {")
                subs.append("\(indent)\(indent)return self.request(.\(op.caseUsage), completion: completion)")
                subs.append("\(indent)}")
                return subs.joined(separator: "\n")
            }
            strings.append(ops.joined(separator: "\n\n"))
            strings.append("}")
        }


        return strings.joined(separator: "\n")
    }
}
