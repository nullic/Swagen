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

    init(outputFolder: URL, processor: SwaggerProcessor) {
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
                let fileURL = modelsFolder.appendingPathComponent("\(scheme.title).swift")
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
            try utilsFile.data(using: .utf8)?.write(to: utilsURL)
        

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
        
        // Cases
        strings.append("public enum \(name) {")
        strings.append(contentsOf: operations.map({ "\(indent)case \($0.caseDeclaration)" }))
        strings.append("}")
        strings.append("")
        
        // Paths
        strings.append("extension \(name): TargetType {")
        strings.append("\(indent)public var baseURL: URL { return URL(string: \"\(processor.baseURL.absoluteString)\")! }")
        strings.append("")
        strings.append("\(indent)public var path: String {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return \"\($0.path)\"" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        // Requests
        strings.append("\(indent)public var headers: [String: String]? { return nil }")
        strings.append("")
        
        strings.append("\(indent)public var method: Moya.Method {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseName): return .\($0.method.lowercased())" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)public var task: Moya.Task {")
        strings.append("\(indent)\(indent)switch self {")
        strings.append(contentsOf: operations.map({ "\(indent)\(indent)case .\($0.caseWithParams): return \($0.moyaTask)" }))
        strings.append("\(indent)\(indent)}")
        strings.append("\(indent)}")
        strings.append("")
        
        strings.append("\(indent)public var sampleData: Data { return Data() }")
        strings.append("}")

        return strings.joined(separator: "\n")
    }
}
