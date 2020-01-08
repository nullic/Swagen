//
//  SwaggerMoyaGenerator.swift
//  Swagen
//
//  Created by Dmitriy Petrusevich on 9/27/19.
//  Copyright © 2019 Dmitriy Petrusevich. All rights reserved.
//

import Foundation

class SwaggerMoyaGenerator {
    struct Options: OptionSet {
        let rawValue: Int

        static let internalLevel = Options(rawValue: 1 << 0)
        static let responseTypes = Options(rawValue: 1 << 1)
        static let customAuthorization = Options(rawValue: 1 << 2)
        static let moyaProvider = Options(rawValue: 1 << 3)
    }

    let processor: SwaggerProcessor
    let options: Options
    let outputFolder: URL
    let modelsFolder: URL
    let apisFolder: URL

    init(outputFolder: URL, processor: SwaggerProcessor, options: Options) {
        genAccessLevel = options.contains(.internalLevel) ? "internal" : "public"
        genServerAccessLevel = options.contains(.internalLevel) ? "internal" : "open"

        self.options = options
        self.outputFolder = outputFolder
        self.modelsFolder = outputFolder.appendingPathComponent("Models")
        self.apisFolder = outputFolder.appendingPathComponent("APIs")
        self.processor = processor
    }

    func run() {
        generateModels()
        generateAPI()
    }

    private func generateModels() {
        do {
            try? FileManager.default.removeItem(at: modelsFolder)
            try FileManager.default.createDirectory(at: modelsFolder, withIntermediateDirectories: true, attributes: nil)

            for (_, scheme) in processor.schemes {
                let fileURL = modelsFolder.appendingPathComponent("\(scheme.title.escaped).swift")
                let text = "\(genFilePrefix)\n\n\(scheme.swiftString)\n"
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

            if options.contains(.moyaProvider) {
                let fileURL = outputFolder.appendingPathComponent("Server.swift")
                try? FileManager.default.removeItem(at: fileURL)
                try serverFile.data(using: .utf8)?.write(to: fileURL)
            }

            var utilsStings = utilsFile
            if options.contains(.responseTypes) {
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
        strings.append("\(genAccessLevel) enum \(name) {")
        strings.append(operations.map({ "\($0.caseDocumetation)\n\(indent)case \($0.caseDeclaration)" }).joined(separator: "\n\n"))
        strings.append("}")
        strings.append("")
        
        // Paths
        strings.append("extension \(name): TargetType {")
        strings.append("\(indent)\(genAccessLevel) var baseURL: URL { return URL(string: \"\(processor.baseURL.absoluteString)\")! }")
        strings.append("")
        strings.append("\(indent)\(genAccessLevel) var path: String {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return \"\($0.path)\"" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        // RequestsneedParams
        strings.append("\(indent)\(genAccessLevel) var headers: [String: String]? {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseWithParams(position: [.header])):\(caseReturn) \($0.moyaTaskHeaders)" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genAccessLevel) var method: Moya.Method {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return .\($0.method.lowercased())" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genAccessLevel) var task: Moya.Task {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseWithParams(position: [.body, .query, .formData])):\(caseReturn) \($0.moyaTask)" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)\(genAccessLevel) var sampleData: Data { return Data() }")
        strings.append("}")

        // Authorization
        if options.contains(.customAuthorization) {
            strings.append("")
            strings.append("// MARK: - Authorization")
            strings.append("")
            strings.append("extension \(name): AccessTokenAuthorizable {")
            strings.append("\(indent)\(genAccessLevel) var authorizationType: Moya.AuthorizationType {")
            strings.append("\(indent)\(indent)switch self {")
            strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return \($0.moyaTaskAuth)" }))
            strings.append("\(indent)\(indent)}")
            strings.append("\(indent)}")
            strings.append("}")
        }

        // Responses
        if options.contains(.responseTypes) {
            strings.append("")
            strings.append("// MARK: - Response Parsing")
            strings.append("")
            strings.append("extension \(name): TargetTypeResponse {")
            strings.append("\(indent)\(genAccessLevel) func decodeResponse(_ response: Moya.Response) throws -> Any {")
            strings.append("\(indent)\(indent)switch self {")
            strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName):\n\($0.moyaResponseDecoder(responseName: "response", indentLevel: 3))" }))
            strings.append("\(indent)\(indent)}")
            strings.append("\(indent)}")
            strings.append("}")
        }

        // Responses
        if options.contains(.moyaProvider) {
            strings.append("")
            strings.append("// MARK: - Sync Requests")
            strings.append("")
            strings.append("extension Server where Target == \(name) {")
            let ops: [String] = operations.map { op -> String in
                var subs: [String] = []
                subs.append("\(indent)\(genAccessLevel) func \(op.funcDeclaration) throws -> \(op.firstSuccessResponseType) {")
                subs.append("\(indent)\(indent)return try self.response(.\(op.caseUsage))")
                subs.append("\(indent)}")
                return subs.joined(separator: "\n")
            }
            strings.append(ops.joined(separator: "\n\n"))
            strings.append("}")
        }

        // Responses
        if options.contains(.moyaProvider) {
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
                subs.append("\(indent)\(genAccessLevel) func \(declaration) -> Moya.Cancellable {")
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
